#!/usr/bin/env bash
# _lib.sh — shared helpers for ALESA NOVA Basic hooks and scripts. Sourced, never executed.
#
# Design rules (every hook depends on them):
#   • Works on a bare machine: JSON is parsed with python3, else jq, else a sed fallback. A guard that
#     silently parses nothing is worse than no guard, so security gates also scan the raw input.
#   • Messages that must reach a PERSON use {"systemMessage": …}; messages for the AGENT use
#     hookSpecificOutput.additionalContext (PostToolUse/SessionStart) or stderr + exit 2 (a block).
#     Plain stderr with exit 0 is NOT shown to either (only in verbose mode) — never rely on it.
#   • Per-user data (logs, backups, state) lives in ~/.nova-basic, mode 700 — private on shared machines.
#   • bash 3.2 compatible (macOS /bin/bash): no associative arrays, no ${x,,}, no mapfile.

NOVA_HOME="${NOVA_HOME:-$HOME/.nova-basic}"
mkdir -p "$NOVA_HOME" 2>/dev/null && chmod 700 "$NOVA_HOME" 2>/dev/null
NOVA_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)}"
NOVA_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$NOVA_ROOT/.claude-plugin/plugin.json" 2>/dev/null | head -1)"

# ── High-confidence secret signatures (provider prefixes + structural). Shared by the secret gate,
#    the commit/push scan and log redaction. NOVA_SECRET_RE_COMMIT omits bare JWTs: public "anon"
#    JWTs (e.g. Supabase) are committed on purpose, so they would block legitimate pushes.
_NOVA_SECRET_CORE='AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9A-Za-z]{16,}|rk_live_[0-9A-Za-z]{16,}|sk-(proj|svcacct|admin|ant|or)-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{20,}|hf_[A-Za-z0-9]{30,}|gsk_[A-Za-z0-9]{30,}|r8_[A-Za-z0-9]{30,}|xai-[A-Za-z0-9]{40,}|pplx-[A-Za-z0-9]{40,}|gh[pousr]_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{40,}|glpat-[0-9A-Za-z_-]{20,}|xox[baprs]-[0-9A-Za-z-]{10,}|SG\.[0-9A-Za-z_-]{20,}\.[0-9A-Za-z_-]{20,}|[0-9]{8,10}:AA[0-9A-Za-z_-]{33}|(mongodb(\+srv)?|redis|rediss|postgres(ql)?|mysql|amqps?)://[^[:space:]:@/]+:[^[:space:]@/]+@|-----BEGIN [A-Z ]*PRIVATE KEY-----'
NOVA_SECRET_RE_COMMIT="$_NOVA_SECRET_CORE"
NOVA_SECRET_RE="$_NOVA_SECRET_CORE"'|eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'
# A secret-ish NAME assigned a long literal value (not an env reference / placeholder).
NOVA_GENERIC_RE='(api[_-]?key|secret(_key)?|auth[_-]?token|access[_-]?token|client[_-]?secret|service[_-]?role(_key)?|private[_-]?key|db[_-]?password|passwd|password)["'"'"' ]*[:=]>?["'"'"' ]*[0-9A-Za-z/+]{16,}'

# [CHANGE 2026-10-03] what: placeholder checks look at the matched SECRET TOKEN, not the whole line ·
#   why: a line-level allow-list let `key = '<real key>' // example` through (review finding) ·
#   verify: tests S25 (blocked) and S26 (AWS documentation key EXAMPLE allowed).
# nova_token_is_placeholder <token> → 0 when the matched value itself is a placeholder / documentation sample.
nova_token_is_placeholder() {
  printf '%s' "$1" | grep -qiE 'x{4,}|example|placeholder|your[_-]|changeme|dummy|sample|redacted|fake|test[_-]?key|[<>]|\.\.\.|0{8,}'
}
# nova_line_has_real_secret <line> [regex] → 0 when the line holds at least one secret that is not a placeholder.
# A JWT counts as public only when the line names it as an anon/publishable key (e.g. SUPABASE_ANON_KEY=eyJ…).
nova_line_has_real_secret() {
  local line="$1" re="${2:-$NOVA_SECRET_RE}" tok
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    nova_token_is_placeholder "$tok" && continue
    case "$tok" in eyJ*) printf '%s' "$line" | grep -qiE '[_.-]anon([_.-]|$)|anon[_-]?key|publishable' && continue ;; esac
    return 0
  done < <(printf '%s' "$line" | grep -oE "$re" 2>/dev/null)   # process substitution: no temp file needed
  local g; g="$(printf '%s' "$line" | grep -oiE "$NOVA_GENERIC_RE" 2>/dev/null | head -1)"
  [ "$re" = "$NOVA_SECRET_RE" ] && [ -n "$g" ] && ! nova_token_is_placeholder "$g" && return 0
  return 1
}
# first real (non-placeholder) secret token in a line — for masked samples in messages
nova_first_secret() {
  local tok
  while IFS= read -r tok; do
    [ -n "$tok" ] && ! nova_token_is_placeholder "$tok" && { printf '%s' "$tok"; return; }
  done < <(printf '%s' "$1" | grep -oE "${2:-$NOVA_SECRET_RE}" 2>/dev/null)
  printf '%s' "$1" | grep -oiE "$NOVA_GENERIC_RE" 2>/dev/null | head -1
}

