#!/usr/bin/env bash
# verify-before-done-gate.sh — Stop · ALESA NOVA Basic
#
# Law 3 — verify after you change. When the agent finishes a turn by saying the work is done/fixed/working
# (English or Bahasa Malaysia), after changing code, but ran nothing that exercises the code since its last
# change, this gate sends it back ONCE (exit 2) to run a real check — or to say plainly what is not verified.
#   Counts as a check: test runners (pytest, jest, vitest, go test, cargo test, phpunit …), running the
#   program (python app.py, node x.js, ./script, npm start/dev/test), requests (curl, wget, httpie), docker
#   run/compose up, notebook execution, browser automation tools.
#   Does NOT count: lint/format/type-check/compile only (eslint, ruff, flake8, tsc --noEmit, php -l, bash -n …).
#   A check whose result was an error (e.g. "Exit code 1") does not count either.
#   Honest disclosure passes: "not verified", "untested", "could not run the tests", "belum diuji" …
# Never loops: if Claude is already continuing because of a Stop hook, or this exact final message was already
# sent back once, the turn is allowed to end.
# Needs python3 to read the transcript; without it the gate stays silent (all other gates still work).
#
# Mode: NOVA_DONE_GATE_MODE = enforce (default) | warn (tell you, don't send back) | off.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh" || exit 0
MODE="$(nova_mode NOVA_DONE_GATE_MODE enforce)"
[ "$MODE" = off ] && exit 0
nova_read_input; nova_parse
[ "$NOVA_STOP_ACTIVE" = 1 ] && exit 0
[ -n "$NOVA_TRANSCRIPT" ] && [ -f "$NOVA_TRANSCRIPT" ] || exit 0
nova_has_python || exit 0
mkdir -p "$NOVA_HOME/state" 2>/dev/null

VERDICT="$(python3 - "$NOVA_TRANSCRIPT" <<'PY' 2>/dev/null
import hashlib, json, os, re, sys
path = sys.argv[1]
size = os.path.getsize(path)
with open(path, "rb") as f:
    if size > 6_000_000:
        f.seek(size - 6_000_000); f.readline()
    raw = f.read().decode("utf-8", "replace").splitlines()
entries = []
for ln in raw:
    try:
        e = json.loads(ln)
    except Exception:
        continue
    if isinstance(e, dict) and not e.get("isSidechain"):
        entries.append(e)

def content(e):
    c = (e.get("message") or {}).get("content")
    return c if isinstance(c, (list, str)) else []

start = 0
for i in range(len(entries) - 1, -1, -1):
    e = entries[i]
    if e.get("type") != "user" or e.get("isMeta"):
        continue
    c = content(e)
    if isinstance(c, str):
        if c.strip():
            start = i; break
        continue
    kinds = {p.get("type") for p in c if isinstance(p, dict)}
    if "text" in kinds and "tool_result" not in kinds:
        start = i; break

CODE = re.compile(r"\.(py|ipynb|js|jsx|ts|tsx|mjs|cjs|vue|svelte|php|rb|go|rs|java|kt|swift|c|cc|cpp|h|hpp|cs|scala|dart|lua|r|jl|sh|bash|sql)$", re.I)
LINT = re.compile(r"((make|npm|yarn|pnpm|bun)\s+(run\s+)?(lint|format|fmt|typecheck|type-check|tsc|check-types|vet|style)\b|eslint|flake8|ruff|pylint|pyflakes|mypy|black|isort|prettier|stylelint|shellcheck|tsc(\s+--noemit)?|php\s+-l|bash\s+-n|sh\s+-n|python3?\s+-m\s+(py_compile|compileall|black|flake8|ruff|pylint|mypy|isort|pyflakes))[^;&|]*", re.I)
VERIFY = re.compile(
    r"(^|[\s;&|(])("
    r"pytest|py\.test|unittest|nose2|tox|nox|jest|vitest|mocha|ava|karma|jasmine|playwright|cypress|"
    r"phpunit|pest|artisan\s+test|rspec|minitest|rake\s+test|go\s+(test|run)|cargo\s+(test|run|bench)|dotnet\s+(test|run)|"
    r"mvn\s+(test|verify)|gradlew?\s+(test|check|run)|ctest|make(\s+[\w.-]+)?(\s|$)|"
    r"(npm|pnpm|yarn|bun)\s+(run\s+)?(test|start|dev|e2e|serve)|bun\s+test|deno\s+(test|run)|"
    r"python3?\s+(-m\s+[\w.]+|[^\s;&|]+\.py)|node\s+[^\s;&|]+|ts-node|tsx\s+[^\s;&|]+|ruby\s+[^\s;&|]+|php\s+[^\s;&|-][^\s;&|]*|java\s+|"
    r"curl|wget|http\s|httpie|xh\s|"
    r"(bash|sh|zsh)\s+[^\s;&|-][^\s;&|]*|\./[^\s;&|]+|"
    r"docker\s+(run|compose\s+up|exec)|jupyter\s+(nbconvert|execute)|papermill|rscript\s|julia\s"
    r")", re.I)
