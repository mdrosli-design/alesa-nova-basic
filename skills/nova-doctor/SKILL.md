---
name: nova-doctor
description: "Check that ALESA NOVA Basic is installed and working on this machine — versions, guard modes, hook health, recent guard events — run a self-test that proves the guards block here, and produce a support report that is safe to send for remote help (no file contents, no secrets). Use when the user asks whether the guards work, wants support, or after installing on a new machine. BM: semak alesa, berfungsi ke, laporan sokongan."
argument-hint: "[--save]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/alesa-doctor.sh *)
---

# nova-doctor — health check and support report

1. Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/alesa-doctor.sh --selftest $ARGUMENTS`
2. Explain the result briefly: anything marked ✗ or failed, what it means and how to fix it. If everything
   passes, say so in one line (e.g. "8/8 hooks healthy, self-test 27/27 passed").
3. If the user needs remote help: they can send this report to hello@alesa.my — it contains versions,
   settings and masked guard events only. `/nova-doctor --save` writes it to a file.
4. If an update is available or needed, show the update commands from the report.

Reply in the user's language.