# ── Is python3 really usable? On macOS without the Command Line Tools, /usr/bin/python3 is a stub that
#    opens an install dialog on every call — a hook must never trigger that, so detect it first.
nova_has_python() {
  if [ -n "${NOVA_PY_OK:-}" ]; then [ "$NOVA_PY_OK" = 1 ]; return; fi
  local p; p="$(command -v python3 2>/dev/null)"
  if [ -z "$p" ]; then NOVA_PY_OK=0; return 1; fi
  if [ "$p" = /usr/bin/python3 ] && [ "$(uname -s 2>/dev/null)" = Darwin ] && ! xcode-select -p >/dev/null 2>&1; then
    NOVA_PY_OK=0; return 1
  fi
  NOVA_PY_OK=1
}

# nova_read_input — read the hook JSON from stdin once.
nova_read_input() { NOVA_INPUT="$(cat 2>/dev/null)"; [ -n "$NOVA_INPUT" ] || NOVA_INPUT='{}'; }

# nova_parse — one parse of the hook JSON into shell variables:
#   NOVA_TOOL NOVA_CMD NOVA_PATH NOVA_PAYLOAD NOVA_CWD NOVA_SESSION NOVA_EVENT NOVA_TRANSCRIPT
#   NOVA_STOP_ACTIVE (1 when Claude is already continuing because of a Stop hook) NOVA_PARSER
# NOVA_PATH covers file_path (Edit/Write/Read) and notebook_path (NotebookEdit).
# NOVA_PAYLOAD is the text being written: content · new_string · new_source · edits[].new_string.
nova_parse() {
  NOVA_TOOL=""; NOVA_CMD=""; NOVA_PATH=""; NOVA_PAYLOAD=""; NOVA_CWD=""; NOVA_SESSION=""
  NOVA_EVENT=""; NOVA_TRANSCRIPT=""; NOVA_STOP_ACTIVE=""; NOVA_PARSER="none"
  if nova_has_python; then
    local assign
    assign="$(printf '%s' "$NOVA_INPUT" | python3 -c '
import sys, json, shlex
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
if not isinstance(d, dict): d = {}
ti = d.get("tool_input")
if not isinstance(ti, dict): ti = {}
def s(v): return v if isinstance(v, str) else ""
parts = [s(ti.get("content")), s(ti.get("new_string")), s(ti.get("new_source"))]
edits = ti.get("edits")
if isinstance(edits, list):
    parts += [s(e.get("new_string")) for e in edits if isinstance(e, dict)]
out = [
    ("NOVA_TOOL", s(d.get("tool_name"))),
    ("NOVA_CMD", s(ti.get("command"))),
    ("NOVA_PATH", s(ti.get("file_path")) or s(ti.get("notebook_path"))),
    ("NOVA_PAYLOAD", "\n".join(p for p in parts if p)),
    ("NOVA_CWD", s(d.get("cwd"))),
    ("NOVA_SESSION", s(d.get("session_id"))),
    ("NOVA_EVENT", s(d.get("hook_event_name"))),
    ("NOVA_TRANSCRIPT", s(d.get("transcript_path"))),
    ("NOVA_STOP_ACTIVE", "1" if d.get("stop_hook_active") is True else ""),
]
for k, v in out:
    print("%s=%s" % (k, shlex.quote(v.replace("\x00", ""))))
' 2>/dev/null)"
    if [ -n "$assign" ]; then
      eval "$assign"; NOVA_PARSER="python3"
      # input python could not read (malformed / truncated JSON) → try jq, then the sed + raw-scan fallback
      if [ -n "$NOVA_TOOL$NOVA_EVENT$NOVA_SESSION" ] || [ "${#NOVA_INPUT}" -le 2 ]; then return 0; fi
    fi
  fi
  if command -v jq >/dev/null 2>&1 && printf '%s' "$NOVA_INPUT" | jq -e . >/dev/null 2>&1; then
    NOVA_TOOL="$(printf '%s' "$NOVA_INPUT" | jq -r '.tool_name // ""')"
    NOVA_CMD="$(printf '%s' "$NOVA_INPUT" | jq -r '.tool_input.command // ""')"
    NOVA_PATH="$(printf '%s' "$NOVA_INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')"
    NOVA_PAYLOAD="$(printf '%s' "$NOVA_INPUT" | jq -r '[.tool_input.content, .tool_input.new_string, .tool_input.new_source, (.tool_input.edits // [] | .[]? | .new_string)] | map(select(type == "string")) | join("\n")')"
    NOVA_CWD="$(printf '%s' "$NOVA_INPUT" | jq -r '.cwd // ""')"
    NOVA_SESSION="$(printf '%s' "$NOVA_INPUT" | jq -r '.session_id // ""')"
    NOVA_EVENT="$(printf '%s' "$NOVA_INPUT" | jq -r '.hook_event_name // ""')"
    NOVA_TRANSCRIPT="$(printf '%s' "$NOVA_INPUT" | jq -r '.transcript_path // ""')"
    [ "$(printf '%s' "$NOVA_INPUT" | jq -r '.stop_hook_active // false')" = true ] && NOVA_STOP_ACTIVE=1
    NOVA_PARSER="jq"; return 0
  fi
  # sed fallback — simple string fields only. JSON escapes stay escaped (\" \n), which is fine for
  # pattern matching. The text being written cannot be extracted reliably here, so security gates
  # fall back to scanning the raw input (see NOVA_PARSER=sed).
  NOVA_TOOL="$(_nova_sed_field tool_name)"; NOVA_CMD="$(_nova_sed_field command)"
  NOVA_PATH="$(_nova_sed_field file_path)"; [ -n "$NOVA_PATH" ] || NOVA_PATH="$(_nova_sed_field notebook_path)"
  NOVA_CWD="$(_nova_sed_field cwd)"; NOVA_SESSION="$(_nova_sed_field session_id)"
  NOVA_EVENT="$(_nova_sed_field hook_event_name)"; NOVA_TRANSCRIPT="$(_nova_sed_field transcript_path)"
  printf '%s' "$NOVA_INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && NOVA_STOP_ACTIVE=1
  NOVA_PARSER="sed"
}
_nova_sed_field() {   # ERE only — BSD sed (macOS) has no \| in basic regex
  printf '%s' "$NOVA_INPUT" | tr '\n' ' ' \
    | sed -nE 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' | head -1
}

