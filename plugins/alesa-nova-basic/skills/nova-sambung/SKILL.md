---
name: nova-sambung
description: "Bahasa Malaysia name for /nova-resume — sambung projek dari brief (docs/RESUME-BRIEF.md): baca brief, semak git, teruskan dari langkah seterusnya."
disable-model-invocation: true
allowed-tools: Read Bash(git status *) Bash(git log *) Bash(git diff *)
---

# nova-sambung — sambung dari baton

Same steps as `/nova-resume`:

1. Read `docs/RESUME-BRIEF.md` in full (missing → say so, suggest `/nova-init`, continue from git history).
   Read the newest entries of `CHANGELOG.md` if it exists.
2. Check the real state: `git log --oneline -10` and `git status --short --branch`.
3. When the brief disagrees with git, git is right — tell the user and correct the brief.
4. Summarise in at most five lines: where things stand, what changed last, what remains, the next step.
5. Continue with the brief's next step (*Langkah seterusnya* / *Next step*) unless the user asks otherwise,
   following the 3 Laws: read before you write · back up before you change · verify before "done".

Reply in the user's language (Bahasa Malaysia if they write in it).
