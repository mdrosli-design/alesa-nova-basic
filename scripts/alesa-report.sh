#!/usr/bin/env bash
# alesa-report.sh — AI-use report from the local activity log (/nova-report).
# Usage: alesa-report.sh [--days N | --since YYYY-MM-DD] [--project DIR | --all]
#   default: today, current project (git root of the current folder)
# Prints Markdown: what the AI agent did through its tools (files changed, commands, checks run, guard
# events, backups) plus a disclosure statement to edit — e.g. for coursework that requires declaring AI use.
# Honest limit: the log lives in the user's own account; it records the agent's tool calls, not text pasted
# elsewhere, and it is editable — a disclosure aid, not tamper-proof evidence.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../hooks/_lib.sh" || exit 1
nova_has_python || { echo "alesa-report needs python3."; exit 1; }
DAYS=1; SINCE=""; PROJECT=""; ALL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --days) DAYS="${2:-1}"; shift ;;
    --since) SINCE="${2:-}"; shift ;;
    --project) PROJECT="${2:-}"; shift ;;
    --all) ALL=1 ;;
  esac
  shift
done
[ -n "$PROJECT" ] || PROJECT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
NOVA_LANG_SEL="$(nova_lang)" NOVA_V="${NOVA_VERSION:-}" python3 - "$NOVA_HOME" "$DAYS" "$SINCE" "$PROJECT" "$ALL" <<'PY'
import collections, datetime as dt, glob, json, os, re, sys
home, days, since, project, allp = sys.argv[1:6]
ms = os.environ.get("NOVA_LANG_SEL") == "ms"
today = dt.date.today()
start = dt.date.fromisoformat(since) if since else today - dt.timedelta(days=max(int(days or 1), 1) - 1)
project = os.path.realpath(project)

recs = []
for f in sorted(glob.glob(os.path.join(home, "activity", "*.jsonl"))):
    try:
        day = dt.date.fromisoformat(os.path.basename(f)[:10])
    except ValueError:
        continue
    if day < start:
        continue
    for ln in open(f, encoding="utf-8", errors="replace"):
        try:
            r = json.loads(ln)
        except Exception:
            continue
        cwd = os.path.realpath(r.get("cwd") or "/")
        if not allp and not (cwd == project or cwd.startswith(project + os.sep)):
            continue
        recs.append(r)

def rel(p):
    if not p:
        return p
    rp = os.path.realpath(p) if os.path.isabs(p) else p
    return os.path.relpath(rp, project) if os.path.isabs(rp) and rp.startswith(project) else p

TEST = re.compile(r"(pytest|unittest|jest|vitest|mocha|go test|cargo test|phpunit|pest|rspec|npm (run )?test|yarn test|pnpm test|playwright|cypress|curl |python3? \S+\.py|node \S+)", re.I)
sessions = {r.get("session") for r in recs if r.get("session")}
tools = collections.Counter(r.get("tool", "") for r in recs)
changed = collections.Counter(rel(r["target"]) for r in recs if r.get("tool") in ("Edit", "Write", "MultiEdit", "NotebookEdit") and r.get("target"))
cmds = [r["target"] for r in recs if r.get("tool") == "Bash" and r.get("target")]
checks = [c for c in cmds if TEST.search(c)]
web = [r["target"] for r in recs if r.get("tool") in ("WebFetch", "WebSearch") and r.get("target")]

def log_events(name):
    n = 0
    for ln in open(os.path.join(home, name), encoding="utf-8", errors="replace") if os.path.exists(os.path.join(home, name)) else []:
        try:
            d = dt.date.fromisoformat(ln[:10])
        except ValueError:
            continue
        if d >= start and " BLOCK" in ln:
            n += 1
    return n
guards = {g: log_events(f) for g, f in (("secret-leak", "secret-leak-gate.log"), ("dangerous-command", "dangerous-command-gate.log"),
                                         ("insecure-default", "insecure-default-gate.log"), ("verify-before-done", "verify-before-done.log"))}
