#!/usr/bin/env bash
# insecure-default-gate.sh — PreToolUse(Edit|Write|MultiEdit|NotebookEdit|Bash) · ALESA NOVA Basic
#
# Blocks (exit 2) known insecure defaults before they ship:
#   • Row Level Security disabled / fully permissive USING (true) policies (Postgres, Supabase)
#   • Firebase rules open to everyone (allow …: if true · ".read"/".write": true)
#   • TLS certificate verification disabled (rejectUnauthorized:false · NODE_TLS_REJECT_UNAUTHORIZED=0 ·
#     requests verify=False · Go InsecureSkipVerify · CURLOPT_SSL_VERIFYPEER false)
#   • wildcard CORS origin together with credentials
#   • DEBUG enabled in a production env file
#   • Jupyter listening on all network interfaces with an empty token/password — anyone on the network can
#     run code as you (jupyter command line or jupyter config file)
# Warns (shown to you, not blocked): a model server exposed to the network without a key
#   (OLLAMA_HOST=0.0.0.0 · vLLM --host 0.0.0.0 without --api-key) · Gradio share=True (public link).
# Exempt: test/spec/fixture/example files and documentation (they describe patterns, they don't ship them).
#
# Mode: NOVA_INSECURE_GATE_MODE = enforce (default) | warn | off (settings "env" or before starting Claude Code).
# Log:  ~/.nova-basic/insecure-default-gate.log   Tests: tests/run-tests.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
MODE="$(nova_mode NOVA_INSECURE_GATE_MODE enforce)"
[ "$MODE" = off ] && exit 0
nova_read_input; nova_parse
WARNINGS=""
warn() { WARNINGS="${WARNINGS}${WARNINGS:+ · }$1"; }

block() {
  local why="$1" fix="$2"
  nova_log insecure-default-gate.log "BLOCK tool=$NOVA_TOOL why=$why target=${NOVA_PATH:-cmd}"
  if [ "$MODE" = warn ]; then
    nova_user_msg "⚠️ NOVA insecure-default (warn mode): $why — would block in enforce mode."
    exit 0
  fi
  if [ "$(nova_lang)" = ms ]; then
    cat >&2 <<EOF
🔴 NOVA · GATE TETAPAN TIDAK SELAMAT · DISEKAT
Sebab  : $why
Sasaran: ${NOVA_PATH:-$(printf '%s' "$NOVA_CMD" | head -c 200)}
Ini tetapan lalai tidak selamat yang biasa mendedahkan data atau mesin.
Cara betul: $fix
Longgarkan (hanya jika pasti): NOVA_INSECURE_GATE_MODE=warn dalam "env" tetapan Claude Code.
EOF
  else
    cat >&2 <<EOF
🔴 NOVA · INSECURE-DEFAULT GATE · BLOCKED
Why    : $why
Target : ${NOVA_PATH:-$(printf '%s' "$NOVA_CMD" | head -c 200)}
This is a known insecure default that commonly exposes data or the machine.
Fix    : $fix
Relax (only if you are sure): NOVA_INSECURE_GATE_MODE=warn in Claude Code settings "env".
EOF
  fi
  exit 2
}
finish() {
  if [ -n "$WARNINGS" ]; then nova_log insecure-default-gate.log "WARN $WARNINGS"; nova_user_msg "⚠️ NOVA: $WARNINGS"; fi
  exit 0
}

EXPOSED_IP='(0\.0\.0\.0|\*|::|\[::\])'
FIX_JUPYTER="keep Jupyter's token or set a password (jupyter server password), or listen on 127.0.0.1 and reach it through an SSH tunnel."

