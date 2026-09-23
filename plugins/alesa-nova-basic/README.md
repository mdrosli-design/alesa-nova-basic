# ALESA NOVA Basic

**Disciplined AI coding for solo builders. Vibe code without the disasters.**

AI coding agents are fast — and that speed is how people leak API keys, ship insecure defaults,
overwrite working code, and trust a "done ✅" that was never verified. **ALESA NOVA Basic** adds a
thin layer of *mechanical* discipline to Claude Code: guardrails that **act** at the moment of
risk (block or back up) plus a short, sane working method. It's not a linter you have to remember
to run, and not a prompt the agent can quietly ignore — the hooks fire automatically.

## What it gives you

### 🛡 Mechanical guardrails (the difference)
| Guard | What it does | Disaster prevented |
|-------|--------------|--------------------|
| **secret-leak gate** | Blocks a real secret (AWS / Google / Stripe-live / GitHub token, DB URL w/ password, private key, JWT) from entering a client-exposed file (`NEXT_PUBLIC_`/`VITE_`/`REACT_APP_`) or a commit. | Pushing an API key to a public repo. |
| **insecure-default gate** | Blocks RLS-off, `USING(true)`, TLS-verify-off, wildcard CORS + credentials, `DEBUG` in a prod env. | Wide-open databases & security holes. |
| **backup-before-edit** | Saves `<file>.bak.auto.<ts>` before the agent edits an existing file. | "The AI overwrote my code." |
| **change-annotation** | Nudges a `// [CHANGE] what · why · verify` note on code edits + logs unannotated ones. | Code nobody can understand later. |

The two security gates **block (exit 2) by default**. Flip to warn-only any time:
`NOVA_SECRET_GATE_MODE=warn` · `NOVA_INSECURE_GATE_MODE=warn`.

### 🧭 A working method + 2 skills
- **3 Laws** — back up before you change · read before you write · verify after you change.
- **Evidence-based done** — no "done/fixed/deployed" without a probe. *Lint is not verification.*
- **`/nova-verify`** — systematic verification + evidence table.
- **`/nova-brainstorm`** — design-before-build planning gate.
- **`/nova-basic`** — show what's active and how to use it.

## Install
From the ALESA NOVA marketplace in Claude Code:
```
/plugin marketplace add alesa-it/alesa-nova-marketplace
/plugin install alesa-nova-basic
```
Then restart Claude Code. Run `/nova-basic` to see it working.

## Growing past Basic
Basic is complete for a solo developer — you upgrade by **need**, not because Basic is crippled:
- A second, independent AI reviewing your code before you ship → **cross-model review**
- Client / regulated data (Malaysian PDPA, ISO 27001) → **Compliance edition** (audit + reporting)
- Team / agency with per-client isolation → **multi-tenant edition**
- Real-time drift supervision (watch & block as it happens) → **supervision edition**

Licensing & editions: **hello@alesa.my** · **https://alesa.my**

---
© Novastack System Sdn. Bhd.. Free for individual use — see [LICENSE.txt](LICENSE.txt).
