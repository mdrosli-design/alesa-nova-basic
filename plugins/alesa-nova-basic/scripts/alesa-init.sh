#!/usr/bin/env bash
# alesa-init.sh — project continuity setup for ALESA NOVA Basic (/nova-init). Never overwrites anything.
# Creates only what is missing:
#   • a git repository (history = the safety net under every change)
#   • docs/RESUME-BRIEF.md — the baton between sessions, machines and people (read at session start)
#   • CHANGELOG.md — date · file:line — what · why · verify
#   • .gitignore lines that keep secrets out of git (.env, keys) plus notebook/python noise
# Usage: alesa-init.sh [project folder]   (default: current folder)

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../hooks/_lib.sh" || exit 1
DIR="${1:-$PWD}"
cd "$DIR" 2>/dev/null || { echo "alesa-init: folder not found: $DIR" >&2; exit 1; }
L="$(nova_lang)"; TODAY="$(date +%F)"
MADE=""; KEPT=""
made() { MADE="${MADE}  + $1"$'\n'; }
kept() { KEPT="${KEPT}  = $1"$'\n'; }

if command -v git >/dev/null 2>&1 && ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  git init -q && made "git repository"
fi
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
NAME="$(basename "$ROOT")"
mkdir -p "$ROOT/docs"

BRIEF="$ROOT/docs/RESUME-BRIEF.md"
if [ -f "$BRIEF" ]; then kept "docs/RESUME-BRIEF.md (already there — not touched)"
else
  if [ "$L" = ms ]; then
    cat > "$BRIEF" <<EOF
# Brief projek — $NAME

> Baton antara sesi, mesin dan orang. Baca sebelum bekerja; kemas kini dengan \`/nova-checkpoint\`
> sebelum berhenti. Jika brief ini bercanggah dengan git, git yang betul — kemudian betulkan fail ini.

## Status
Baru dimulakan · dikemas kini $TODAY

## Projek
- Apa ia: (isi)
- Cara jalankan: (isi)
- Cara uji: (isi)

## Siap (terkini di atas, dengan bukti)
- $TODAY — projek disediakan dengan /nova-init

## Baki
- [ ] (isi)

## Langkah seterusnya
(satu tindakan seterusnya)

## Amaran & keputusan
- (tiada lagi)
EOF
  else
    cat > "$BRIEF" <<EOF
# Project brief — $NAME

> The baton between sessions, machines and people. Read it before you work; update it with
> \`/nova-checkpoint\` before you stop. If it disagrees with git, git is right — then fix this file.

## Status
Just started · updated $TODAY

## Project
- What it is: (fill in)
- How to run: (fill in)
- How to test: (fill in)

## Done (latest first, with evidence)
- $TODAY — project set up with /nova-init

## Remaining
- [ ] (fill in)

## Next step
(the single next action)

## Warnings & decisions
- (none yet)
EOF
  fi
  made "docs/RESUME-BRIEF.md"
fi

CL="$ROOT/CHANGELOG.md"
if [ -f "$CL" ]; then kept "CHANGELOG.md (already there — not touched)"
else
  printf '# Changelog\n\nFormat: `date · file:line — what · why · verify`\n\n## %s\n- project set up with ALESA NOVA Basic (/nova-init)\n' "$TODAY" > "$CL"
  made "CHANGELOG.md"
fi

GI="$ROOT/.gitignore"; touch "$GI"
added=""
for line in '.env' '.env.*' '!.env.example' '*.pem' 'id_rsa*' 'id_ed25519*' '*.p12' '.ipynb_checkpoints/' '__pycache__/'; do
  grep -qxF -- "$line" "$GI" 2>/dev/null || added="${added}${line}"$'\n'
done
if [ -n "$added" ]; then
  { [ -s "$GI" ] && [ -n "$(tail -c1 "$GI")" ] && echo; echo "# added by ALESA NOVA Basic (/nova-init) — keep secrets and notebook noise out of git"; printf '%s' "$added"; } >> "$GI"
  made ".gitignore: $(printf '%s' "$added" | tr '\n' ' ')"
else
  kept ".gitignore (safety lines already present)"
fi

if [ "$L" = ms ]; then echo "ALESA NOVA Basic · init · $ROOT"; else echo "ALESA NOVA Basic · init · $ROOT"; fi
[ -n "$MADE" ] && printf '%s' "$MADE"
[ -n "$KEPT" ] && printf '%s' "$KEPT"
exit 0
