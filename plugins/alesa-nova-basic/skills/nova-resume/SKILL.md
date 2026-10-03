---
name: nova-resume
description: "Continue a project where the last session stopped: read the project brief, recent commits and changelog, reconcile them with git, and pick up the next step. Use when the user says resume, continue, carry on, pick up where we left off. BM: sambung, teruskan, sambung projek."
allowed-tools: Read Bash(git status *) Bash(git log *) Bash(git diff *)
---

# nova-resume — continue from the baton

1. Read `docs/RESUME-BRIEF.md` in full. If it is missing, say so, suggest `/nova-init`, and continue from git
   history only. Read the newest entries of `CHANGELOG.md` if it exists.
2. Check the real state: `git log --oneline -10` and `git status --short --branch`.
3. Reconcile: when the brief disagrees with git (for example, work listed as remaining is already
   committed), git is right — tell the user and correct the brief.
4. Summarise in at most five lines: where things stand, what changed last, what remains, the next step.
5. Continue with the brief's **Next step** unless the user asks for something else. Follow the 3 Laws:
   read before you write · back up before you change (automatic) · verify before you call anything done.

Reply in the user's language.
