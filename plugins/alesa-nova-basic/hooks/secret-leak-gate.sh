#!/usr/bin/env bash
# secret-leak-gate.sh — MECHANICAL PreToolUse BLOCK · stops secrets reaching client-exposed code / deploys.
#
# PHILOSOPHY: vibe coders can't review — so the SYSTEM blocks MECHANICALLY, not by
#   asking a human and not by trusting the agent to obey a prompt (an agent can betray a prompt anytime).
#   it ACTS (exit 2 = BLOCK), it does not merely print a notice. This directly answers
#   critique #1 (the "380k leaked apps · API keys in client JS · service-role keys exposed" headline).
#
# WHAT IT BLOCKS:
#   • Edit/Write that places a REAL secret into a CLIENT-EXPOSED file (src/, public/, dist/, *.jsx/tsx/vue…).
#   • A deploy/commit/push/build/ship Bash command when client-exposed files / build output contain a secret.
# WHAT IT ALLOWS (no FP):
#   • Server-side .env (gitignored) · placeholders (YOUR_KEY, xxxx, <token>) · env references (process.env.X,
#     import.meta.env.X) · PUBLISHABLE keys meant to be public (pk_live/pk_test, *_ANON_KEY, NEXT_PUBLIC_*_ANON).
#
# Mode: NOVA_SECRET_GATE_MODE = enforce (default) | warn | off.  Exit: 0 allow · 2 BLOCK.
# Test harness: ~/.claude/hooks/secret-leak-gate.test.sh (re-run after edits).

set -uo pipefail
MODE="${NOVA_SECRET_GATE_MODE:-enforce}"
[[ "$MODE" == "off" ]] && exit 0
LOG="$HOME/.nova-basic/secret-leak-gate.log"; mkdir -p "$HOME/.nova-basic"

INPUT="$(cat 2>/dev/null || echo '{}')"

