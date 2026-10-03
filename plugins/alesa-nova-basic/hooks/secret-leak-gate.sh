#!/usr/bin/env bash
# secret-leak-gate.sh — PreToolUse(Edit|Write|MultiEdit|NotebookEdit|Bash) · ALESA NOVA Basic
#
# Blocks (exit 2) a real credential before it leaves your machine:
#   1. An edit that puts a real secret into a framework PUBLIC env var (NEXT_PUBLIC_, VITE_, …) — the build
#      bundles those into client code whatever the file type.
#   2. An edit that hardcodes a real secret into a client-exposed file (src/, public/, *.jsx/tsx/vue/html …).
#   3. `git add` / `git commit` / `git push` while the changes about to be committed or pushed contain a real
#      secret: tracked changes, new (untracked, not ignored) files and, for a push, the unpushed commits.
#      Limits: up to 500 new files, files up to 1 MB, 8 MB of changes (a first push scans the history newest-first
#      up to that cap) — when a scan is partial you are told so.
#   4. A deploy/build command while build output (dist/, build/, public/, .next/ …) contains a real secret.
# Recognises cloud, payment, git-hosting and AI-provider keys (OpenAI, Anthropic, Hugging Face, Groq,
# Replicate, OpenRouter, xAI, Perplexity, Google), bot tokens, DB URLs with passwords and private keys.
# Allows: server-side .env (keep it gitignored), env references, publishable/anon keys, and placeholder
# values (the matched token itself must look like a placeholder — a comment saying "example" is not enough).
#
# Mode: NOVA_SECRET_GATE_MODE = enforce (default) | warn | off — set it in settings "env" or before starting
#       Claude Code (an inline VAR=… inside the agent's command does not reach this hook).
# Log:  ~/.nova-basic/secret-leak-gate.log (samples are masked).  Tests: tests/run-tests.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
MODE="$(nova_mode NOVA_SECRET_GATE_MODE enforce)"
[ "$MODE" = off ] && exit 0
nova_read_input; nova_parse

TARGET=""
block() {
  local why="$1" sample="$2" fix="$3"
  nova_log secret-leak-gate.log "BLOCK tool=$NOVA_TOOL why=$why target=${TARGET:-cmd} sample=$(nova_mask "$sample")"
  if [ "$MODE" = warn ]; then
    nova_user_msg "⚠️ NOVA secret-leak (warn mode): $why — ${TARGET:-command}. Would block in enforce mode."
    exit 0
  fi
  if [ "$(nova_lang)" = ms ]; then
    cat >&2 <<EOF
🔴 NOVA · GATE RAHSIA · DISEKAT
Sebab : $why
Sasaran: ${TARGET:-$NOVA_CMD}
Contoh : $(nova_mask "$sample")  (ditapis)
Kunci/kelayakan sebenar akan terdedah (kod client, commit atau bundle deploy).
Cara betul: $fix
Jika kunci ini pernah di-commit atau di-push, anggap ia sudah bocor — tukar (rotate) kunci itu.
Longgarkan (hanya jika pasti selamat): tetapkan NOVA_SECRET_GATE_MODE=warn dalam "env" tetapan Claude Code.
EOF
  else
    cat >&2 <<EOF
🔴 NOVA · SECRET-LEAK GATE · BLOCKED
Why    : $why
Target : ${TARGET:-$NOVA_CMD}
Sample : $(nova_mask "$sample")  (masked)
A real credential is about to be exposed (client code, a commit, or a deploy bundle).
Fix    : $fix
If this key was ever committed or pushed, treat it as leaked and rotate it.
Relax (only if you are sure it is safe): set NOVA_SECRET_GATE_MODE=warn in Claude Code settings "env".
EOF
  fi
  exit 2
}

FIX_CLIENT="keep the secret server-side (e.g. a gitignored .env read by your backend); in client code use only publishable/anon keys via import.meta.env / process.env."
FIX_COMMIT="remove the secret from the file (load it from a gitignored .env or a secret manager), make sure .env is in .gitignore, then commit again."

is_client_file() {
  printf '%s' "$1" | grep -qiE '(^|/)(src|public|static|assets|components?|pages|app|resources/(js|views|css)|client|frontend|www|dist|build|out|\.next|wwwroot|js|scripts)/|\.(jsx?|tsx?|mjs|cjs|vue|svelte|astro|html)$'
}
is_server_secret_file() {
  printf '%s' "$1" | grep -qiE '(^|/)\.env(\.[a-z]+)?$|(^|/)(config|server|app/Config|database)/.*\.(php|rb|py|go|env)$|\.env\.|/secrets?/'
}

# ── 0) No usable JSON payload (bare machine or unreadable input): scan the raw input so a secret cannot slip
#       through silently.
if [ "$NOVA_PARSER" = sed ] && [ "$NOVA_TOOL" != Bash ]; then
  if nova_line_has_real_secret "$NOVA_INPUT"; then
    TARGET="$NOVA_PATH"
    block "secret in tool input (no JSON parser available — raw scan)" "$(nova_first_secret "$NOVA_INPUT")" "$FIX_CLIENT"
  fi
  exit 0
