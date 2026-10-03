#!/usr/bin/env bash
# dangerous-command-gate.sh — PreToolUse(Bash) · ALESA NOVA Basic
#
# Blocks (exit 2) catastrophic, hard-to-undo commands BEFORE they run. It stops the AGENT, not you: if you
# really need one of these, run it yourself in your own terminal.
#
# BLOCKS
#   • recursive delete of /, your home folder, a top-level system folder or another user's home;
#     --no-preserve-root; sudo rm -r…; find <one of those> -delete / -exec rm
#   • DROP DATABASE · DROP SCHEMA · DROP TABLE · TRUNCATE TABLE
#   • git push --force / -f / --force-with-lease / +refspec / --mirror · --no-verify (skips safety hooks)
#   • git reset --hard, git checkout -- . or git restore . while there are uncommitted changes · git clean -f
#   • piping a download into a shell: curl … | bash · bash <(curl …) · sh -c "$(curl …)"
#   • shared-machine hazards: docker system prune -a/--volumes · docker volume prune · docker image prune -a ·
#     mass docker rm/rmi $(docker …) · shutdown/reboot/poweroff/halt · kill -9 -1 · mkfs/wipefs ·
#     dd onto a disk device · chmod -R 777 · fork bomb
# WARNS (shown to you, not blocked): migrate:fresh/reset/rollback · db:wipe · prisma migrate reset ·
#   plain docker system prune · git reset --hard <commit> on a clean tree
#
# Mode: NOVA_DANGER_GATE_MODE = enforce (default) | warn | off — set in settings "env" or before starting
#       Claude Code (an inline VAR=… inside the agent's command does not reach this hook).
# Log:  ~/.nova-basic/dangerous-command-gate.log   Tests: tests/run-tests.sh

set -uo pipefail
source "${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh" || exit 0   # Claude Code exports CLAUDE_PLUGIN_ROOT to plugin hooks
MODE="$(nova_mode NOVA_DANGER_GATE_MODE enforce)"
[ "$MODE" = off ] && exit 0
nova_read_input; nova_parse

CMD="$NOVA_CMD"
[ -z "$CMD" ] && [ -z "$NOVA_TOOL" ] && CMD="$NOVA_INPUT"      # nothing parsed: scan the raw input
[ -n "$NOVA_TOOL" ] && [ "$NOVA_TOOL" != Bash ] && exit 0
[ -n "$CMD" ] || exit 0
WORKDIR="${NOVA_CWD:-$PWD}"
C="$(printf '%s' "$CMD" | tr '\n' ';')"
WARNINGS=""

block() {
  local why="$1" safer="${2:-}"
  nova_log dangerous-command-gate.log "BLOCK why=$why cmd=$(nova_redact "$(printf '%s' "$CMD" | head -c 120)")"
  if [ "$MODE" = warn ]; then
    nova_user_msg "⚠️ NOVA dangerous-command (warn mode): $why — would block in enforce mode."
    exit 0
  fi
  if [ "$(nova_lang)" = ms ]; then
    cat >&2 <<EOF
🔴 NOVA · GATE ARAHAN BAHAYA · DISEKAT
Arahan : $(nova_redact "$(printf '%s' "$CMD" | head -c 200)")
Sebab  : $why
Ini operasi memusnahkan yang biasanya tidak boleh diundur. Gate ini menahan AGEN, bukan anda —
jika anda betul-betul mahu, jalankan sendiri di terminal anda.${safer:+
Lebih selamat: $safer}
Longgarkan (hanya jika pasti): NOVA_DANGER_GATE_MODE=warn dalam "env" tetapan Claude Code.
EOF
  else
    cat >&2 <<EOF
🔴 NOVA · DANGEROUS-COMMAND GATE · BLOCKED
Command: $(nova_redact "$(printf '%s' "$CMD" | head -c 200)")
Why    : $why
This is a destructive, usually irreversible operation. This gate stops the AGENT, not you —
if you really mean it, run it yourself in your own terminal.${safer:+
Safer  : $safer}
Relax (only if you are sure): NOVA_DANGER_GATE_MODE=warn in Claude Code settings "env".
EOF
  fi
  exit 2
}
warn() { WARNINGS="${WARNINGS}${WARNINGS:+ · }$1"; }

