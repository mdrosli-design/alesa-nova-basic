#!/usr/bin/env bash
# change-annotation-gate.sh — PostToolUse · ALESA NOVA Basic
#
# WHY: when the agent writes or modifies code, it should leave a short remark AT the changed
# region — what changed, why, and how to verify — so a human reviewer (or future-you) sees the
# context right at the code, not buried in a chat transcript. This is the mechanical layer that
# makes that habit non-optional: an unannotated substantive code change is surfaced loudly and
# logged, so you can see exactly which edits lack context.
#
# CONVENTION:  // [CHANGE] what: … · why: … · verify: …   (comment syntax per language)
#
# Behavior: NON-BLOCKING (PostToolUse — the write already happened). A code edit whose payload
# lacks the marker (and the file has no marker dated today) → stderr nudge + ledger entry.
# This keeps multi-edit flow smooth while leaving the reviewer an audit map. exit 0 always.
# Ledger: ~/.nova-basic/change-annotation-ledger.jsonl

set -uo pipefail
LEDGER="${HOME}/.nova-basic/change-annotation-ledger.jsonl"
mkdir -p "${HOME}/.nova-basic"

INPUT="$(cat 2>/dev/null || echo '{}')"

# [CHANGE 2026-09-24] what: python3-first JSON extraction (jq not shipped on macOS → nudge silently never ran). why/verify: see secret-leak-gate.
_j() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c '
import sys, json
try: d = json.load(sys.stdin)
except Exception: print(""); sys.exit()
cur = d
for k in sys.argv[1].split("."):
    cur = cur.get(k) if isinstance(cur, dict) else None
print(cur if isinstance(cur, str) else "")' "$1" 2>/dev/null && return
  fi
  command -v jq >/dev/null 2>&1 && printf '%s' "$INPUT" | jq -r ".$1 // \"\"" 2>/dev/null && return
  printf ''
}
TOOL=$(_j tool_name)
[[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]] && exit 0

FILE=$(_j tool_input.file_path)
[[ -z "$FILE" ]] && exit 0

# Only code files where comments are possible. Skip docs/data/config-without-comments.
case "$FILE" in
  *.php|*.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.sh|*.bash|*.zsh|*.rb|*.go|*.java|*.kt|*.swift|*.c|*.cc|*.cpp|*.h|*.hpp|*.cs|*.rs|*.vue|*.svelte|*.sql|*.css|*.scss|*.less|*.html|*.htm) : ;;
  *) exit 0 ;;
esac

# The text this tool call wrote (Edit → new_string · Write → content)
if [[ "$TOOL" == "Edit" ]]; then
  PAYLOAD=$(_j tool_input.new_string)
else
  PAYLOAD=$(_j tool_input.content)
fi

# Skip trivial edits — fewer than 2 non-blank lines of change (renames, one-char tweaks)
NONBLANK=$(printf '%s\n' "$PAYLOAD" | grep -cE '[^[:space:]]' || true)
[[ "$NONBLANK" -lt 2 ]] && exit 0

# Annotation marker — generic [CHANGE …]
MARKER_RE='\[CHANGE'

# Satisfied if the marker is in this payload …
if printf '%s' "$PAYLOAD" | grep -qiE "$MARKER_RE"; then exit 0; fi
# … or already present in the on-disk file dated today (annotation added in an adjacent edit)
TODAY=$(date +%F)
if [[ -f "$FILE" ]] && grep -iE "$MARKER_RE" "$FILE" 2>/dev/null | grep -qF "$TODAY"; then exit 0; fi

# Unannotated substantive code change → log + nudge
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -nc --arg ts "$TS" --arg tool "$TOOL" --arg file "$FILE" --arg lines "$NONBLANK" \
  '{ts:$ts, tool:$tool, file:$file, changed_lines:($lines|tonumber), status:"unannotated"}' \
  >> "$LEDGER" 2>/dev/null || true

cat >&2 <<EOF

════════ CHANGE-ANNOTATION SUGGESTED ════════
File: $FILE  ($NONBLANK changed lines, $TOOL)
This code change has no reviewer annotation. Add a remark at the changed region:
   // [CHANGE $TODAY] what: <what changed> · why: <reason> · verify: <how to check>
(use the comment syntax for the file's language: # , -- , <!-- -->, /* */)
Logged for review. Non-blocking.

🇲🇾 Edit kod ini tiada nota untuk reviewer. Tinggalkan catatan di bahagian yang berubah:
   // [CHANGE $TODAY] what: <apa yang berubah> · why: <sebab> · verify: <cara menyemak>
   (guna sintaks komen mengikut bahasa fail). Direkodkan untuk semakan · tidak menyekat.
══════════════════════════════════════════════
EOF
exit 0
