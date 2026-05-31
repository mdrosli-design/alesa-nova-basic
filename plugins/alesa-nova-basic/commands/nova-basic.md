---
description: "Show what ALESA NOVA Basic is protecting you from and how to use it."
---

# ALESA NOVA Basic

You have **ALESA NOVA Basic** active — disciplined AI coding for solo builders. Here's what's
running for you and how to work with it.

## Mechanical guardrails (run automatically)
- **secret-leak gate** — blocks a real API key / token / DB-password / private key from entering
  a client-exposed file or a commit. *(blocks by default)*
- **insecure-default gate** — blocks known-dangerous config: RLS disabled, TLS verify off,
  wildcard CORS + credentials, DEBUG on in prod. *(blocks by default)*
- **backup-before-edit** — auto-saves a `.bak.auto` copy before any existing file is modified.
- **change-annotation** — nudges a `// [CHANGE] what · why · verify` remark on code edits.

To switch a gate to warn-only while learning:
`export NOVA_SECRET_GATE_MODE=warn` · `export NOVA_INSECURE_GATE_MODE=warn`

## The working method
1. **Read before you write** — understand the code first.
2. **Back up before you change** — handled by the hook.
3. **Verify after you change** — prove it works; lint is not verification. (use `/nova-verify`)
4. **Plan non-trivial work first** — design before the agent sprints. (use `/nova-brainstorm`)
5. **Evidence-based done** — no "done/fixed/deployed" without a probe behind it.

## Skills
- **`/nova-verify`** — systematic verification + evidence table before claiming done.
- **`/nova-brainstorm`** — design-before-build planning gate.

## Growing past Basic
Cross-model code review · Compliance (PDPA / ISO 27001) audit suite · team/agency multi-tenant ·
real-time drift supervision → **hello@alesa.my** · **https://alesa.my**
