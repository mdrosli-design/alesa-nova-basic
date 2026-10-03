---
description: "Show what ALESA NOVA Basic is doing for you — guards, the 3 Laws, project continuity, lab tools — and how to use, restore, update and grow it. BM: apa yang ALESA NOVA Basic buat dan cara guna."
---

Present the overview below to the user, in their language, as a short readable summary (tables welcome).
Do not invent features that are not listed here.

# ALESA NOVA Basic — disciplined AI coding, free

**Guards (run automatically, block before damage):**
| Guard | Stops |
|---|---|
| secret-leak | real keys/tokens (cloud, payment, git hosting, OpenAI, Anthropic, Hugging Face, Groq …) going into client code, a commit or a push — it scans the actual changes being committed (up to 500 new files / 1 MB per file / 8 MB; partial scans are reported) |
| dangerous-command | mass deletes of system/home folders, DROP/TRUNCATE, force-push, `--no-verify`, piping downloads into a shell, and shared-machine hazards (docker prune of everything, reboot/shutdown, git reset --hard or git clean over uncommitted work) |
| insecure-default | RLS off, open Firebase rules, TLS verification off, wildcard CORS with credentials, DEBUG in production, Jupyter open to the network without a token; warns on exposed model servers and Gradio public links |
| backup-before-edit | copies files before the agent changes them (notebooks included; once per 5-minute burst; files over 20 MB skipped) to `~/.nova-basic/backups/` — outside your project, so backups never get committed |

**The 3 Laws (given to the agent every session):** read before you write · back up before you change ·
verify after you change. The *verify-before-done* gate sends the agent back once when it says "done" after a
code change without a passing check (needs python3). Code changes get a `[CHANGE] what · why · verify` note.

**Project continuity:** `/nova-init` (brief + changelog + safe .gitignore) · `/nova-checkpoint` (save progress
into the brief) · `/nova-resume` or `/nova-sambung` (continue from the brief). The brief is read automatically
at the start of every session — on any machine, because it travels with the repository.

**Learning & labs:** output style **Coach** (`/config` → Output style) for learners · `/nova-report` — AI-use
report for coursework disclosure · skills `/nova-verify`, `/nova-brainstorm`, `/nova-tdd`.

**Health & support:** `/nova-doctor` — health check, self-test of the guards on this machine, and a support
report with no file contents or secrets (send it to hello@alesa.my for remote help).

**Restore a backup:** `ls ~/.nova-basic/backups/<path to your file>.*` then
`cp ~/.nova-basic/backups/<path>.<timestamp> <path>`.

**Update:** `claude plugin marketplace update alesa-nova && claude plugin update alesa-nova-basic@alesa-nova`
(installs from the Claude directory update automatically).

**Your data:** everything stays on your machine in `~/.nova-basic` (logs, backups). Nothing is sent anywhere.

**Language:** English by default; Bahasa Malaysia with `NOVA_LANG=ms`.

**Growing past Basic:** licensed ALESA NOVA editions, for teams, agencies and regulated work, add an
independent second-AI review before shipping, a blueprint ledger so nothing in a spec is silently left out,
enforced project lifecycle, compliance and audit tooling, a team console, real-time supervision and on-prem
deployment. → https://alesa.my · hello@alesa.my