strip_quotes() { local t="$1"; t="${t#\"}"; t="${t%\"}"; t="${t#\'}"; t="${t%\'}"; printf '%s' "$t"; }
# [CHANGE 2026-10-03] what: resolve //, /./ and parent-directory segments in absolute targets before matching ·
#   why: `rm -rf /./` and `rm -rf /tmp/<parent>/` reached / unmatched (review finding) · verify: tests D61, D62.
norm_path() {
  local p="$1" out="" seg IFS='/' UP=.
  UP="$UP$UP"   # the parent-directory segment, built so the file names no such path literally
  case "$p" in /*) : ;; *) printf '%s' "$p"; return ;; esac
  set -f
  for seg in $p; do
    case "$seg" in ""|.) continue ;; "$UP") out="${out%/*}" ;; *) out="$out/$seg" ;; esac
  done
  set +f
  printf '%s' "${out:-/}"
}
# Targets whose recursive deletion is never a legitimate agent action.
is_catastrophic_target() {
  local t; t="$(norm_path "$(strip_quotes "$1")")"
  case "$t" in
    /|//|/.|'/*'|'~'|'~/'|'~/*'|'~/.'|'$HOME'|'$HOME/'|'$HOME/*'|'${HOME}'|'${HOME}/'|'${HOME}/*') return 0 ;;
  esac
  local n="${t%/}"; n="${n%/\*}"; n="${n%/}"
  case "$n" in
    /home|/Users|/root|/etc|/usr|/var|/bin|/sbin|/lib|/lib32|/lib64|/opt|/boot|/dev|/proc|/sys|/srv|/mnt|/media|/snap|/System|/Library|/Applications|/private|/Volumes) return 0 ;;
    /home/*/*|/Users/*/*) return 1 ;;
    /home/*|/Users/*) return 0 ;;     # a whole user's home folder
  esac
  return 1
}
# [CHANGE 2026-10-03] what: git invocations are parsed by the shared helpers in _lib.sh (global options, quoted
#   -C paths, /usr/bin/git, quoted arguments holding ; or flag text) and short-option clusters (-fu, commit -n)
#   are read · why: each of these forms slipped past a git rule here (review findings) · verify: tests D65-D78.
GITRE="$NOVA_GIT_RE"
BASEDIR="$(nova_cmd_dir "$C" "$WORKDIR")"
repo_dir() {   # the repository a git invocation works in: the leading cd, then that invocation's own -C options
  nova_git_dir "$(printf '%s' "$1" | grep -oE "${GITRE}[a-z-]+" | head -1)" "$BASEDIR"
}
is_dirty() { [ -n "$(git -C "$1" status --porcelain --untracked-files=no 2>/dev/null | head -1)" ]; }
other_tree() { case "$1" in *--git-dir*|*--work-tree*) return 0 ;; esac; return 1; }
git_args() {   # git_args <invocation> <subcommand> → everything after the subcommand
  local pre; pre="$(printf '%s' "$1" | grep -oE "${GITRE}$2" | head -1)"; printf '%s' "${1#"$pre"}"
}
# short_flag <args> <letter> <value-letters> [<attached-value-letters>] → 0 when the short option is given, alone
# or in a cluster (-fu). A letter that takes a value ends its cluster; last in the cluster it uses up the next word.
short_flag() {
  local w c i skip=0
  while IFS= read -r w; do
    [ "$skip" = 1 ] && { skip=0; continue; }
    case "$w" in -*|\"*|\'*|\\*) : ;; *) continue ;; esac              # cannot be an option
    case "$w" in *[\"\'\\]*) w="$(nova_unquote "$w")" ;; esac             # unquote only when needed
    case "$w" in --) return 1 ;; --*|-) continue ;; -*) : ;; *) continue ;; esac
    i=1
    while [ "$i" -lt "${#w}" ]; do
      c="${w:$i:1}"
      [ "$c" = "$2" ] && return 0
      case "${4:-}" in *"$c"*) break ;; esac
      case "$3" in *"$c"*) [ "$i" -eq $((${#w} - 1)) ] && skip=1; break ;; esac
      i=$((i + 1))
    done
  done < <(printf '%s' "$1" | grep -oE "$NOVA_SH_WORD")
  return 1
}

# ── fork bomb (checked on the raw text before any splitting)
case "$CMD" in *':(){ :|:& };:'*|*':(){:|:&};:'*|*':(){ :|: & };:'*) block "fork bomb — would freeze the machine for every user" ;; esac

# ── recursive delete
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  inv="$(printf '%s' "$inv" | sed -E 's/^[;&|(`[:space:]]+//')"
  rec=0; sud=0; npr=0; seen_rm=0; bad=""
  set -f
  for tok in $inv; do
    if [ "$seen_rm" = 0 ]; then
      case "$(strip_quotes "${tok#\\}")" in sudo) sud=1 ;; rm|*/rm) seen_rm=1 ;; esac
      continue
    fi
    case "$tok" in
      --recursive) rec=1 ;;
      --no-preserve-root) npr=1 ;;
      --*) : ;;
      -?*) case "$tok" in *[rR]*) rec=1 ;; esac ;;
      *) if is_catastrophic_target "$tok"; then bad="$tok"
         else case "$(strip_quotes "$tok")" in '/*'|'~/*'|'$HOME/*'|'${HOME}/*') bad="$tok" ;; esac
         fi ;;
    esac
  done
  set +f
  [ "$npr" = 1 ] && block "rm --no-preserve-root (deletes the whole system)"
  [ "$sud" = 1 ] && [ "$rec" = 1 ] && block "recursive delete with sudo (admin rights — can wipe system or other users' files)" "delete inside your own project with a relative path, without sudo."
  if [ -n "$bad" ]; then
    case "$(strip_quotes "$bad")" in
      '/*'|'~/*'|'$HOME/*'|'${HOME}/*') block "deletes everything in $(strip_quotes "$bad")" ;;
    esac
    [ "$rec" = 1 ] && block "recursive delete of $(strip_quotes "$bad") (system root, a home folder or a system folder)" "delete only the specific folder inside your project, e.g. rm -rf ./build"
  fi
