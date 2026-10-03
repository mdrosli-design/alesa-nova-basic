#!/usr/bin/env bash
# activity-log.sh — PostToolUse(all tools) · ALESA NOVA Basic
#
# Keeps a private, local record of what the agent did — one JSON line per tool call — so you can review a
# session or produce an AI-use report (/nova-report), e.g. to disclose AI assistance in coursework.
#   Stored : ~/.nova-basic/activity/YYYY-MM-DD.jsonl (your account only; folder mode 700). Nothing is sent
#            anywhere.
#   Records: time, session id, working folder, tool, and the target — file path, the first 300 characters of a
#            command, a URL without its query string, a search query. Never file contents; secrets are
#            redacted.
#   Pruned after NOVA_LOG_KEEP_DAYS (default 90) by the session-start hook. Off switch: NOVA_ACTIVITY_LOG=off.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
[ "$(nova_mode NOVA_ACTIVITY_LOG on)" = off ] && exit 0
nova_read_input
DIR="$NOVA_HOME/activity"; mkdir -p "$DIR" 2>/dev/null || exit 0
OUT="$DIR/$(date +%F).jsonl"

if nova_has_python; then
  printf '%s' "$NOVA_INPUT" | NOVA_RE="$NOVA_SECRET_RE" python3 -c '
import json, os, re, sys, time
from urllib.parse import urlsplit
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit()
SECRET = re.compile(os.environ["NOVA_RE"].replace("[[:space:]]", r"\s"))
ASSIGN = re.compile(r"((api[_-]?key|token|secret|password|passwd)[\"\x27 ]*[:=][\"\x27 ]*)[^\"\x27\s&]{6,}", re.I)
def red(s):
    return ASSIGN.sub(r"\1[REDACTED]", SECRET.sub("[REDACTED]", s))
tool = d.get("tool_name") or ""
ti = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else {}
target = ""
if tool == "Bash":
    target = " ".join((ti.get("command") or "").split())[:300]
elif tool in ("Edit", "Write", "MultiEdit", "NotebookEdit", "Read"):
    target = ti.get("file_path") or ti.get("notebook_path") or ""
elif tool == "WebFetch":
    u = urlsplit(ti.get("url") or "")
    target = "%s://%s%s" % (u.scheme, u.netloc, u.path) if u.netloc else ""
elif tool == "WebSearch":
    target = (ti.get("query") or "")[:160]
elif tool in ("Grep", "Glob"):
    target = ("%s %s" % (ti.get("pattern") or "", ti.get("path") or "")).strip()[:200]
elif tool in ("Task", "Agent"):
    target = ("%s: %s" % (ti.get("subagent_type") or "agent", ti.get("description") or "")).strip()[:160]
rec = {
    "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "session": d.get("session_id") or "",
    "cwd": d.get("cwd") or "",
    "tool": tool,
    "target": red(target),
}
print(json.dumps(rec, ensure_ascii=False))' >> "$OUT" 2>/dev/null
else
  nova_parse
  t="$NOVA_CMD"; [ -n "$t" ] || t="$NOVA_PATH"
  printf '{"ts":"%s","session":"%s","cwd":"%s","tool":"%s","target":"%s"}\n' \
    "$(date +%Y-%m-%dT%H:%M:%S%z)" "$(nova_json_escape "$NOVA_SESSION")" "$(nova_json_escape "$NOVA_CWD")" \
    "$(nova_json_escape "$NOVA_TOOL")" "$(nova_json_escape "$(nova_redact "$(printf '%s' "$t" | tr '\n' ' ' | head -c 300)")")" \
    >> "$OUT" 2>/dev/null
fi
exit 0