# ── Shell words and git invocations (shared by the secret and dangerous-command gates).
# [CHANGE 2026-10-03] what: quote-aware word patterns + git global-option parsing in one place · why:
#   `git -C "/a b" push --force`, `/usr/bin/git push -f`, `git commit -m "a; b" --no-verify` and
#   `git commit -C HEAD` (reuse a message) slipped past or confused the per-gate regexes (review finding) ·
#   verify: tests S39-S42, D68-D78.
# One shell word: plain characters, \-escapes and "…" / '…' parts — no unquoted whitespace or ; & |.
NOVA_SH_WORD='([^[:space:];&|"'"'"'\\]|\\.|"[^"]*"|'"'"'[^'"'"']*'"'"')+'
# The rest of one command: words and spaces up to an unquoted ; & | ) or backtick.
NOVA_SH_ARGS='([^;&|)`"'"'"'\\]|\\.|"[^"]*"|'"'"'[^'"'"']*'"'"')*'
# git — also /usr/bin/git, "git", \git — plus its global options (-C/-c/--git-dir/--work-tree/--namespace/
# --config-env/--attr-source take a separate value); the subcommand pattern follows directly.
NOVA_GIT_RE='(^|[[:space:];&|(`])([^[:space:];&|(`]*/)?[\\"'"'"']?git["'"'"']?([[:space:]]+((-C|-c|--git-dir|--work-tree|--namespace|--config-env|--attr-source)[[:space:]]+'"$NOVA_SH_WORD"'|--[a-zA-Z][a-zA-Z-]*(=('"$NOVA_SH_WORD"')?)?|-[a-zA-Z]))*[[:space:]]+'