done < <(printf '%s' "$C" | grep -oE '(^|[[:space:];&|(`])(sudo[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*)?([^[:space:];&|(`]*/)?[\\"'"'"']?rm["'"'"']?[[:space:]]+[^;&|)`]*' 2>/dev/null)

while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  inv="$(printf '%s' "$inv" | sed -E 's/^[;&|(`[:space:]]+//')"
  printf '%s' "$inv" | grep -qE -- '-delete|-exec[[:space:]]+rm' || continue
  first=""; set -f
  for tok in $inv; do case "$tok" in find|*/find|sudo) continue ;; -*) break ;; *) first="$tok"; break ;; esac; done
  set +f
  [ -n "$first" ] && is_catastrophic_target "$first" && block "find $(strip_quotes "$first") … -delete (mass delete from a system or home folder)"
done < <(printf '%s' "$C" | grep -oE '(^|[[:space:];&|(`])(sudo[[:space:]]+)?find[[:space:]]+[^;&|)`]*' 2>/dev/null)

# ── databases
printf '%s' "$C" | grep -qiE '(^|[^[:alnum:]_])(drop[[:space:]]+(database|schema|table)|truncate[[:space:]]+table)[[:space:]]' \
  && block "destroys database data (DROP / TRUNCATE)" "back up first (e.g. mysqldump / pg_dump) and run it yourself after checking you are not on production."

# ── git
NOTREE="cannot check that repository for uncommitted changes when --git-dir/--work-tree is used"
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  a="$(git_args "$inv" push)"
  if short_flag "$a" f o || printf ' %s ' "$a" | tr -d "\"'" | grep -qE '[[:space:]](--force|--force-with-lease(=[^[:space:]]*)?|--force-if-includes|--mirror)[[:space:]]|[[:space:]]\+[^[:space:]]+'; then
    block "force push overwrites the remote history (other people's or your earlier work is lost)" "git pull --rebase, resolve conflicts, then a normal git push."
  fi
done < <(printf '%s' "$C" | grep -oE "${GITRE}push${NOVA_SH_ARGS}" 2>/dev/null)
printf '%s ' "$C" | grep -qE "${GITRE}[a-z-]+${NOVA_SH_ARGS}[[:space:]]--no-verify([[:space:];&|)\`]|\$)" \
  && block "--no-verify skips the repository's safety checks (pre-commit / pre-push hooks)" "fix what the hook reports, then commit normally."
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  short_flag "$(git_args "$inv" commit)" n cCFmt uS \
    && block "git commit -n is --no-verify: it skips the repository's safety checks (pre-commit / commit-msg hooks)" "fix what the hook reports, then commit normally."
