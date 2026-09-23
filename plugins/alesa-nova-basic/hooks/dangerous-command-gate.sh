#!/usr/bin/env bash
# dangerous-command-gate.sh — MECHANICAL PreToolUse(Bash) BLOCK · ALESA NOVA Basic
#
# PHILOSOPHY: the #1 vibe-coding horror is "the AI ran a command and wiped my files / dropped my DB /
#   force-pushed over my work." A prompt reminder can't stop that — an agent can ignore a prompt. So the
#   SYSTEM blocks the catastrophic command MECHANICALLY (exit 2), before it runs. It ACTS, not warns.
#   It gates the AGENT, not you: if you truly need a blocked command, run it yourself in the terminal.
#
# BLOCKS (high-confidence catastrophic):
#   • rm -rf / · rm -fr / · rm -rf ~ · rm -rf $HOME · sudo rm -rf   (mass file deletion)
#   • DROP DATABASE · DROP TABLE · TRUNCATE TABLE                    (destroys data)
#   • git push --force / push -f (any branch) · --no-verify         (overwrites remote / skips gates)
#   • curl … | bash · wget … | sh · … | sudo bash                   (blind remote-code execution)
#   • mkfs · dd if=/dev/zero|urandom · chmod -R 777 · shutdown · reboot · :(){ :|:& };:
# WARNS (legit on dev, catastrophic on prod — you decide):
#   • migrate:fresh / migrate:reset / db:wipe / prisma migrate reset
#
# Robust: works even with NO jq and NO python3 (raw-input scan) — a security block must never fail open.
# Mode: NOVA_DANGER_GATE_MODE = enforce (default) | warn | off.  Exit: 0 allow · 2 BLOCK.

set -uo pipefail
MODE="${NOVA_DANGER_GATE_MODE:-enforce}"
[[ "$MODE" == "off" ]] && exit 0
LOG="$HOME/.nova-basic/dangerous-command-gate.log"; mkdir -p "$HOME/.nova-basic"

INPUT="$(cat 2>/dev/null || echo '{}')"

_j() {  # _j <dot.path> — python3 first (common on macOS), then jq, else empty.
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
CMD=$(_j tool_input.command)
# Raw fail-CLOSED fallback: no parser available → scan the whole raw input (a Bash command still can't slip through).
[[ -z "$CMD" && -z "$TOOL" ]] && CMD="$INPUT"

# Only gate Bash (or the raw-fallback case where TOOL is unknown).
[[ -n "$TOOL" && "$TOOL" != "Bash" ]] && exit 0
[[ -z "$CMD" ]] && exit 0

is_catastrophic() {
  case "$1" in
    *"rm -rf /"*|*"rm -fr /"*|*"rm -rf ~"*|*"rm -fr ~"*|*'rm -rf $HOME'*|*'rm -fr $HOME'*|*"sudo rm -rf"*|*"sudo rm -fr"*) return 0 ;;
    *"DROP DATABASE"*|*"drop database"*|*"DROP TABLE"*|*"drop table"*|*"TRUNCATE TABLE"*|*"truncate table"*) return 0 ;;
    *"push --force"*|*"push -f "*|*"push --force-with-lease"*|*"--no-verify"*) return 0 ;;
    *" | bash"*|*" | sh"*|*" | sudo bash"*|*" | sudo sh"*|*" |bash"*|*" |sh"*) return 0 ;;
    *"mkfs"*|*"dd if=/dev/zero"*|*"dd if=/dev/urandom"*|*"dd if=/dev/random"*|*"chmod -R 777"*|*"chmod 777 -R"*) return 0 ;;
    *"shutdown"*|*"reboot"*|*"init 0"*|*"init 6"*|*":(){ :|:& };:"*|*":(){:|:&};:"*) return 0 ;;
    *) return 1 ;;
  esac
}

if is_catastrophic "$CMD"; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) · DANGER-BLOCK · $(echo "$CMD" | head -c 80)" >> "$LOG"
  [[ "$MODE" == "warn" ]] && { echo "⚠️  DANGEROUS-COMMAND WARN — would block in enforce: $(echo "$CMD" | head -c 60)" >&2; exit 0; }
  cat >&2 <<EOF

🔴 ════════ DANGEROUS-COMMAND GATE · BLOCKED (mechanical · not a notice) ════════
Command: $(echo "$CMD" | head -c 200)
This is a catastrophic, usually-irreversible operation (mass delete / drop DB / force-push / blind
remote-exec). It is the #1 way vibe-coded projects get destroyed by their own agent.

If you REALLY mean it: run it yourself in your terminal (this gate stops the AGENT, not you),
or set NOVA_DANGER_GATE_MODE=warn for this one command.

🇲🇾 DISEKAT: arahan ini memusnahkan (padam pukal / drop DB / force-push / jalankan kod jauh secara membuta).
   Inilah punca #1 projek vibe-coded rosak oleh agennya sendiri. Kalau anda BETUL-BETUL nak: jalankan
   sendiri di terminal anda (gate ini menahan AGEN, bukan anda), atau set NOVA_DANGER_GATE_MODE=warn.
═══════════════════════════════════════════════════════════════════════════════
EOF
  exit 2
fi

# WARN-tier: schema-destructive dev commands (legit on dev, catastrophic on prod — human judges).
case "$CMD" in
  *"migrate:fresh"*|*"migrate:reset"*|*"migrate:rollback"*|*"db:wipe"*|*"prisma migrate reset"*|*"sequelize db:drop"*)
    echo "⚠️  NOVA: '$(echo "$CMD" | head -c 40)' wipes DB data. Fine on dev — make sure this is NOT production (back up first if unsure)." >&2
    ;;
esac
exit 0
