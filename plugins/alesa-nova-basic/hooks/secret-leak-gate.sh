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
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
NEW=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // ""' 2>/dev/null || echo "")

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
═══════════════════════════════════════════════════════════════════════════
EOF
  exit 2
}

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