done < <(printf '%s' "$C" | grep -oE "${GITRE}commit${NOVA_SH_ARGS}" 2>/dev/null)
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  a="$(git_args "$inv" reset)"
  printf '%s ' "$a" | grep -qE '[[:space:]]--hard[[:space:]]' || continue
  other_tree "$inv" && block "git reset --hard: $NOTREE" "run git status there first, then reset yourself if it is clean."
  dir="$(repo_dir "$inv")"
  is_dirty "$dir" && block "git reset --hard would throw away uncommitted changes in $dir" "commit or stash first (git stash), then reset."
  tgt="$(printf '%s' "$a" | sed -nE 's/.*--hard[[:space:]]+([^-[:space:]][^[:space:]]*).*/\1/p')"
  [ -n "$tgt" ] && [ "$tgt" != HEAD ] && warn "git reset --hard $tgt moves the branch back; later commits are recoverable only through git reflog"
done < <(printf '%s' "$C" | grep -oE "${GITRE}reset${NOVA_SH_ARGS}" 2>/dev/null)
inv="$(printf '%s ' "$C" | grep -oE "${GITRE}(checkout([[:space:]]+HEAD)?([[:space:]]+--)?|restore([[:space:]]+--(worktree|staged))*)[[:space:]]+(\.|:/|\*)[[:space:];]" | head -1)"
if [ -n "$inv" ]; then
  other_tree "$inv" && block "discarding all changes: $NOTREE" "commit or stash first, or restore only the specific file you mean."
  dir="$(repo_dir "$inv")"
  is_dirty "$dir" && block "this discards every uncommitted change in $dir" "commit or stash first, or restore only the specific file you mean."
fi
while IFS= read -r inv; do
  [ -n "$inv" ] || continue
  a="$(git_args "$inv" clean)"
  short_flag "$a" f e || printf ' %s ' "$a" | grep -qE '[[:space:]]--force[[:space:]]' || continue
  short_flag "$a" n e || printf ' %s ' "$a" | grep -qE '[[:space:]]--dry-run[[:space:]]' && continue
  block "git clean -f permanently deletes untracked files — they are not in git, so they cannot be restored" "run git clean -n first to see the list, then delete only what you mean, yourself."
done < <(printf '%s' "$C" | grep -oE "${GITRE}clean${NOVA_SH_ARGS}" 2>/dev/null)

# ── downloads piped into a shell
if printf '%s' "$C" | grep -qiE '(^|[^[:alnum:]_-])(curl|wget|fetch|iwr|invoke-webrequest)([[:space:]]|$)'; then
  printf '%s' "$C" | grep -qE '\|[[:space:]]*(sudo[[:space:]]+(-[[:alnum:]-]+[[:space:]]+)*)?(env[[:space:]]+([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*)?(ba|z|da|k|fi|c|tc)?sh([[:space:]]|$|;)' \
    && block "pipes a download straight into a shell (runs unreviewed remote code)" "download the script, read it, then run it yourself."
  printf '%s' "$C" | grep -qE '(^|[[:space:];&|(])((ba|z|da|k)?sh|source|\.)[[:space:]]+(-[[:alnum:]]+[[:space:]]+)*<\([[:space:]]*(curl|wget)' \
    && block "runs a downloaded script through process substitution (unreviewed remote code)" "download the script, read it, then run it yourself."
  printf '%s' "$C" | grep -qE '(ba|z|da|k)?sh[[:space:]]+-c[[:space:]]+["'"'"']?\$\([[:space:]]*(curl|wget)' \
    && block "runs a downloaded script via sh -c \"\$(curl …)\" (unreviewed remote code)" "download the script, read it, then run it yourself."
fi

# ── shared machines: docker
DK='(^|[[:space:];&|(`])(sudo[[:space:]]+)?docker[[:space:]]+'
printf '%s ' "$C" | grep -qE "${DK}system[[:space:]]+prune[^;&|]*[[:space:]](-a|--all|--volumes)[[:space:]]" \
  && block "docker system prune -a/--volumes removes every unused image, container and volume on this machine — including other users'" "remove only your own containers/images by name."
