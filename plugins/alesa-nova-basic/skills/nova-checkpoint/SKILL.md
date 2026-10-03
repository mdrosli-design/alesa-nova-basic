---
name: nova-checkpoint
description: "Save progress into the project brief so the next session, person or machine continues cleanly: status, what was done with evidence, what remains, the next step, warnings. Add the argument 'commit' to also make a local git commit (never pushes). Use when the user says checkpoint, save progress, update the brief, or is about to stop. BM: simpan kemajuan, checkpoint, kemas kini brief, sebelum berhenti."
argument-hint: "[commit]"
allowed-tools: Read Edit Write Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git add *) Bash(git commit *)
---

# nova-checkpoint — hand the baton on

1. If `docs/RESUME-BRIEF.md` does not exist, stop and suggest `/nova-init`.
2. Look at the real state first: `git status --short --branch`, `git log --oneline -8`, and what you changed
   in this session.
3. Update `docs/RESUME-BRIEF.md`, keeping its headings (edit, don't rewrite history):
   - **Status** — one line on where the project stands, with today's date.
   - **Done** — this session's finished items at the top, each with its evidence: the test or command you
     actually ran and its result, or `file:line`. Never list evidence you did not produce in this session;
     mark unverified work as *unverified*.
   - **Remaining** — open items, including anything you found but did not do.
   - **Next step** — the single next action for whoever continues.
   - **Warnings & decisions** — anything the next person must know.
4. Add a `CHANGELOG.md` entry for today's changes: `date · file:line — what · why · verify`.
5. Only if the arguments contain `commit` ($ARGUMENTS): show `git status`, then commit the changes with the
   message `checkpoint: <one-line summary>`. Never push.
6. Report in three lines: what was saved, what remains, the next step.

Reply in the user's language.
