#!/usr/bin/env bash
# insecure-default-gate.sh — MECHANICAL PreToolUse BLOCK · stops shipping known insecure defaults.
#
# PHILOSOPHY: vibe coders can't spot insecure config — so the SYSTEM blocks it
#   MECHANICALLY (exit 2), not by asking a human and not by trusting a prompt. it ACTS.
#   Answers the survey headline: "RLS disabled · admin access by default · auth not enforced · TLS off".
#
# BLOCKS (high-confidence, rarely legitimate to ship):
#   • Postgres/Supabase  DISABLE ROW LEVEL SECURITY  + fully-permissive RLS policy  USING (true) / WITH CHECK (true)
#   • Firebase open rules:  allow read, write: if true;   /   ".read": true  /  ".write": true
#   • TLS verification disabled: rejectUnauthorized:false · NODE_TLS_REJECT_UNAUTHORIZED=0 · verify=False
#       · InsecureSkipVerify:true · CURLOPT_SSL_VERIFYPEER => false/0
#   • Wildcard CORS WITH credentials: origin '*' + credentials true
#   • Debug mode in a PRODUCTION env file: APP_DEBUG=true / DEBUG=True in .env.prod(uction|.live)
# ALLOWS (no FP): test/spec/mock/fixture/example files; localhost-scoped dev; non-prod .env.
#
# Mode: NOVA_INSECURE_GATE_MODE = enforce (default) | warn | off.  Exit: 0 allow · 2 BLOCK.
# Harness: ~/.claude/hooks/insecure-default-gate.test.sh

set -uo pipefail
MODE="${NOVA_INSECURE_GATE_MODE:-enforce}"
[[ "$MODE" == "off" ]] && exit 0
LOG="$HOME/.nova-basic/insecure-default-gate.log"; mkdir -p "$HOME/.nova-basic"

INPUT="$(cat 2>/dev/null || echo '{}')"
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
NEW=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // ""' 2>/dev/null || echo "")

[[ "$TOOL" == "Write" || "$TOOL" == "Edit" || "$TOOL" == "NotebookEdit" ]] || exit 0
[[ -z "$NEW" ]] && exit 0

# Test/fixture/example files are exempt (insecure settings there are intentional & not shipped to prod).
is_test_file() { echo "$1" | grep -qiE '(^|/)(tests?|spec|__tests__|__mocks__|fixtures?|e2e|cypress|playwright|stories)/|\.(test|spec|stories|cy)\.[a-z]+$|\.(example|sample|dist-info)$|mock|fixture'; }
is_test_file "$FP" && exit 0
# Documentation / notes / memory that merely DESCRIBE a pattern are not SHIPPING it — exempt (prevents FP
# on READMEs, changelogs, security docs, and the framework's own memory that name the dangerous patterns).
is_doc_file() { echo "$1" | grep -qiE '\.(md|markdown|mdx|rst|txt|adoc)$|(^|/)(docs?|memory|notes?)/|(^|/)(readme|changelog|license|contributing)'; }
is_doc_file "$FP" && exit 0

block() {
  local why="$1" sample="$2"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) · INSECURE-DEFAULT-BLOCK · tool=$TOOL · why=$why · target=$FP · sample=$(echo "$sample" | head -c 60)" >> "$LOG"
  [[ "$MODE" == "warn" ]] && { echo "⚠️  INSECURE-DEFAULT WARN ($why) — would block in enforce" >&2; exit 0; }
  cat >&2 <<EOF

🔴 ════════ INSECURE-DEFAULT GATE · BLOCKED (mechanical · not a notice) ════════
Why:    $why
Target: $FP
This is a known insecure default — the #1 way vibe-coded apps expose data
(RLS off / open rules / TLS verification disabled / debug-in-prod / wildcard-CORS+creds).

FIX (no human review needed — just don't ship the insecure default):
  • Keep Row Level Security ENABLED; write a scoped policy (auth.uid() = user_id), never USING (true).
  • Firebase: never  if true; — gate on request.auth != null + ownership.
  • Never disable TLS verification in shipped code (rejectUnauthorized stays true).
  • APP_DEBUG=false / DEBUG=False in production env.
  • CORS: name explicit origins when credentials are allowed (never '*' + credentials).

Override (only if you are certain it is safe):  NOVA_INSECURE_GATE_MODE=warn
═══════════════════════════════════════════════════════════════════════════════
EOF
  exit 2
}