BROWSER = re.compile(r"playwright|puppeteer|browser|chrome|selenium", re.I)
DONE = re.compile(
    r"\b(done|fixed|works|working now|is working|completed?|finished|deployed|resolved|implemented|shipped|"
    r"all (the )?tests? pass(ing|ed)?|tests? (now )?pass(es|ed)?|ready to (use|go|ship|merge))\b|✅|"
    r"\b(siap|selesai|berjaya|beres|sudah (dibaiki|diperbaiki|berfungsi|siap)|dah (siap|ok|okay|baiki|berfungsi))\b", re.I)
HONEST = re.compile(
    r"(not (yet )?(been )?(verified|tested|run)|untested|unverified|without (running|testing)|"
    r"haven'?t (run|tested|verified)|have not (run|tested|verified)|could ?n'?t (run|test|verify)|cannot (run|test|verify)|"
    r"unable to (run|test|verify)|no tests? (exist|available|were run)|did ?n[o']?t (run|test|verify)|did not (run|test|verify)|"
    r"belum (diuji|disahkan|dijalankan|disemak)|tidak (diuji|dijalankan)|tidak (dapat|boleh) (menguji|mengesahkan|menjalankan)|tanpa (menguji|menjalankan))", re.I)

events = []
errors = set()   # tool_use ids whose result was an error (e.g. "Exit code 1")
for e in entries[start + 1:]:
    if e.get("type") == "user" and isinstance(content(e), list):
        for p in content(e):
            if isinstance(p, dict) and p.get("type") == "tool_result" and p.get("is_error"):
                errors.add(p.get("tool_use_id"))
        continue
    if e.get("type") != "assistant":
        continue
    for p in content(e) if isinstance(content(e), list) else []:
        if not isinstance(p, dict):
            continue
        if p.get("type") == "text":
            events.append(("text", p.get("text") or "", None))
        elif p.get("type") == "tool_use":
            name = p.get("name") or ""
            inp = p.get("input") if isinstance(p.get("input"), dict) else {}
            if name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
                fp = inp.get("file_path") or inp.get("notebook_path") or ""
                events.append(("edit" if CODE.search(fp) else "doc", fp, p.get("id")))
            elif name == "Bash":
                events.append(("bash", inp.get("command") or "", p.get("id")))
            else:
                events.append(("tool", name, p.get("id")))

last_edit = max((i for i, ev in enumerate(events) if ev[0] == "edit"), default=-1)
if last_edit < 0:
    print("ALLOW"); sys.exit()
verified = False
for kind, val, tid in events[last_edit + 1:]:
    if tid in errors:
        continue            # a check that failed is not proof
    if kind == "bash" and VERIFY.search(LINT.sub(" ", val)):
        verified = True; break
    if kind == "tool" and BROWSER.search(val):
        verified = True; break
last_tool = max((i for i, ev in enumerate(events) if ev[0] != "text"), default=-1)
final = "\n".join(v for k, v, _ in events[last_tool + 1:] if k == "text")[-1500:]
if verified or not final or not DONE.search(final) or HONEST.search(final):
    print("ALLOW"); sys.exit()
print("BLOCK\t%s\t%s" % (hashlib.sha1(final.encode("utf-8", "replace")).hexdigest(), events[last_edit][1]))
PY
)"

case "$VERDICT" in BLOCK*) : ;; *) exit 0 ;; esac
HASH="$(printf '%s' "$VERDICT" | cut -f2)"; FILE="$(printf '%s' "$VERDICT" | cut -f3)"
MARK="$NOVA_HOME/state/done-gate-${NOVA_SESSION:-nosession}"
[ "$(cat "$MARK" 2>/dev/null)" = "$HASH" ] && exit 0      # already sent back once for this exact message
printf '%s' "$HASH" > "$MARK" 2>/dev/null
nova_log verify-before-done.log "BLOCK session=${NOVA_SESSION:-?} last_edit=$FILE"

if [ "$MODE" = warn ]; then
  nova_user_msg "⚠️ NOVA: the agent said the work is done, but ran nothing after changing $FILE — ask it to show a real test or run."
  exit 0
fi
if [ "$(nova_lang)" = ms ]; then
  cat >&2 <<EOF
NOVA · SIAP MESTI ADA BUKTI: anda menyatakan kerja sudah siap, tetapi tiada apa-apa yang dijalankan sejak perubahan kod terakhir ($FILE). Lint atau kompil sahaja bukan pengesahan.
Sebelum tamat: jalankan ujian atau arahan yang berkaitan dan tunjukkan hasilnya — atau, jika tidak dapat dijalankan, nyatakan terus terang apa yang belum disahkan dan bagaimana pengguna boleh menyemaknya.
EOF
else
  cat >&2 <<EOF
NOVA · VERIFY BEFORE DONE: you said the work is done, but nothing was run since your last code change ($FILE). Lint or a compile alone is not verification.
Before finishing: run the relevant test or command and show its result — or, if you cannot run it, say plainly what is not verified and how the user can check it.
EOF
fi
exit 2
