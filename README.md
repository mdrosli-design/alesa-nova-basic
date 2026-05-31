# ALESA NOVA — Marketplace (free)

**Disciplined AI coding for solo builders. Vibe code without the disasters.**

This marketplace hosts **ALESA NOVA Basic** — a free Claude Code plugin that adds *mechanical*
guardrails to your AI coding agent: hooks that **act** at the moment of risk (block or back up),
not best-effort reminders. It's the answer to the real failure modes of fast AI coding — leaked
secrets, insecure defaults, overwritten work, and "done" claims that were never verified.

## What ALESA NOVA Basic gives you

| Guard | What it does | Disaster it prevents |
|-------|--------------|----------------------|
| **secret-leak gate** | Blocks a real API key / token / DB password / private key from entering a client-exposed file or a commit. | Pushing an API key to a public repo. |
| **insecure-default gate** | Blocks RLS-off, TLS-verify-off, wildcard CORS + credentials, `DEBUG` in a prod env. | Wide-open databases & security holes. |
| **backup-before-edit** | Auto-saves `<file>.bak.auto` before the agent edits an existing file. | "The AI overwrote my working code." |
| **change-annotation** | Nudges a `// [CHANGE] what · why · verify` note on code edits. | Code nobody can understand later. |

Plus a working method (3 Laws · evidence-based "done" · untrusted-until-proven) and two skills —
`/nova-verify` (systematic verification + evidence table) and `/nova-brainstorm` (design-before-build).

## Install

```
/plugin marketplace add mdrosli-design/alesa-nova-marketplace
/plugin install alesa-nova-basic@alesa-nova
```
Restart Claude Code, then run `/nova-basic` to see what's active.

The two security gates **block by default**. Flip to warn-only while you learn:
`NOVA_SECRET_GATE_MODE=warn` · `NOVA_INSECURE_GATE_MODE=warn`.

## Editions

**Basic** (this — free, solo) → **Compliance** (licensed: Malaysian PDPA · ISO/IEC 27001 · MAMPU
alignment + security/audit suite) → team/agency multi-tenant + real-time supervision.

Licensing & higher editions: **hello@alesa.my** · **https://alesa.my**

---
© ALESA IT Services. Basic is free for individual use — see the plugin's LICENSE.txt.
