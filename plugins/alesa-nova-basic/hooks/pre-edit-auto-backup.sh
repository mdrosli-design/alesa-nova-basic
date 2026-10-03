#!/usr/bin/env bash
# pre-edit-auto-backup.sh — PreToolUse(Edit|Write|MultiEdit|NotebookEdit) · ALESA NOVA Basic
#
# Law 1 — back up before you change. Copies an existing file before the agent modifies it, so a bad edit
# can always be undone. Notebooks (.ipynb) included.
#
# Where: ~/.nova-basic/backups/<full path of the file>.<YYYYMMDD-HHMMSS> — OUTSIDE your project, so backups
#   never clutter the repo and can never be committed by accident (a backup of .env next to the file would
#   slip past a ".env" line in .gitignore and could be pushed with your keys).
# Restore: cp ~/.nova-basic/backups/<path>.<timestamp> <path>     (/nova-basic shows the latest ones)
# Skips: files larger than NOVA_BACKUP_MAX_MB (default 20 — datasets, model weights) and a file that was
#   already backed up in the last 5 minutes (the agent is iterating on it). Old backups are pruned after
#   NOVA_BACKUP_KEEP_DAYS (default 14) by the session-start hook.
# Mode: NOVA_BACKUP_MODE = warn (default: back up, never block) | enforce (block the edit when the backup
#   cannot be written) | off.  Log: ~/.nova-basic/pre-edit-backup.log

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
MODE="$(nova_mode NOVA_BACKUP_MODE warn)"
[ "$MODE" = off ] && exit 0
nova_read_input; nova_parse

case "$NOVA_TOOL" in Edit|Write|MultiEdit|NotebookEdit) : ;; *) exit 0 ;; esac
FILE="$NOVA_PATH"
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0              # new file: nothing to back up
case "$FILE" in *.bak|*.bak.*) exit 0 ;; esac            # never back up a backup
case "$FILE" in "$NOVA_HOME"/*) exit 0 ;; esac

MAX_MB="${NOVA_BACKUP_MAX_MB:-20}"
size_kb="$(du -k "$FILE" 2>/dev/null | cut -f1)"
if [ -n "$size_kb" ] && [ "$size_kb" -gt $((MAX_MB * 1024)) ] 2>/dev/null; then
  nova_log pre-edit-backup.log "SKIP_LARGE ${size_kb}KB $FILE"
  exit 0
fi

ABS="$FILE"; case "$ABS" in /*) : ;; *) ABS="${NOVA_CWD:-$PWD}/$ABS" ;; esac
REL="${ABS//\\//}"; REL="${REL//:/}"                       # Windows-style paths → plain folders
DEST_DIR="$NOVA_HOME/backups$(dirname "/${REL#/}")"
NAME="$(basename "$ABS")"
if mkdir -p "$DEST_DIR" 2>/dev/null; then
  recent="$(find "$DEST_DIR" -maxdepth 1 -name "$NAME.*" -mmin -5 2>/dev/null | head -1)"
  if [ -n "$recent" ]; then nova_log pre-edit-backup.log "SKIP_RECENT $recent"; exit 0; fi
  BAK="$DEST_DIR/$NAME.$(date +%Y%m%d-%H%M%S)"
  if cp -p "$FILE" "$BAK" 2>/dev/null; then
    nova_log pre-edit-backup.log "BACKUP $FILE -> $BAK tool=$NOVA_TOOL"
    exit 0
  fi
fi

nova_log pre-edit-backup.log "FAILED $FILE (could not write under $DEST_DIR)"
if [ "$MODE" = enforce ]; then
  echo "NOVA: blocked — could not back up $FILE before editing (check free space / permissions of $NOVA_HOME)." >&2
  exit 2
fi
nova_user_msg "⚠️ NOVA: could not back up $FILE before this edit (check free space / permissions of $NOVA_HOME)."
exit 0
