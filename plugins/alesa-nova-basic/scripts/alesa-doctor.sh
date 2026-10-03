#!/usr/bin/env bash
# alesa-doctor.sh — health check + support report for ALESA NOVA Basic (/nova-doctor).
# Usage: alesa-doctor.sh [--selftest] [--save]
#   --selftest  run the quick gate self-test on THIS machine (proves the guards actually block here)
#   --save      also write the report to ~/.nova-basic/support-report-<time>.txt
# The report holds versions, settings and recent guard events (already masked) — never file contents,
# never secrets — so it is safe to send to support for remote help.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../hooks/_lib.sh" || exit 1
tilde() { case "$1" in "$HOME"*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
onoff() { [ "$(nova_mode "$1" on)" = off ] && echo off || echo on; }
SELF=""; SAVE=""
for a in "$@"; do case "$a" in --selftest|selftest) SELF=1 ;; --save|save) SAVE=1 ;; esac; done

report() {
  local ok=0 total=0 h py jqv cc ms
  echo "ALESA NOVA Basic — doctor · $(date '+%Y-%m-%d %H:%M %Z')"
  echo "Version      : ${NOVA_VERSION:-?}   (plugin: $(tilde "$NOVA_ROOT"))"
  py="$(nova_has_python && python3 -c 'import platform; print(platform.python_version())' 2>/dev/null || echo none)"
  jqv="$(jq --version 2>/dev/null || echo none)"
  echo "System       : $(uname -sm) · bash ${BASH_VERSION%%(*} · python3 $py · jq $jqv · git $(git --version 2>/dev/null | awk '{print $3}')"
  cc="$(claude --version 2>/dev/null | head -1)"; echo "Claude Code  : ${cc:-not on PATH}"
  echo "Language     : $(nova_lang)   (NOVA_LANG=${NOVA_LANG:-unset}, LANG=${LANG:-unset})"
  echo "Gate modes   : secret=$(nova_mode NOVA_SECRET_GATE_MODE enforce) danger=$(nova_mode NOVA_DANGER_GATE_MODE enforce) insecure=$(nova_mode NOVA_INSECURE_GATE_MODE enforce) done=$(nova_mode NOVA_DONE_GATE_MODE enforce) backup=$(nova_mode NOVA_BACKUP_MODE warn) annotation=$(onoff NOVA_ANNOTATION_MODE) activity-log=$(onoff NOVA_ACTIVITY_LOG) session-context=$(onoff NOVA_SESSION_CONTEXT)"
  for f in /etc/claude-code/managed-settings.json "/Library/Application Support/ClaudeCode/managed-settings.json"; do
    [ -f "$f" ] || continue
    if grep -q '"alesa-nova-basic@alesa-nova"' "$f" 2>/dev/null; then ms="$f (enables alesa-nova-basic@alesa-nova for every user)"; else ms="$f (does not enable alesa-nova-basic@alesa-nova)"; fi
  done
  echo "Managed setup: ${ms:-none (per-user install)}"
  for h in session-start pre-edit-auto-backup secret-leak-gate insecure-default-gate dangerous-command-gate change-annotation-gate activity-log verify-before-done-gate; do
    total=$((total + 1))
    if [ -x "$NOVA_ROOT/hooks/$h.sh" ] && bash -n "$NOVA_ROOT/hooks/$h.sh" 2>/dev/null; then ok=$((ok + 1)); else echo "  ✗ hook problem: $h.sh (missing, not executable, or syntax error)"; fi
  done
  echo "Hooks        : $ok/$total present, executable, syntax OK"
  if nova_has_python; then echo "Done gate    : active (python3 reads the session transcript)"; else echo "Done gate    : INACTIVE — needs python3 to read the session transcript (all other guards work without it)"; fi
  local nb nl sz
  nb="$(find "$NOVA_HOME/backups" -type f 2>/dev/null | wc -l | tr -d ' ')"
  nl="$(find "$NOVA_HOME/activity" -name '*.jsonl' 2>/dev/null | wc -l | tr -d ' ')"
  sz="$(du -sh "$NOVA_HOME" 2>/dev/null | cut -f1)"
  echo "Data folder  : $(tilde "$NOVA_HOME") ($sz) · $nb backups · $nl days of activity log"
  echo "Recent guard events (newest last, samples masked):"
  local ev; ev="$(cat "$NOVA_HOME"/secret-leak-gate.log "$NOVA_HOME"/dangerous-command-gate.log "$NOVA_HOME"/insecure-default-gate.log "$NOVA_HOME"/verify-before-done.log 2>/dev/null | sort | tail -8)"
  if [ -n "$ev" ]; then printf '%s\n' "$ev" | cut -c1-180 | sed 's/^/  /'; else echo "  (none)"; fi
  if [ -n "$SELF" ]; then
    echo "Self-test    :"
    if command -v python3 >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
      bash "$NOVA_ROOT/tests/run-tests.sh" --quick 2>&1 | sed 's/^/  /'
    else
      echo "  skipped — needs python3 and git to build test inputs (the guards themselves do not need them)"
    fi
  fi
  cat <<EOF
Update       : online   →  claude plugin marketplace update alesa-nova && claude plugin update alesa-nova-basic@alesa-nova
               offline  →  refresh the lab mirror folder/git copy, then run the same two commands
               automatic → set "autoUpdate": true on the alesa-nova marketplace (see docs/LAB-DEPLOYMENT.md)
Support      : send this report to hello@alesa.my — it contains no file contents and no secrets.
EOF
}

if [ -n "$SAVE" ]; then
  out="$NOVA_HOME/support-report-$(date +%Y%m%d-%H%M%S).txt"
  report | tee "$out"
  echo "Saved: $(tilde "$out")"
else
  report
fi