# Normalize for matching (lowercase, collapse spaces; keep a raw copy for case-sensitive env checks)
N=$(printf '%s' "$NEW" | tr '[:upper:]' '[:lower:]' | tr -s ' \t')

# 1) RLS disabled / fully-permissive
echo "$N" | grep -qE 'disable[[:space:]]+row[[:space:]]+level[[:space:]]+security' && block "Postgres/Supabase Row Level Security DISABLED" "DISABLE ROW LEVEL SECURITY"
echo "$N" | grep -qE 'create[[:space:]]+policy.*(using|with[[:space:]]+check)[[:space:]]*\([[:space:]]*true[[:space:]]*\)' && block "fully-permissive RLS policy (USING true)" "policy USING (true)"
echo "$N" | grep -qE 'using[[:space:]]*\([[:space:]]*true[[:space:]]*\)' && echo "$N" | grep -qE '\bpolicy\b|\brls\b|row[[:space:]]+level' && block "fully-permissive RLS policy (USING true)" "USING (true)"

# 2) Firebase open rules
echo "$N" | grep -qE 'allow[[:space:]]+(read|write|read,[[:space:]]*write|get|list|create|update|delete)[[:space:]]*:[[:space:]]*if[[:space:]]+true' && block "Firebase open security rule (if true)" "allow ...: if true"
echo "$N" | grep -qE '"\.(read|write)"[[:space:]]*:[[:space:]]*true' && block "Firebase RTDB open rule (.read/.write: true)" ".read/.write: true"

# 3) TLS verification disabled
echo "$N" | grep -qE 'rejectunauthorized[[:space:]]*:[[:space:]]*false' && block "TLS verification disabled (rejectUnauthorized:false)" "rejectUnauthorized:false"
echo "$N" | grep -qE 'node_tls_reject_unauthorized[[:space:]]*[:=][[:space:]]*["'"'"']?0' && block "TLS verification disabled (NODE_TLS_REJECT_UNAUTHORIZED=0)" "NODE_TLS_REJECT_UNAUTHORIZED=0"
echo "$N" | grep -qE 'insecureskipverify[[:space:]]*:[[:space:]]*true' && block "TLS verification disabled (Go InsecureSkipVerify:true)" "InsecureSkipVerify:true"
echo "$N" | grep -qE 'curlopt_ssl_verify(peer|host)[^,)]*(=>|,)[[:space:]]*(false|0|f)\b' && block "TLS verification disabled (CURLOPT_SSL_VERIFYPEER false)" "CURLOPT_SSL_VERIFYPEER false"
echo "$N" | grep -qE '\bverify[[:space:]]*=[[:space:]]*false\b' && echo "$N" | grep -qE 'requests\.|session\.|\.get\(|\.post\(|httpx' && block "TLS verification disabled (python requests verify=False)" "verify=False"

# 4) Wildcard CORS WITH credentials (the dangerous combo)
if echo "$N" | grep -qE "origin[[:space:]]*:[[:space:]]*['\"]\*['\"]|access-control-allow-origin[[:space:]]*[:=][[:space:]]*['\"]?\*"; then
  echo "$N" | grep -qE 'credentials[[:space:]]*:[[:space:]]*true|access-control-allow-credentials[[:space:]]*[:=][[:space:]]*["'"'"']?true' \
    && block "wildcard CORS origin '*' WITH credentials (exposes authed data cross-site)" "origin:'*' + credentials:true"
fi

# 5) Debug mode in a PRODUCTION env file
if echo "$FP" | grep -qiE '\.env\.(prod|production|live)$'; then
  echo "$N" | grep -qE '(app_debug|debug)[[:space:]]*=[[:space:]]*(true|1|on)\b' && block "DEBUG enabled in a production env file" "DEBUG=true in $FP"
fi

exit 0