# [CHANGE 2026-09-24] what: dependency-resilient JSON extraction (python3 → jq) + raw fail-closed net.
#   why: hooks required `jq`, which macOS does NOT ship by default — so on the target machine (solo-builder
#        Mac with no jq) the gate parsed nothing and FAILED OPEN silently (a real AWS key leaked, verified
#        exit 0). A mechanical guard that silently does nothing is worse than none.
#   verify: with no jq AND no python3, a secret in raw input still BLOCKS (raw-scan below); with either present, normal.
_j() {  # _j <dot.path> — extract a JSON string field. python3 first (common on macOS), then jq, else empty.
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
FP=$(_j tool_input.file_path)
NEW=$(_j tool_input.content); [[ -z "$NEW" ]] && NEW=$(_j tool_input.new_string)

# ── High-confidence REAL secret signatures (provider-specific + structural) ─────────────────────────
SECRET_RE='AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|sk_live_[0-9A-Za-z]{16,}|rk_live_[0-9A-Za-z]{16,}|sk-[A-Za-z0-9]{20,}|gh[pousr]_[0-9A-Za-z]{30,}|github_pat_[0-9A-Za-z_]{40,}|glpat-[0-9A-Za-z_-]{20,}|xox[baprs]-[0-9A-Za-z-]{10,}|SG\.[0-9A-Za-z_-]{20,}\.[0-9A-Za-z_-]{20,}|(mongodb(\+srv)?|redis|rediss|postgres(ql)?|mysql|amqps?)://[^[:space:]:@/]+:[^[:space:]@/]+@|-----BEGIN [A-Z ]*PRIVATE KEY-----|eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'
# Generic assigned secret: a secret-ish KEY with a long literal value (not an env ref / placeholder).
GENERIC_RE='(api[_-]?key|secret(_key)?|auth[_-]?token|access[_-]?token|client[_-]?secret|service[_-]?role(_key)?|private[_-]?key|db[_-]?password|passwd|password)["'"'"' ]*[:=]>?["'"'"' ]*[0-9A-Za-z/+]{16,}'

# Allowlist — things that LOOK secret-ish but are safe to expose / not real.
is_allowed_value() {
  echo "$1" | grep -qiE 'pk_live_|pk_test_|publishable|[_.]anon([_.]|$)|anon[_-]?key|your[_-]?(key|token|secret|api)|example|placeholder|changeme|xxxx+|<[a-z0-9_]+>|\$\{?[a-z_]|process\.env|import\.meta\.env|os\.getenv|getenv\(|env\(|dummy|sample|test[_-]?key'
}

# Client-exposed destination? (where secrets must NEVER live / get bundled)
is_client_file() {
  echo "$1" | grep -qiE '(^|/)(src|public|static|assets|components?|pages|app|resources/(js|views|css)|client|frontend|www|dist|build|out|\.next|wwwroot|js|scripts)/|\.(jsx?|tsx?|mjs|cjs|vue|svelte|astro|html)$'
}
# Server-side / safe-to-hold-secret file? (.env is gitignored server config — secrets belong here)
is_server_secret_file() {
  echo "$1" | grep -qiE '(^|/)\.env(\.[a-z]+)?$|(^|/)(config|server|app/Config|database)/.*\.(php|rb|py|go|env)$|\.env\.|/secrets?/'
}

block() {
  local why="$1" sample="$2"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) · SECRET-LEAK-BLOCK · tool=$TOOL · why=$why · target=${FP:-cmd} · sample=$(echo "$sample" | head -c 40)" >> "$LOG"
  [[ "$MODE" == "warn" ]] && { echo "⚠️  SECRET-LEAK WARN ($why) — would block in enforce" >&2; exit 0; }
  cat >&2 <<EOF

🔴 ════════ SECRET-LEAK GATE · BLOCKED (mechanical · not a notice) ════════
Why:    $why
Target: ${FP:-$CMD}
A real secret/credential is about to land in CLIENT-EXPOSED code or a deploy bundle.
This is the #1 cause of leaked vibe-coded apps (API keys in client JS / exposed service-role keys).

FIX (no human-review needed — just don't ship the secret):
  • Move the secret to a server-side .env (gitignored). NEVER hardcode in src/public/dist.
  • In client code, read PUBLIC config only (publishable/anon keys), via import.meta.env / process.env.
  • If this is a publishable/anon key, name it clearly (pk_*, *_ANON_KEY) — those are allowed.

Override (only if you are certain it is safe):  NOVA_SECRET_GATE_MODE=warn  (per-command env)

🇲🇾 KENAPA DISEKAT: kunci/secret sebenar akan tertanam dalam kod yang terdedah kepada client atau dalam commit.
   Inilah punca #1 app vibe-coded bocor (API key dalam client JS / service-role key terdedah).
   CARA BETUL: simpan secret dalam fail .env di server (gitignore) — jangan hardcode dalam src/public/dist.
        Dalam kod client, baca config PUBLIC sahaja (pk_* / *_ANON_KEY) — itu dibenarkan.
   Override (hanya jika anda pasti ia selamat): NOVA_SECRET_GATE_MODE=warn
═══════════════════════════════════════════════════════════════════════════
EOF
  exit 2
}

# [CHANGE 2026-09-24] Raw fail-CLOSED net: if NEITHER python3 nor jq is available, structured extraction
#   yields empty ($TOOL blank while raw input carries data). Rather than fail open, scan the raw JSON for a
#   real secret — so a hardcoded key still can't slip through silently on a bare machine. verify: no-parser + AWS key → exit 2.
if [[ -z "$TOOL" && "${#INPUT}" -gt 20 ]]; then
  if echo "$INPUT" | grep -qiE "$SECRET_RE"; then
    is_allowed_value "$INPUT" || block "secret in tool input (no JSON parser present — raw fail-closed scan)" "$INPUT"
  fi
  exit 0
fi

if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" || "$TOOL" == "NotebookEdit" ]] && [[ -n "$NEW" ]]; then
  # ── 0) Framework PUBLIC-prefixed env var carrying a REAL secret — bundled to client by the build
  #       REGARDLESS of file type (this is the #1 accidental leak vector · DeepSeek). Allow anon/publishable.
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -qiE '^[[:space:]]*(export[[:space:]]+)?(NEXT_PUBLIC_|REACT_APP_|VITE_|EXPO_PUBLIC_|VUE_APP_|GATSBY_|PUBLIC_)[A-Z0-9_]*[[:space:]]*[:=]'; then
      if echo "$line" | grep -qiE "$SECRET_RE" || echo "$line" | grep -qiE "$GENERIC_RE"; then
        is_allowed_value "$line" && continue
        block "framework-PUBLIC env var carries a real secret (build bundles it into client)" "$line"
      fi
    fi
  done <<< "$NEW"

  # ── 1) Secret landing in a client-exposed source file ──────────────────────────────────────────
  if is_client_file "$FP" && ! is_server_secret_file "$FP"; then
    # service-account / private-key JSON blob
    if echo "$NEW" | grep -qE '"type"[[:space:]]*:[[:space:]]*"service_account"|"private_key"[[:space:]]*:[[:space:]]*"'; then
      block "service-account / private-key JSON in client-exposed file" "service_account"
    fi
    # line-by-line: secret present AND not an allowed ref/placeholder/publishable
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if echo "$line" | grep -qiE "$SECRET_RE" || echo "$line" | grep -qiE "$GENERIC_RE"; then
        is_allowed_value "$line" && continue
        block "secret hardcoded into client-exposed file" "$line"
      fi
    done <<< "$NEW"
  fi
fi

# ── 2) Deploy/commit/push/build/ship command → scan client + build dirs for secrets ─────────────────
if [[ "$TOOL" == "Bash" ]] && echo "$CMD" | grep -qiE '\b(git (add|commit|push)|npm run build|vite build|next build|yarn build|pnpm build|(scp|rsync)[^|]*\b(dist|build|public)\b|tar[^|]*\b(dist|build)\b|pm2 (deploy|reload|restart)|vercel|netlify deploy|firebase deploy|wrangler (deploy|publish))\b'; then
  # scan the likeliest client/build dirs in CWD (bounded; skip node_modules/.git)
  for dir in dist build public out .next src resources/js; do
    [[ -d "$dir" ]] || continue
    hit=$(grep -rIiE "$SECRET_RE" "$dir" 2>/dev/null \
          --exclude-dir=node_modules --exclude-dir=.git --exclude='*.map' \
          | grep -viE 'pk_live_|pk_test_|publishable|anon|your_|example|placeholder|process\.env|import\.meta\.env' \
          | head -1)
    if [[ -n "$hit" ]]; then
      FP="$dir"; block "secret found in deploy/build dir before ship" "$hit"
    fi
  done
fi

exit 0
