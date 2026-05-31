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
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
[[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]] && exit 0

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
[[ -z "$FILE" ]] && exit 0

# Only code files where comments are possible. Skip docs/data/config-without-comments.
case "$FILE" in
  *.php|*.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.sh|*.bash|*.zsh|*.rb|*.go|*.java|*.kt|*.swift|*.c|*.cc|*.cpp|*.h|*.hpp|*.cs|*.rs|*.vue|*.svelte|*.sql|*.css|*.scss|*.less|*.html|*.htm) : ;;
  *) exit 0 ;;
esac

# The text this tool call wrote (Edit → new_string · Write → content)
if [[ "$TOOL" == "Edit" ]]; then
  PAYLOAD=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""' 2>/dev/null || echo "")
else
  PAYLOAD=$(echo "$INPUT" | jq -r '.tool_input.content // ""' 2>/dev/null || echo "")
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
══════════════════════════════════════════════
EOF
exit 0
