#!/usr/bin/env bash
# pre-edit-auto-backup.sh — PreToolUse(Edit|Write|NotebookEdit) hook · ALESA NOVA Basic
#
# Law 1 — BACKUP BEFORE EVERY EDIT. Auto-creates `<file>.bak.auto.<ts>` before the agent's
# Edit/Write/NotebookEdit modifies an existing file, so you can always roll back a bad change.
# Counters the #1 vibe-coding regret: an AI overwrote my working code and I can't get it back.
#
# Mode env: NOVA_BACKUP_MODE = warn (default, creates backup + logs) |
#           enforce (blocks the edit if the backup can't be written) | off
# Skip:     NOVA_BACKUP_SKIP=1 (one-shot bypass)
# Log:      ~/.nova-basic/pre-edit-backup.log
# Exit:     0 = ok (backup made / nothing to back up) · 2 = BLOCK (enforce + backup failed)

set -uo pipefail
MODE="${NOVA_BACKUP_MODE:-warn}"
LOG="$HOME/.nova-basic/pre-edit-backup.log"
mkdir -p "$HOME/.nova-basic"
[[ "$MODE" == "off" ]] && exit 0
[[ "${NOVA_BACKUP_SKIP:-0}" == "1" ]] && { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP env_skip" >> "$LOG"; exit 0; }

INPUT="$(cat 2>/dev/null || echo '{}')"
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null)

case "$TOOL" in
  Edit|Write|NotebookEdit) : ;;
  *) exit 0 ;;
esac

# Nothing to back up if the file doesn't exist yet (Write creating a brand-new file)
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0
# Never back up a backup (avoid an infinite .bak chain)
[[ "$FILE_PATH" == *.bak.* || "$FILE_PATH" == *.bak ]] && exit 0

# Skip if a fresh backup (<5 min) already exists for this file — agent is iterating on the same file
RECENT_BAK=$(find "$(dirname "$FILE_PATH")" -maxdepth 1 -name "$(basename "$FILE_PATH").bak.auto.*" -mmin -5 2>/dev/null | head -1)
[[ -n "$RECENT_BAK" ]] && { echo "[$(date '+%Y-%m-%d %H:%M:%S')] SKIP_RECENT $RECENT_BAK" >> "$LOG"; exit 0; }

TS=$(date +%Y%m%d-%H%M%S)
BAK="${FILE_PATH}.bak.auto.${TS}"
if cp -a "$FILE_PATH" "$BAK" 2>/dev/null; then
  echo "✓ NOVA Basic: backed up before edit · backup dibuat sebelum edit → $(basename "$BAK")" >&2
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BACKUP path=$FILE_PATH bak=$BAK tool=$TOOL" >> "$LOG"
  exit 0
fi

MSG="auto-backup FAILED for $FILE_PATH (could not write $BAK)"
if [[ "$MODE" == "enforce" ]]; then
  echo "BLOCKED: $MSG — fix the destination or set NOVA_BACKUP_SKIP=1 if intentional." >&2
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCK_ENFORCE $MSG" >> "$LOG"; exit 2
else
  echo "WARN (nova-backup): $MSG" >&2
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN $MSG" >> "$LOG"; exit 0
fi