# ── Commands
if [ "$NOVA_TOOL" = Bash ]; then
  C="$(printf '%s' "$NOVA_CMD" | tr '\n' ' ')"
  if printf '%s' "$C" | grep -qE '(^|[^[:alnum:]_-])jupyter([[:space:]]+|-)(notebook|lab|server)([[:space:]]|$)'; then
    if printf '%s ' "$C" | grep -qE -- "--ip(=|[[:space:]]+)[\"']?${EXPOSED_IP}[\"']?[[:space:]]" \
       && printf '%s ' "$C" | grep -qE -- "--(NotebookApp|ServerApp|IdentityProvider)\.(token|password)=(''|\"\"|[[:space:]])"; then
      block "Jupyter on all network interfaces with an empty token/password — anyone on the network can run code as you" "$FIX_JUPYTER"
    fi
  fi
  printf '%s' "$C" | grep -qE "OLLAMA_HOST=[\"']?(0\.0\.0\.0|::|\[::\])" \
    && warn "OLLAMA_HOST=0.0.0.0 exposes your model server to the whole network with no authentication — keep it on 127.0.0.1 unless a proxy with a key sits in front"
  if printf '%s' "$C" | grep -qE '(^|[^[:alnum:]_-])vllm([[:space:]]+serve|\.entrypoints)' \
     && printf '%s ' "$C" | grep -qE -- '--host(=|[[:space:]]+)(0\.0\.0\.0|::)[[:space:]]' \
     && ! printf '%s' "$C" | grep -qE -- '--api-key'; then
    warn "vLLM on 0.0.0.0 without --api-key: anyone on the network can use this GPU — add --api-key or bind to 127.0.0.1"
  fi
  finish
fi

# ── Edits
case "$NOVA_TOOL" in Write|Edit|MultiEdit|NotebookEdit) : ;; *) exit 0 ;; esac
TEXT="$NOVA_PAYLOAD"
[ -n "$TEXT" ] || { [ "$NOVA_PARSER" = sed ] && TEXT="$NOVA_INPUT"; }
[ -n "$TEXT" ] || exit 0
FP="$NOVA_PATH"
# [CHANGE 2026-10-03] what: exemptions only for test/fixture FOLDERS, test-style suffixes and documentation file
#   types · why: the old pattern exempted any path containing "mock"/"fixture" (src/mock-server.ts) and any file
#   under docs/ (review finding) · verify: tests I21-I23.
printf '%s' "$FP" | grep -qiE '(^|/)(tests?|spec|__tests__|__mocks__|fixtures?|e2e|cypress|playwright|stories)/|\.(test|spec|stories|cy|mock|fixture)\.[a-z]+$|\.(example|sample|dist-info)$' && exit 0
printf '%s' "$FP" | grep -qiE '\.(md|markdown|mdx|rst|txt|adoc)$|(^|/)(readme|changelog|license|contributing)(\.[a-z]+)?$' && exit 0

N="$(printf '%s' "$TEXT" | tr '[:upper:]' '[:lower:]' | tr -s ' \t')"

# 1) Row Level Security
printf '%s' "$N" | grep -qE 'disable[[:space:]]+row[[:space:]]+level[[:space:]]+security' \
  && block "Row Level Security DISABLED (Postgres/Supabase)" "keep RLS enabled and write a scoped policy, e.g. USING (auth.uid() = user_id)."
printf '%s' "$N" | grep -qE 'create[[:space:]]+policy.*(using|with[[:space:]]+check)[[:space:]]*\([[:space:]]*true[[:space:]]*\)' \
  && block "fully permissive RLS policy (USING (true))" "scope the policy to the owner, e.g. USING (auth.uid() = user_id)."
# 2) Firebase
printf '%s' "$N" | grep -qE 'allow[[:space:]]+(read|write|read,[[:space:]]*write|get|list|create|update|delete)[[:space:]]*:[[:space:]]*if[[:space:]]+true' \
  && block "Firebase security rule open to everyone (if true)" "require request.auth != null and check ownership."
printf '%s' "$N" | grep -qE '"\.(read|write)"[[:space:]]*:[[:space:]]*true' \
  && block "Firebase Realtime Database rule open to everyone (.read/.write: true)" "require auth and scope rules per user."