printf '%s' "$C" | grep -qE "${DK}volume[[:space:]]+prune" \
  && block "docker volume prune deletes all unused volumes (datasets, databases, model caches) on this machine" "remove a specific volume by name."
printf '%s ' "$C" | grep -qE "${DK}image[[:space:]]+prune[^;&|]*[[:space:]](-a|--all)[[:space:]]" \
  && block "docker image prune -a deletes every image not in use — other users must download them again" "remove a specific image by name."
printf '%s' "$C" | grep -qE "${DK}(rm|rmi|container[[:space:]]+rm|image[[:space:]]+rm|volume[[:space:]]+rm)[[:space:]][^;&|]*\\\$\([[:space:]]*(sudo[[:space:]]+)?docker" \
  && block "mass-removes Docker containers/images/volumes selected by \$(docker …)" "remove specific items by name."
printf '%s' "$C" | grep -qE "${DK}system[[:space:]]+prune" && warn "docker system prune removes stopped containers and dangling images for every user of this machine"

# ── shared machines: power, kill-all, disks, permissions (first word of each command segment)
while IFS= read -r seg; do
  seg="$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//')"
  while :; do
    case "$seg" in
      sudo\ *|nohup\ *|time\ *|exec\ *|command\ *|builtin\ *) seg="${seg#* }"; seg="$(printf '%s' "$seg" | sed -E 's/^(-[[:alnum:]-]+[[:space:]]+)*//')" ;;
      env\ *) seg="${seg#env }" ;;
      [A-Za-z_]*=*\ *) case "${seg%% *}" in *=*) seg="${seg#* }" ;; *) break ;; esac ;;
      *) break ;;
    esac
  done
  w1="${seg%% *}"; rest="${seg#"$w1"}"; rest="$(printf '%s' "$rest" | sed -E 's/^[[:space:]]+//')"; w2="${rest%% *}"
  case "$w1" in
    shutdown|reboot|poweroff|halt) block "$w1 — powers off/restarts the machine (ends every user's work)" ;;
    systemctl) case "$w2" in poweroff|reboot|halt|kexec|suspend|hibernate|hybrid-sleep) block "systemctl $w2 — powers off/restarts the machine" ;; esac ;;
    init|telinit) case "$w2" in 0|6) block "$w1 $w2 — halts/reboots the machine" ;; esac ;;
    kill) printf '%s ' "$seg" | grep -qE '^kill[[:space:]]+(-9|-KILL|-SIGKILL|-s[[:space:]]+(9|KILL)|--)[[:space:]]+-1[[:space:]]' && block "kill … -1 kills every process you own (all your sessions, notebooks and jobs)" ;;
    mkfs|mkfs.*|wipefs) block "$w1 — erases a disk / partition" ;;
    dd) printf '%s' "$seg" | grep -qE 'of=/dev/(sd|hd|nvme|disk|rdisk|mmcblk|vd|xvd|loop|md)' && block "dd onto a disk device overwrites the disk" ;;
    chmod) if printf '%s ' "$seg" | grep -qE '[[:space:]](-[a-zA-Z]*R[a-zA-Z]*|--recursive)[[:space:]]' && printf '%s ' "$seg" | grep -qE '[[:space:]](0?777|a\+rwx|ugo\+rwx|a=rwx)[[:space:]]'; then
             block "chmod -R 777 makes the files writable by every user (on a shared machine, anyone can change or copy them)" "give only the access needed, e.g. chmod -R u+rwX,go-w <dir>"
           fi ;;
  esac
done < <(printf '%s\n' "$C" | awk '{gsub(/&&|\|\||;|\||&|\(|\)|`/, "\n"); print}')

# ── warn tier (legitimate on a dev database, catastrophic on production)
case "$C" in
  *migrate:fresh*|*migrate:reset*|*migrate:rollback*|*db:wipe*|*"prisma migrate reset"*|*"sequelize db:drop"*|*"rails db:drop"*|*"rake db:drop"*)
    warn "this wipes database data — fine on a dev database, make sure this is not production (back up first if unsure)" ;;
esac

if [ -n "$WARNINGS" ]; then
  nova_log dangerous-command-gate.log "WARN $WARNINGS"
  nova_user_msg "⚠️ NOVA: $WARNINGS"
fi
exit 0
