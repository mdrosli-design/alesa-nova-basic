# Changelog — ALESA NOVA Basic

## 1.2.1 — 2026-10-03

### Fixed
- Hooks load their shared library from `${CLAUDE_PLUGIN_ROOT}/hooks/_lib.sh` (a literal plugin path, which Claude
  Code exports to plugin hooks) instead of a path computed at run time, and the hook scripts no longer name a
  parent-directory path. The Claude directory validator rejected both. Behaviour is unchanged.

## 1.2.0 — 2026-10-03

### Added
- **Project continuity**: `/nova-init` (project brief, changelog, git and secret-safe `.gitignore`; never
  overwrites), `/nova-checkpoint` (save progress into the brief, optional local commit), `/nova-resume` and
  `/nova-sambung` (continue from the brief). A session-start hook gives the agent the 3 Laws and, when a brief
  exists, its next step.
- **Verify-before-done gate** (Stop hook, needs python3): sends the agent back once when it claims done/fixed
  after changing code without a passing check since. Lint/compile and failed runs do not count; honest "not
  verified" passes; never loops.
- **Activity log + `/nova-report`**: private local log of the agent's tool calls (no file contents, known
  secret formats redacted) and an AI-use report with an editable disclosure statement.
- **`/nova-doctor`**: health check, on-machine self-test of the guards, support report safe to send.
- **Coach output style** for learners.
- **Shared-machine guards**: docker prune of everything / volume prune / mass rm, reboot/shutdown/poweroff,
  `kill -9 -1`, `git reset --hard` and `git checkout -- .` over uncommitted work, `git clean -f`.
- **AI-lab guards**: Jupyter open to the network without a token (blocked); model servers exposed without a
  key and Gradio public links (warned).
- **AI-provider keys** recognised: OpenAI (`sk-proj-`…), Anthropic, Hugging Face, Groq, Replicate, OpenRouter,
  xAI, Perplexity; Telegram bot tokens.
- **Bahasa Malaysia** messages and briefing with `NOVA_LANG=ms` (or an `ms_*` locale); English by default.
- Regression suite `tests/run-tests.sh` (226 checks; python3 / jq-only / bare-machine modes) and CI on
  Ubuntu x86-64, Ubuntu ARM64 and macOS.
- Lab deployment guide (`docs/LAB-DEPLOYMENT.md`, Bahasa Malaysia version), `PRIVACY.md`, directory listing
  metadata.

### Changed
- **Backups now go to `~/.nova-basic/backups/`**, outside the project — a backup of `.env` next to the file
  could slip past `.gitignore` and be pushed. Large files (> 20 MB) are skipped; backups are pruned after 14 days.
- **Commit/push secret scan now checks the actual changes** (tracked changes, new files, unpushed commits)
  instead of only web build folders — up to 500 new files, 1 MB per file and 8 MB in total (a first push scans
  the history newest-first up to that cap); a partial scan is reported. Placeholder checks look at the matched
  token, not the whole line.
- Dangerous-command matching parses arguments instead of matching substrings.
- Warn-mode messages are now shown to the user, and the change-annotation reminder now reaches the agent
  (plain stderr with exit 0 is not displayed by Claude Code).

### Fixed
- Notebook edits were never backed up and notebook content was never scanned for secrets (`notebook_path` /
  `new_source` were not read).
- False positives: `curl … | shasum`, `rm -rf /tmp/…`, `cat /var/run/reboot-required`, `dd … of=file.img`.
- Missed cases: `rm -Rf /`, `rm -r -f /`, `git push … -f` at the end of a command, `bash <(curl …)`,
  `sh -c "$(curl …)"`, OpenAI project keys and Anthropic keys.
- The change-annotation ledger needed `jq`, which macOS does not always have.
- Git global options before the subcommand (`git -c …`, `--no-pager`, `-C <dir>`) were not recognised by the
  secret and dangerous-command gates; an added line starting with `++ ` could hide a secret from the commit scan.
- Git commands are now read quote-aware: a quoted `-C "/path with spaces"`, git called as `/usr/bin/git`, a
  message containing `;` before `--no-verify`, `git commit -n` (short for `--no-verify`), `git push -fu`, a quoted
  `+refspec` and `git push&&…` were missed; `git commit -C HEAD` (reuse a message) was taken as a folder, which
  skipped the secret scan. `--no-verify` inside a commit message is no longer a false positive. With
  `--git-dir`/`--work-tree` the secret scan says it could not check instead of guessing the repository, and
  `reset --hard` / `checkout .` there are blocked because the working tree cannot be checked.
- The plugin README pointed to a marketplace that does not exist.

## 1.1.0 — 2026-09-24
- Works without `jq` (python3 first, raw fail-closed scan otherwise); dangerous-command gate.

## 1.0.0
- First public release: secret-leak and insecure-default gates, backup before edit, change annotation,
  `/nova-verify`, `/nova-brainstorm`, `/nova-tdd`.