# 3) TLS verification
printf '%s' "$N" | grep -qE 'rejectunauthorized[[:space:]]*:[[:space:]]*false' && block "TLS verification disabled (rejectUnauthorized: false)" "keep certificate verification on; trust a custom CA instead of turning checks off."
printf '%s' "$N" | grep -qE 'node_tls_reject_unauthorized[[:space:]]*[:=][[:space:]]*["'"'"']?0' && block "TLS verification disabled (NODE_TLS_REJECT_UNAUTHORIZED=0)" "keep certificate verification on; use NODE_EXTRA_CA_CERTS for a custom CA."
printf '%s' "$N" | grep -qE 'insecureskipverify[[:space:]]*:[[:space:]]*true' && block "TLS verification disabled (InsecureSkipVerify: true)" "keep verification on; add the CA to RootCAs."
printf '%s' "$N" | grep -qE 'curlopt_ssl_verify(peer|host)[^,)]*(=>|,)[[:space:]]*(false|0)([^0-9a-z]|$)' && block "TLS verification disabled (CURLOPT_SSL_VERIFYPEER false)" "keep verification on; point CURLOPT_CAINFO at the CA bundle."
if printf '%s' "$N" | grep -qE '(^|[^[:alnum:]_])verify[[:space:]]*=[[:space:]]*false([^[:alnum:]_]|$)' && printf '%s' "$N" | grep -qE 'requests\.|session\.|\.get\(|\.post\(|httpx'; then
  block "TLS verification disabled (verify=False)" "remove verify=False; pass verify='/path/to/ca.pem' for a private CA."
fi
# 4) Wildcard CORS with credentials
if printf '%s' "$N" | grep -qE "origin[[:space:]]*:[[:space:]]*['\"]\*['\"]|access-control-allow-origin[[:space:]]*[:=][[:space:]]*['\"]?\*"; then
  printf '%s' "$N" | grep -qE 'credentials[[:space:]]*:[[:space:]]*true|access-control-allow-credentials[[:space:]]*[:=][[:space:]]*["'"'"']?true' \
    && block "wildcard CORS origin '*' WITH credentials (exposes signed-in data to any site)" "list the exact allowed origins when credentials are enabled."
fi
# 5) Debug in a production env file
if printf '%s' "$FP" | grep -qiE '\.env\.(prod|production|live)$'; then
  printf '%s' "$N" | grep -qE '(app_debug|debug)[[:space:]]*=[[:space:]]*(true|1|on)([^[:alnum:]]|$)' \
    && block "DEBUG enabled in a production env file" "set APP_DEBUG=false / DEBUG=False in production."
fi
# 6) Jupyter config: empty token + all interfaces
if printf '%s' "$N" | grep -qE "(notebookapp|serverapp|identityprovider)\.(token|password)[[:space:]]*=[[:space:]]*(''|\"\")|\"(token|password)\"[[:space:]]*:[[:space:]]*\"\""; then
  if printf '%s' "$N" | grep -qE "(notebookapp|serverapp)\.ip[[:space:]]*=[[:space:]]*['\"]${EXPOSED_IP}['\"]|\"ip\"[[:space:]]*:[[:space:]]*\"${EXPOSED_IP}\""; then
    block "Jupyter config: empty token/password while listening on all network interfaces" "$FIX_JUPYTER"
  fi
fi
# Warnings — model servers and public share links
printf '%s' "$N" | grep -qE "ollama_host[[:space:]]*[:=][[:space:]]*[\"']?(0\.0\.0\.0|::)" \
  && warn "OLLAMA_HOST=0.0.0.0 exposes the model server to the whole network with no authentication"
printf '%s' "$N" | grep -qE '\.launch\([^)]*share[[:space:]]*=[[:space:]]*true' \
  && warn "Gradio share=True creates a public internet link to this app — do not use it with private data"
finish