fi

# ── 1-2) Edits
case "$NOVA_TOOL" in
  Write|Edit|MultiEdit|NotebookEdit)
    [ -n "$NOVA_PAYLOAD" ] || exit 0
    TARGET="$NOVA_PATH"
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      if printf '%s' "$line" | grep -qiE '^[[:space:]]*(export[[:space:]]+)?(NEXT_PUBLIC_|REACT_APP_|VITE_|EXPO_PUBLIC_|VUE_APP_|GATSBY_|PUBLIC_)[A-Z0-9_]*[[:space:]]*[:=]'; then
        nova_line_has_real_secret "$line" \
          && block "a framework PUBLIC env var carries a real secret (the build ships it to every browser)" "$(nova_first_secret "$line")" "$FIX_CLIENT"
      fi
    done <<< "$NOVA_PAYLOAD"
    if is_client_file "$NOVA_PATH" && ! is_server_secret_file "$NOVA_PATH"; then
      if printf '%s' "$NOVA_PAYLOAD" | grep -qE '"type"[[:space:]]*:[[:space:]]*"service_account"|"private_key"[[:space:]]*:[[:space:]]*"'; then
        block "service-account / private-key JSON in a client-exposed file" "service_account" "$FIX_CLIENT"
      fi
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        nova_line_has_real_secret "$line" && block "secret hardcoded into a client-exposed file" "$(nova_first_secret "$line")" "$FIX_CLIENT"
      done <<< "$NOVA_PAYLOAD"
    fi
    exit 0 ;;
  Bash) : ;;
  *) exit 0 ;;
esac

# ── 3-4) Commands
CMD="$NOVA_CMD"; [ -n "$CMD" ] || exit 0
# [CHANGE 2026-10-03] what: the git invocation (global options, quoted -C paths, /usr/bin/git) is parsed by the
#   shared helpers in _lib.sh · why: `git -C "/a b" commit`, `git -c x=y push` and `git commit -C HEAD` skipped or
#   misdirected the scan (review findings) · verify: tests S37-S42.
# The folder: a leading `cd <dir> &&`, then the -C options of the git invocation itself.
WORKDIR="$(nova_cmd_dir "$CMD" "${NOVA_CWD:-$PWD}")"
END='([[:space:];&|)`]|$)'
GITINV="$(printf '%s' "$CMD" | grep -oE "${NOVA_GIT_RE}(push|add|commit)$END" | head -1)"
[ -n "$GITINV" ] && WORKDIR="$(nova_git_dir "$GITINV" "$WORKDIR")"

SCAN_BYTES=8000000
WARN=""
# Writes the raw change stream (diff-style "+" lines under "+++ b/<file>" headers) that a git add/commit/push
# would publish; notes about what could not be scanned go to fd 3.
git_changes() {
  local root="$1" kind="$2" n=0
  git -C "$root" diff HEAD --no-color --no-ext-diff -U0 2>/dev/null \
    || git -C "$root" diff --cached --no-color --no-ext-diff -U0 2>/dev/null
  git -C "$root" ls-files -o --exclude-standard 2>/dev/null | while IFS= read -r f; do
    n=$((n + 1))
    if [ "$n" -gt 500 ]; then echo "more-than-500-new-files" >&3; break; fi
    p="$root/$f"; [ -f "$p" ] || continue
    if [ "$(wc -c < "$p" 2>/dev/null | tr -d ' ')" -gt 1048576 ] 2>/dev/null; then echo "large:$f" >&3; continue; fi
    grep -Iq . "$p" 2>/dev/null || continue
    printf 'diff --git a/%s b/%s\n+++ b/%s\n@@ new file @@\n' "$f" "$f" "$f"; sed 's/^/+/' "$p" 2>/dev/null
  done
  if [ "$kind" = push ]; then
    if git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
      git -C "$root" log -p --no-color --no-ext-diff '@{u}..HEAD' 2>/dev/null
    else
      git -C "$root" log -p --no-color --no-ext-diff HEAD 2>/dev/null   # first push: whole history, newest first, until the 8 MB cap (reported)
    fi
  fi
}

