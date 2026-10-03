#!/usr/bin/env bash
# change-annotation-gate.sh — PostToolUse(Edit|Write|MultiEdit) · ALESA NOVA Basic
#
# When the agent changes code, it should leave a short remark AT the changed region — what changed, why,
# and how to verify — so a reviewer (or future-you) sees the context next to the code, not buried in chat.
# Convention:  // [CHANGE] what: … · why: … · verify: …   (use the file's comment syntax)
#
# Non-blocking (the edit already happened). A substantive code change without the marker → a reminder is
# injected into the AGENT's context (hookSpecificOutput.additionalContext) and the edit is recorded in
# ~/.nova-basic/change-annotation-ledger.jsonl, so you can review which changes lack context.
# Off switch: NOVA_ANNOTATION_MODE=off.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
[ "$(nova_mode NOVA_ANNOTATION_MODE warn)" = off ] && exit 0
nova_read_input; nova_parse
case "$NOVA_TOOL" in Edit|Write|MultiEdit) : ;; *) exit 0 ;; esac
FILE="$NOVA_PATH"; [ -n "$FILE" ] || exit 0

case "$FILE" in
  *.php|*.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.sh|*.bash|*.zsh|*.rb|*.go|*.java|*.kt|*.swift|*.c|*.cc|*.cpp|*.h|*.hpp|*.cs|*.rs|*.vue|*.svelte|*.sql|*.css|*.scss|*.less|*.html|*.htm|*.r|*.R|*.jl|*.scala|*.dart|*.lua) : ;;
  *) exit 0 ;;
esac

NONBLANK="$(printf '%s\n' "$NOVA_PAYLOAD" | grep -cE '[^[:space:]]' || true)"
[ "${NONBLANK:-0}" -lt 2 ] && exit 0                         # trivial edit
printf '%s' "$NOVA_PAYLOAD" | grep -qiE '\[CHANGE' && exit 0
TODAY="$(date +%F)"
if [ -f "$FILE" ] && grep -iE '\[CHANGE' "$FILE" 2>/dev/null | grep -qF "$TODAY"; then exit 0; fi

printf '{"ts":"%s","tool":"%s","file":"%s","changed_lines":%s,"status":"unannotated"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(nova_json_escape "$NOVA_TOOL")" "$(nova_json_escape "$FILE")" "${NONBLANK:-0}" \
  >> "$NOVA_HOME/change-annotation-ledger.jsonl" 2>/dev/null

if [ "$(nova_lang)" = ms ]; then
  MSG="NOVA: perubahan kod pada $FILE ($NONBLANK baris) tiada nota untuk penyemak. Tambah satu komen di kawasan yang berubah: [CHANGE $TODAY] what: <apa berubah> · why: <sebab> · verify: <cara semak> (guna sintaks komen bahasa fail). Satu nota bagi setiap perubahan logik, bukan setiap baris."
else
  MSG="NOVA: the code change to $FILE ($NONBLANK lines) has no reviewer note. Add one comment at the changed region: [CHANGE $TODAY] what: <what changed> · why: <reason> · verify: <how to check> (use the file's comment syntax). One note per logical change, not per line."
fi
nova_agent_ctx PostToolUse "$MSG"
exit 0
