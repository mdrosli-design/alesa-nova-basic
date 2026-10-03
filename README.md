# ALESA NOVA Basic

**Disciplined AI coding — free. Vibe code without the disasters.**

[Bahasa Malaysia](README.ms.md) · [Lab deployment](docs/LAB-DEPLOYMENT.md) · [Privacy](PRIVACY.md) · [Changelog](CHANGELOG.md)

AI coding agents are fast — and that speed is how API keys leak, insecure defaults ship, working code gets
overwritten and a "done ✅" turns out to be untested. **ALESA NOVA Basic** is a free Claude Code plugin that
adds *mechanical* discipline: hooks that **act** at the moment of risk — block, back up, or send the agent
back to prove its work — plus a short working method, project continuity, a learning mode and a self-testing
doctor. It runs entirely on your machine.

Built for **developers**, **learners and computer labs**, and **on-prem AI workstations** — anywhere an AI
agent can run commands and edit code. English and Bahasa Malaysia.

## What you get

| | Module | What it does |
|---|---|---|
| 🛡 | **Secret-leak guard** | Blocks real credentials — cloud, payment, git hosting and AI-provider keys (OpenAI, Anthropic, Hugging Face, Groq, Replicate, OpenRouter, xAI, Perplexity, Google) — from client code, public env vars, a commit or a push. Scans the actual changes being committed or pushed (up to 500 new files, 1 MB per file, 8 MB in total — you are told when a scan is partial). |
| 🛡 | **Dangerous-command guard** | Blocks mass deletes of system/home folders, DROP/TRUNCATE, force-push, `--no-verify`, `curl … \| bash`, and shared-machine hazards: docker prune of everything, reboot/shutdown, `git reset --hard` or `git clean` over uncommitted work. |
| 🛡 | **Insecure-default guard** | Blocks RLS off, open Firebase rules, TLS verification off, wildcard CORS with credentials, DEBUG in production, Jupyter on the network without a token. Warns on exposed model servers and Gradio public links. |
| 💾 | **Backup before edit** | Copies each file (notebooks included) before the agent edits it — once per 5-minute burst, files over 20 MB skipped — outside your project, so backups are never committed. |
| ⚖️ | **The 3 Laws** | Read before you write · back up before you change · verify after you change — given to the agent every session. A *verify-before-done* gate sends it back once when it claims "done" without a passing check (a failed run doesn't count; needs python3). |
| 🔁 | **Continuity** | `/nova-init`, `/nova-checkpoint`, `/nova-resume` (`/nova-sambung`): a project brief that every new session reads first, on any machine. |
| 🎓 | **Coach mode** | A learning output style: explains first, small steps, leaves the key part for you, checks understanding. |
| 📝 | **AI-use report** | `/nova-report` — what the AI did, plus a disclosure statement to edit, for coursework and client work. |
| 🩺 | **Doctor** | `/nova-doctor` — health check, a self-test proving the guards block on *this* machine, and a support report with no file contents or secrets. |

Every guard has a regression suite (`tests/run-tests.sh`, 226 checks) that runs on
macOS (bash 3.2 and 5) and Linux — Ubuntu and Debian, x86-64 and ARM64 (the base of Raspberry Pi OS 64-bit
and of ARM AI workstations) — in three modes: with python3, with jq only, and on a bare machine with neither,
because a security guard must never fail open.

## Install

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```

Restart Claude Code, then run `/nova-doctor`. Updates: `claude plugin update alesa-nova-basic@alesa-nova`,
or turn on automatic updates once: `/plugin` → **Marketplaces** → `alesa-nova` → **Enable auto-update**
(off by default for third-party marketplaces).

**Computer labs and shared machines** — install once for every account, pin the guard settings so they can't
be switched off per user, use an offline mirror, and keep it updated automatically:
[docs/LAB-DEPLOYMENT.md](docs/LAB-DEPLOYMENT.md).

## Commands

| Command | |
|---|---|
| `/nova-basic` | What is active and how to use it |
| `/nova-init` | Project brief + changelog + safe `.gitignore` (never overwrites) |
| `/nova-checkpoint [commit]` | Save progress into the brief (optionally a local commit) |
| `/nova-resume` · `/nova-sambung` | Continue from the brief |
| `/nova-verify` · `/nova-brainstorm` · `/nova-tdd` | Verification table · design before build · test first |
| `/nova-report` | AI-use report |
| `/nova-doctor [--save]` | Health check, self-test, support report |
| Output style **Coach** | `/config` → Output style |

(The full names are `/alesa-nova-basic:<command>`; the short form works when no other command uses it.)

## Transparency

Plain bash scripts, readable source, no network access. The hooks write only under `~/.nova-basic/` —
backups, guard logs with known secret formats masked, and a local activity log (tool, file path, command head;
never file contents). Details: [plugin details](docs/PLUGIN-DETAILS.md#what-runs-on-your-machine-transparency)
and [PRIVACY.md](PRIVACY.md).

**Honest limits:** the guards stop the agent's tool calls, not commands you type yourself; detection reads the
command text (common, high-confidence forms, including quoted paths and option clusters) — a command disguised
through variables, aliases, `eval`, a script or a config override is not seen; the done gate needs python3; the
activity log is local and editable; Basic does not replace code review.

## The ALESA NOVA framework

Basic is the free edition of **ALESA NOVA**, an engineering-discipline framework for AI coding agents built
on one idea: *evidence, not promises.* Licensed editions — for teams, agencies, institutions and regulated
work — add:

- an independent second-AI review of every significant change before it ships
- a blueprint ledger, so nothing in a specification is silently left out
- an enforced project lifecycle (brief, checkpoint, close) across a whole team
- compliance and audit tooling (data protection, ISO/IEC 27001 gap analysis)
- a team console, real-time supervision, and on-prem deployment

**https://alesa.my** · **hello@alesa.my**

---
© Novastack System Sdn. Bhd. · ALESA NOVA Basic is free for individual and internal use — see
[LICENSE.txt](LICENSE.txt).