kind=""
if printf '%s' "$CMD" | grep -qE "${NOVA_GIT_RE}push$END"; then kind=push
elif printf '%s' "$CMD" | grep -qE "${NOVA_GIT_RE}(add|commit)$END"; then kind=commit
fi
# --git-dir / --work-tree point git at a repository this scan cannot locate reliably: say so instead of guessing.
case "$GITINV" in *--git-dir*|*--work-tree*) [ -n "$kind" ] && WARN="--git-dir/--work-tree used: the changes were not scanned"; kind="" ;; esac
if [ -n "$kind" ] && command -v git >/dev/null 2>&1; then
  root="$(git -C "$WORKDIR" rev-parse --show-toplevel 2>/dev/null)"
  if [ -n "$root" ]; then
    RAW="$(mktemp "${TMPDIR:-/tmp}/nova-scan.XXXXXX" 2>/dev/null)"; NOTES="$(mktemp "${TMPDIR:-/tmp}/nova-notes.XXXXXX" 2>/dev/null)"
    trap 'rm -f "${RAW:-}" "${NOTES:-}"' EXIT          # set at once, so a half-created pair is cleaned up too
    hit=""
    # [CHANGE 2026-10-03] what: "+++ " counts as a file header only between "diff --git" and the first "@@" ·
    #   why: an added line whose text starts with "++ " is shown as "+++ …" and was mistaken for a header, so a
    #   secret on it was never checked (review finding) · verify: tests S34, S35.
    TAG='/^diff --git /{h=1; next} h && /^\+\+\+ /{f=substr($0,5); sub(/^b\//,"",f); next} h && /^@@/{h=0; next} h{next} /^@@/{next} /^\+/{print f "\t" substr($0,2)}'
    if [ -n "$RAW" ] && [ -n "$NOTES" ]; then
      git_changes "$root" "$kind" 3>"$NOTES" | head -c "$SCAN_BYTES" > "$RAW"
      while IFS= read -r l; do
        nova_line_has_real_secret "${l#*	}" "$NOVA_SECRET_RE_COMMIT" && { hit="$l"; break; }
      done < <(awk "$TAG" "$RAW" | grep -E "$NOVA_SECRET_RE_COMMIT")
    else
      # no writable temp folder: still scan, streaming (only the "was it complete?" check is lost)
      WARN="could not check whether the scan was complete (no writable temp folder)"
      while IFS= read -r l; do
        nova_line_has_real_secret "${l#*	}" "$NOVA_SECRET_RE_COMMIT" && { hit="$l"; break; }
      done < <(git_changes "$root" "$kind" 3>/dev/null | head -c "$SCAN_BYTES" | awk "$TAG" | grep -E "$NOVA_SECRET_RE_COMMIT")
    fi
  fi
  if [ -n "$root" ]; then
    if [ -n "$hit" ]; then
      TARGET="$root/${hit%%	*}"
      if [ "$kind" = push ]; then
        block "a real secret is in the changes about to be pushed" "$(nova_first_secret "${hit#*	}" "$NOVA_SECRET_RE_COMMIT")" \
          "remove it from the file AND from the commit (git commit --amend, or an interactive rebase for older commits), rotate the key, then push."
      fi
      block "a real secret is in the changes about to be committed" "$(nova_first_secret "${hit#*	}" "$NOVA_SECRET_RE_COMMIT")" "$FIX_COMMIT"
    fi
    if [ -n "$RAW" ] && [ -n "$NOTES" ]; then
      [ "$(wc -c < "$RAW" | tr -d ' ')" -ge "$SCAN_BYTES" ] && WARN="${WARN}${WARN:+, }more than 8 MB of changes"
      grep -q '^more-than-500-new-files' "$NOTES" && WARN="${WARN}${WARN:+, }more than 500 new files"
      nb="$(grep -c '^large:' "$NOTES" 2>/dev/null)"; [ "${nb:-0}" -gt 0 ] && WARN="${WARN}${WARN:+, }$nb new file(s) over 1 MB"
    fi
  fi
fi

if printf '%s' "$CMD" | grep -qiE '(^|[[:space:];&|(])(npm run build|vite build|next build|yarn build|pnpm build|bun run build|(scp|rsync)[^|;&]*(dist|build|public)|pm2 (deploy|reload|restart)|vercel|netlify deploy|firebase deploy|wrangler (deploy|publish))' \
   || printf '%s' "$CMD" | grep -qE "${NOVA_GIT_RE}push$END"; then
  for dir in dist build public out .next src resources/js; do
    [ -d "$WORKDIR/$dir" ] || continue
    nh=0
    while IFS= read -r hitline; do
      [ -n "$hitline" ] || continue
      nh=$((nh + 1))
      if [ "$nh" -gt 2000 ]; then WARN="${WARN}${WARN:+, }more than 2000 secret-like strings in $dir/"; break; fi
      if nova_line_has_real_secret "${hitline#*:}" "$NOVA_SECRET_RE_COMMIT"; then
        TARGET="${hitline%%:*}"
        block "a real secret is inside build/deploy output" "$(nova_first_secret "${hitline#*:}" "$NOVA_SECRET_RE_COMMIT")" "$FIX_CLIENT"
      fi
    done < <(grep -rIE --exclude-dir=node_modules --exclude-dir=.git --exclude='*.map' "$NOVA_SECRET_RE_COMMIT" "$WORKDIR/$dir" 2>/dev/null | head -2001)   # options first: BSD grep stops parsing options at the first operand
  done
fi

if [ -n "$WARN" ]; then
  nova_log secret-leak-gate.log "PARTIAL $WARN"
  if [ "$(nova_lang)" = ms ]; then
    nova_user_msg "⚠️ NOVA: imbasan rahsia hanya separa ($WARN) — semak fail itu sendiri sebelum push."
  else
    nova_user_msg "⚠️ NOVA: the secret scan was partial ($WARN) — check those files yourself before pushing."
  fi
fi
exit 0
