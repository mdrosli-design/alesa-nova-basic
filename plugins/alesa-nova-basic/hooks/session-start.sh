#!/usr/bin/env bash
# session-start.sh — SessionStart · ALESA NOVA Basic
#
# Gives the agent the working method (3 Laws) at the start of every session, and — when the project has a
# brief (docs/RESUME-BRIEF.md, created by /nova-init) — points it at the brief and its "Next step", so work
# continues where the last session stopped (on any machine: the brief travels with the repo).
# Housekeeping, at most once a day: prunes backups older than NOVA_BACKUP_KEEP_DAYS (14) and activity logs
# older than NOVA_LOG_KEEP_DAYS (90). Set either to 0 to keep everything.
# Output: plain stdout, which Claude Code adds to the session context. Off switch: NOVA_SESSION_CONTEXT=off.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
nova_read_input; nova_parse

# ── housekeeping (once a day)
mkdir -p "$NOVA_HOME/state" 2>/dev/null
today="$(date +%F)"
if [ "$(cat "$NOVA_HOME/state/last-prune" 2>/dev/null)" != "$today" ]; then
  printf '%s' "$today" > "$NOVA_HOME/state/last-prune" 2>/dev/null
  kb="${NOVA_BACKUP_KEEP_DAYS:-14}"; kl="${NOVA_LOG_KEEP_DAYS:-90}"
  if [ "$kb" -gt 0 ] 2>/dev/null && [ -d "$NOVA_HOME/backups" ]; then
    find "$NOVA_HOME/backups" -type f -mtime +"$kb" -exec rm -f {} + 2>/dev/null
    find "$NOVA_HOME/backups" -mindepth 1 -type d -empty -exec rmdir {} + 2>/dev/null
  fi
  if [ "$kl" -gt 0 ] 2>/dev/null && [ -d "$NOVA_HOME/activity" ]; then
    find "$NOVA_HOME/activity" -type f -name '*.jsonl' -mtime +"$kl" -exec rm -f {} + 2>/dev/null
  fi
fi

[ "$(nova_mode NOVA_SESSION_CONTEXT on)" = off ] && exit 0

dir="${NOVA_CWD:-$PWD}"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"; [ -n "$root" ] || root="$dir"
brief=""
for b in "$dir/docs/RESUME-BRIEF.md" "$root/docs/RESUME-BRIEF.md"; do [ -f "$b" ] && { brief="$b"; break; }; done

next=""; updated=""
if [ -n "$brief" ]; then
  updated="$(date -r "$brief" +%F 2>/dev/null || stat -c %y "$brief" 2>/dev/null | cut -c1-10)"
  next="$(awk 'tolower($0) ~ /^##+[[:space:]]*(next step|langkah seterusnya)/ {f=1; next}
               f && /^##/ {exit}
               f && NF && $0 !~ /^[[:space:]]*\(/ {print; n++; if (n >= 3) exit}' "$brief" 2>/dev/null | cut -c1-300)"
fi
# show the brief relative to the project (cwd and git root can differ by a symlink, e.g. /tmp vs /private/tmp)
rel="${brief#"$dir"/}"; [ "$rel" = "$brief" ] && rel="${brief#"$root"/}"

if [ "$(nova_lang)" = ms ]; then
  cat <<EOF
ALESA NOVA Basic aktif (v${NOVA_VERSION:-?}). Kaedah kerja — ikut sepanjang sesi ini:
1. Baca sebelum tulis: lihat kod/konfigurasi sedia ada sebelum mengubahnya.
2. Backup sebelum ubah: automatik (salinan di ~/.nova-basic/backups/).
3. Sahkan selepas ubah: jalankan ujian/arahan sebenar dan tunjuk hasilnya sebelum kata "siap". Lint/kompil sahaja bukan pengesahan. Jika tidak dapat disahkan, nyatakan terus terang.
Pagar: kebocoran rahsia, arahan memusnahkan dan tetapan tidak selamat disekat secara mekanikal — bila disekat, betulkan puncanya; jangan cari jalan memintas.
Bahasa: pengguna ini menetapkan Bahasa Malaysia (NOVA_LANG=ms) — balas dalam Bahasa Malaysia.
EOF
  if [ -n "$brief" ]; then
    printf 'Brief projek: %s (dikemas kini %s) — BACA DAHULU sebelum bekerja; teruskan dari "Langkah seterusnya".\n' "$rel" "${updated:-?}"
    [ -n "$next" ] && printf 'Langkah seterusnya (dari brief):\n%s\n' "$next"
  elif [ -d "$root/.git" ]; then
    echo "Tiada brief projek lagi — /nova-init menyediakannya (kesinambungan antara sesi dan mesin)."
  fi
else
  cat <<EOF
ALESA NOVA Basic is active (v${NOVA_VERSION:-?}). Working method — follow it for this whole session:
1. Read before you write: look at the existing code/config before changing it.
2. Back up before you change: automatic (copies in ~/.nova-basic/backups/).
3. Verify after you change: run the real test/command and show the result before saying "done". Lint or a green compile alone is not verification. If you could not verify, say so plainly.
Guards: secret leaks, destructive commands and insecure defaults are blocked mechanically — when one blocks you, fix the cause; do not look for a way around it.
EOF
  if [ -n "$brief" ]; then
    printf 'Project brief: %s (updated %s) — READ IT FIRST, then continue from its "Next step".\n' "$rel" "${updated:-?}"
    [ -n "$next" ] && printf 'Next step (from the brief):\n%s\n' "$next"
  elif [ -d "$root/.git" ]; then
    echo "No project brief yet — /nova-init sets one up (continuity across sessions and machines)."
  fi
fi
exit 0