# nova_unquote <word> → the word's literal text: quotes and backslash escapes removed, nothing expanded.
nova_unquote() {
  local s="$1" out="" q="" c i=0
  while [ "$i" -lt "${#s}" ]; do
    c="${s:$i:1}"
    if [ "$q" = "'" ]; then
      if [ "$c" = "'" ]; then q=""; else out="$out$c"; fi
    elif [ "$q" = '"' ]; then
      if [ "$c" = '"' ]; then q=""
      else
        if [ "$c" = '\' ]; then case "${s:$((i + 1)):1}" in '"'|'\'|'$'|'`') i=$((i + 1)); c="${s:$i:1}" ;; esac; fi
        out="$out$c"
      fi
    else
      case "$c" in
        "'"|'"') q="$c" ;;
        '\') i=$((i + 1)); out="$out${s:$i:1}" ;;
        *) out="$out$c" ;;
      esac
    fi
    i=$((i + 1))
  done
  printf '%s' "$out"
}
# nova_join_dir <base> <dir> → <dir> resolved from <base> the way cd would (~, $HOME, absolute, relative).
nova_join_dir() {
  case "$2" in
    "") printf '%s' "$1" ;;
    /*) printf '%s' "$2" ;;
    "~"|'$HOME'|'${HOME}') printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${2#\~/}" ;;
    '$HOME/'*) printf '%s/%s' "$HOME" "${2#\$HOME/}" ;;
    '${HOME}/'*) printf '%s/%s' "$HOME" "${2#\$\{HOME\}/}" ;;
    *) printf '%s/%s' "$1" "$2" ;;
  esac
}
# nova_cmd_dir <command> <cwd> → the folder the command works in: <cwd>, moved by a leading `cd <dir> &&` / `;`.
nova_cmd_dir() {
  local w
  w="$(printf '%s' "$1" | grep -oE "^[[:space:]]*cd[[:space:]]+$NOVA_SH_WORD[[:space:]]*(&&|;)" | head -1 \
       | sed -E 's/^[[:space:]]*cd[[:space:]]+//; s/[[:space:]]*(&&|;)$//')"
  nova_join_dir "$2" "$(nova_unquote "$w")"
}
# nova_git_dir <"git <global options> <subcommand>"> <base> → the folder git runs in: each -C <dir> applies in
# order, a relative one to the previous (git's own rule). Pass only the part up to the subcommand, so that
# subcommand options such as `commit -C <commit>` are not mistaken for a folder.
nova_git_dir() {
  local d="$2" w
  while IFS= read -r w; do
    w="$(printf '%s' "$w" | sed -E 's/^[[:space:]]*-C[[:space:]]+//')"
    d="$(nova_join_dir "$d" "$(nova_unquote "$w")")"
  done < <(printf '%s' "$1" | grep -oE "[[:space:]]-C[[:space:]]+$NOVA_SH_WORD")
  printf '%s' "$d"
}

# ── Language: English by default; Bahasa Malaysia with NOVA_LANG=ms (or a ms_* locale).
nova_lang() {
  case "$(printf '%s' "${NOVA_LANG:-}" | tr '[:upper:]' '[:lower:]')" in
    ms|my|bm|malay*|bahasa*) echo ms; return ;;
    en|english) echo en; return ;;
  esac
  case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in ms|ms_*|ms-*) echo ms ;; *) echo en ;; esac
}

# nova_mode <ENV_VAR_NAME> <default> → enforce | warn | off
nova_mode() {
  local v; eval "v=\${$1:-}"; [ -n "$v" ] || v="$2"
  case "$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')" in
    enforce|block|on|1|true) echo enforce ;;
    warn|warning) echo warn ;;
    off|0|false|disable|disabled) echo off ;;
    *) echo "$2" ;;
  esac
}

# ── JSON output (no jq needed)
nova_json_escape() {
  local s; s="$(printf '%s' "$1" | tr -d '\000-\010\013\014\016-\037')"
  s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; s="${s//$'\r'/\\r}"; s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}
nova_user_msg() { printf '{"systemMessage":"%s"}\n' "$(nova_json_escape "$1")"; }
nova_agent_ctx() {
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$1" "$(nova_json_escape "$2")"
}

# ── Logging (one line per event, UTC) and redaction
nova_log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$2" >> "$NOVA_HOME/$1" 2>/dev/null; }
nova_redact() {   # provider secrets + "password=…"-style values → [REDACTED]
  if nova_has_python; then
    printf '%s' "$1" | NOVA_RE="$NOVA_SECRET_RE" python3 -c '
import os, re, sys
t = sys.stdin.read()
t = re.sub(os.environ["NOVA_RE"].replace("[[:space:]]", r"\s"), "[REDACTED]", t)
t = re.sub(r"((api[_-]?key|token|secret|password|passwd)[\"\x27 ]*[:=][\"\x27 ]*)[^\"\x27\s&]{6,}", r"\1[REDACTED]", t, flags=re.I)
sys.stdout.write(t)' 2>/dev/null && return 0
  fi
  printf '%s' "$1" | sed -E "s#${NOVA_SECRET_RE}#[REDACTED]#g" 2>/dev/null || printf '%s' "$1"
}
# nova_mask <secret-ish text> → first 6 chars + … (safe to show in a block message)
nova_mask() { local s; s="$(printf '%s' "$1" | tr -d '\n' | head -c 6)"; printf '%s…' "$s"; }