backups = 0
bl = os.path.join(home, "pre-edit-backup.log")
if os.path.exists(bl):
    for ln in open(bl, encoding="utf-8", errors="replace"):
        try:
            if dt.date.fromisoformat(ln[:10]) >= start and " BACKUP " in ln:
                backups += 1
        except ValueError:
            pass

period = start.isoformat() if start == today else "%s → %s" % (start.isoformat(), today.isoformat())
scope = ("semua projek" if ms else "all projects") if allp else project
L = (lambda en, my: my if ms else en)
print("# " + L("AI-use report", "Laporan penggunaan AI"))
print()
print("- " + L("Project", "Projek") + ": `%s`" % scope)
print("- " + L("Period", "Tempoh") + ": %s" % period)
print("- " + L("Tool", "Alat") + ": Claude Code + ALESA NOVA Basic %s" % os.environ.get("NOVA_V", ""))
print("- " + L("Generated", "Dijana") + ": %s" % dt.datetime.now().strftime("%Y-%m-%d %H:%M"))
print()
print("## " + L("Summary", "Ringkasan"))
print("| %s | %s |" % (L("Item", "Perkara"), L("Count", "Bilangan")))
print("|---|---|")
for k, v in ((L("AI sessions", "Sesi AI"), len(sessions)), (L("Tool calls", "Panggilan alat"), len(recs)),
             (L("Files changed by the AI", "Fail diubah oleh AI"), len(changed)), (L("Commands run", "Arahan dijalankan"), len(cmds)),
             (L("Checks run (tests / runs / requests)", "Semakan dijalankan (ujian / larian / permintaan)"), len(checks)),
             (L("Web lookups", "Carian web"), len(web)), (L("Automatic backups", "Backup automatik"), backups)):
    print("| %s | %s |" % (k, v))
print()
if changed:
    print("## " + L("Files changed by the AI", "Fail yang diubah oleh AI"))
    for f, n in changed.most_common(40):
        print("- `%s` (%d×)" % (f, n))
    print()
if checks:
    print("## " + L("Checks the AI ran", "Semakan yang dijalankan oleh AI"))
    for c in checks[-10:]:
        print("- `%s`" % c[:160])
    print()
if cmds:
    print("## " + L("Commands (most recent 15)", "Arahan (15 terkini)"))
    for c in cmds[-15:]:
        print("- `%s`" % c[:160])
    print()
print("## " + L("Guardrail events", "Peristiwa pagar keselamatan"))
print(", ".join("%s: %d" % (g, n) for g, n in guards.items()) + L(" (blocked actions in this period, all projects)", " (tindakan disekat dalam tempoh ini, semua projek)"))
print()
print("## " + L("Disclosure statement (edit before submitting)", "Pernyataan pendedahan (sunting sebelum menghantar)"))
print(L(
    "> I used an AI coding assistant (Claude Code with ALESA NOVA Basic guardrails) for this work. "
    "It helped with: <describe>. I reviewed, ran and tested the results myself, and I understand the code I am submitting. "
    "The activity summary above was generated from the local log on my machine.",
    "> Saya menggunakan pembantu pengekodan AI (Claude Code dengan pagar ALESA NOVA Basic) untuk kerja ini. "
    "Ia membantu dalam: <terangkan>. Saya telah menyemak, menjalankan dan menguji hasilnya sendiri, dan saya memahami kod yang saya hantar. "
    "Ringkasan aktiviti di atas dijana daripada log setempat di mesin saya."))
print()
print("_" + L(
    "Limits: generated from the local activity log in the user's own account. It shows what the AI agent did through its tools — not text typed or pasted elsewhere — and it can be edited, so it is a disclosure aid, not tamper-proof evidence.",
    "Had: dijana daripada log aktiviti setempat dalam akaun pengguna sendiri. Ia menunjukkan apa yang dilakukan agen AI melalui alatnya — bukan teks yang ditaip atau ditampal di tempat lain — dan boleh disunting, jadi ia alat bantu pendedahan, bukan bukti kalis-ubah.") + "_")
PY
