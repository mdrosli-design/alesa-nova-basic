---
name: nova-report
description: "Produce an AI-use report from the local activity log: what the AI agent did (files changed, commands, checks run, guard events, backups) plus a disclosure statement to edit — for coursework, research or client work that requires declaring AI assistance. Arguments: --days N, --since YYYY-MM-DD, --all. BM: laporan penggunaan AI, pendedahan AI, laporan tugasan."
argument-hint: "[--days N | --since YYYY-MM-DD] [--all]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/alesa-report.sh *) Edit(./AI-USE-REPORT.md)
---

# nova-report — declare AI use honestly

1. Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/alesa-report.sh --project . $ARGUMENTS`
2. Show the report to the user exactly as produced (it is Markdown). Do not add claims that are not in it.
3. Offer to save it as `AI-USE-REPORT.md` in the project.
4. Remind the user to complete the `<describe>` part of the disclosure statement themselves, and that the
   report reflects the agent's tool calls from a local, editable log — a disclosure aid, not proof.
5. For a Bahasa Malaysia report, the user can set `NOVA_LANG=ms`.

Reply in the user's language.
