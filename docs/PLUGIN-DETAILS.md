# ALESA NOVA Basic

**Disciplined AI coding — free. Vibe code without the disasters.**

AI coding agents are fast, and that speed is exactly how API keys leak, insecure defaults ship, working code
gets overwritten and "done ✅" turns out to be untested. ALESA NOVA Basic adds a thin layer of *mechanical*
discipline to Claude Code: hooks that act at the moment of risk — block, back up, or send the agent back —
plus a short working method and tools for continuity, learning and support. For developers, learners and
computer labs, on laptops and on-prem AI workstations. English and Bahasa Malaysia.

## What you get

| Module | What it does |
|---|---|
| **Secret-leak guard** | Blocks real credentials — cloud, payment, git hosting and AI-provider keys (OpenAI, Anthropic, Hugging Face, Groq, Replicate, OpenRouter, xAI, Perplexity, Google), bot tokens, DB URLs with passwords, private keys — from client-exposed code, public env vars, a commit or a push. It scans the actual changes being committed or pushed (up to 500 new files, 1 MB per file, 8 MB in total — you are told when a scan is partial). |
| **Dangerous-command guard** | Blocks mass deletes of system/home folders, DROP/TRUNCATE, force-push, `--no-verify`, piping a download into a shell, and shared-machine hazards: docker prune of everything, reboot/shutdown, `git reset --hard` / `git clean` over uncommitted work. |
| **Insecure-default guard** | Blocks RLS off, open Firebase rules, TLS verification off, wildcard CORS with credentials, DEBUG in production, Jupyter open to the network without a token. Warns on model servers exposed without a key and Gradio public links. |
| **Backup before edit** | Copies each file (notebooks included) before the agent changes it — once per 5-minute burst, files over 20 MB skipped — to `~/.nova-basic/backups/`, outside your project, so a backup can never be committed. |
| **3 Laws + verify-before-done** | The agent gets the working method every session (read before you write · back up · verify). If it says "done" after changing code without a passing check, it is sent back once to prove it (a failed run doesn't count; needs python3). |
| **Change notes** | Reminds the agent to leave `[CHANGE] what · why · verify` at each code change. |
| **Continuity** | `/nova-init` · `/nova-checkpoint` · `/nova-resume` (`/nova-sambung`): a project brief that every new session reads first — on any machine. |
| **Coach mode** | Output style *Coach* for learners: explains first, small steps, leaves the key part to you. |
| **AI-use report** | `/nova-report` summarises what the AI did, with a disclosure statement to edit — for coursework and client work. |
| **Doctor** | `/nova-doctor` checks the install, self-tests the guards on this machine and produces a support report without file contents or secrets. |

## Install

From the Claude directory, or in Claude Code:

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```

Restart Claude Code and run `/nova-doctor`. Computer labs and shared machines: see
[docs/LAB-DEPLOYMENT.md](LAB-DEPLOYMENT.md) (install once for every account, offline mirror,
automatic updates).

## What runs on your machine (transparency)

- **Hooks** — plain bash scripts in `hooks/`, run by Claude Code before/after the agent's tools, at session
  start and when the agent stops. They read the tool call Claude Code passes in, and may run `git` (to see the
  changes about to be committed), `python3` or `jq` (to parse JSON, when available), and standard Unix tools.
- **Files they write** — only under `~/.nova-basic/`: backups, guard logs (credential samples masked), a daily
  activity log (tool, file path, the first 300 characters of a command; never file contents; known secret
  formats redacted), and small state files. Backups are pruned after 14 days and activity logs after 90 days (configurable).
- **Skills** may run the bundled scripts in `scripts/` when you invoke them (`/nova-init`, `/nova-doctor`,
  `/nova-report`).
- **Network** — none. Nothing is sent or fetched by this plugin. See [PRIVACY.md](https://github.com/mdrosli-design/alesa-nova-basic/blob/main/PRIVACY.md).

## Settings (environment variables)

`NOVA_SECRET_GATE_MODE`, `NOVA_DANGER_GATE_MODE`, `NOVA_INSECURE_GATE_MODE`, `NOVA_DONE_GATE_MODE` =
`enforce` (default) · `warn` · `off` — `NOVA_BACKUP_MODE` = `warn` (default) · `enforce` · `off` —
`NOVA_ACTIVITY_LOG`, `NOVA_ANNOTATION_MODE`, `NOVA_SESSION_CONTEXT` = `on`/`off` — `NOVA_LANG=ms` for Bahasa
Malaysia — `NOVA_BACKUP_KEEP_DAYS` (14), `NOVA_LOG_KEEP_DAYS` (90), `NOVA_BACKUP_MAX_MB` (20). Set them in
Claude Code settings `"env"` (a lab admin can pin them for every account in managed settings).

## Honest limits

The guards stop the *agent's* tool calls, not commands you type yourself. Detection is pattern-based: it
catches the common, high-confidence cases, not every possible secret or mistake. Commands are read as text —
one disguised through variables, aliases, `eval`, a script or a config override is not seen. The verify-before-done gate
needs python3. The activity log is local and editable — a disclosure aid, not tamper-proof evidence. Basic
does not replace code review.

## Growing past Basic

Licensed ALESA NOVA editions, for teams, agencies and regulated work, add an independent second-AI review
before shipping, a blueprint ledger so nothing in a spec is silently left out, an enforced project lifecycle,
compliance and audit tooling, a team console, real-time supervision and on-prem deployment —
**https://alesa.my** · **hello@alesa.my**

---
© Novastack System Sdn. Bhd. · open source under the [Mozilla Public License 2.0](https://github.com/mdrosli-design/alesa-nova-basic/blob/main/LICENSE.txt) from version 1.3.0 · names and logo: [TRADEMARKS.md](https://github.com/mdrosli-design/alesa-nova-basic/blob/main/TRADEMARKS.md) · contributing: [CONTRIBUTING.md](https://github.com/mdrosli-design/alesa-nova-basic/blob/main/CONTRIBUTING.md).
