---
name: nova-init
description: "Set up project continuity: a resume brief (docs/RESUME-BRIEF.md) that every new session reads first, a CHANGELOG, git if missing, and .gitignore lines that keep secrets out of git. Never overwrites existing files. Use when starting or adopting a project. BM: sediakan projek, mulakan projek, init projek."
disable-model-invocation: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/alesa-init.sh *) Read Edit(./docs/RESUME-BRIEF.md)
---

# nova-init — give the project a memory

1. Run the setup script (it creates only what is missing and never overwrites):

   `bash ${CLAUDE_PLUGIN_ROOT}/scripts/alesa-init.sh .`

2. Show the user what was created (`+`) and what was already there (`=`), as a short list.
3. If `docs/RESUME-BRIEF.md` was just created, fill in its **Project** section from what you can verify in
   the repository — what it is, how to run it, how to test it — by reading the README, package or
   requirements files and the entry points. Write only what you checked; leave `(fill in)` where unsure.
   Do not change the other sections.
4. Tell the user, in one or two lines: the brief is read automatically at the start of every session;
   `/nova-checkpoint` saves progress into it; `/nova-resume` (or `/nova-sambung`) continues from it.

Reply in the user's language.
