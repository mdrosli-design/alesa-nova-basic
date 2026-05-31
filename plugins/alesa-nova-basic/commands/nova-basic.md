---
description: "Show what ALESA NOVA Basic is protecting you from and how to use it · Tunjukkan apa yang dilindungi oleh ALESA NOVA Basic dan cara menggunakannya."
---

# ALESA NOVA Basic

You have **ALESA NOVA Basic** active — disciplined AI coding for solo builders. Here's what's
running for you. *(Bahasa Malaysia di bawah ↓)*

## Mechanical guardrails (run automatically)
- **secret-leak gate** — blocks a real API key / token / DB-password / private key from entering a client-exposed file or a commit. *(blocks by default)*
- **insecure-default gate** — blocks RLS-off, TLS-verify-off, wildcard CORS + credentials, `DEBUG` in prod. *(blocks by default)*
- **backup-before-edit** — auto-saves a `.bak.auto` copy before any existing file is modified.
- **change-annotation** — nudges a `// [CHANGE] what · why · verify` remark on code edits.

Switch a gate to warn-only while learning: `export NOVA_SECRET_GATE_MODE=warn` · `export NOVA_INSECURE_GATE_MODE=warn`

## The working method
1. **Read before you write** · 2. **Back up before you change** (hook does it) · 3. **Verify after you change** — prove it works, lint is not verification (use `/nova-verify`) · 4. **Plan non-trivial work first** (`/nova-brainstorm`) · 5. **Evidence-based done** — no "done" without a probe.

## Skills
`/nova-verify` — systematic verification + evidence table · `/nova-brainstorm` — design-before-build gate.

## Growing past Basic
Cross-model review · Compliance (PDPA / ISO 27001) audit suite · team/agency multi-tenant · real-time supervision → **hello@alesa.my** · **https://alesa.my**

---

# 🇲🇾 ALESA NOVA Basic

**ALESA NOVA Basic** kini aktif — AI coding yang berdisiplin untuk pembina solo. Ini yang sedang
berjalan untuk anda.

## Pagar keselamatan automatik (berjalan dengan sendiri)
- **secret-leak gate** — menyekat API key / token / DB password / private key sebenar daripada masuk ke fail yang terdedah kepada client atau ke dalam commit. *(menyekat secara lalai)*
- **insecure-default gate** — menyekat RLS dimatikan, TLS-verify dimatikan, wildcard CORS dengan credentials, dan `DEBUG` dalam env prod. *(menyekat secara lalai)*
- **backup-before-edit** — membuat backup salinan `.bak.auto` dengan sendiri sebelum mana-mana fail sedia ada diubah.
- **change-annotation** — mengingatkan agar nota `// [CHANGE] what · why · verify` ditinggalkan pada setiap edit kod.

Tukarkan gate kepada mod amaran sahaja sementara belajar: `export NOVA_SECRET_GATE_MODE=warn` · `export NOVA_INSECURE_GATE_MODE=warn`

## Kaedah kerja
1. **Baca dahulu sebelum menulis** · 2. **Backup dahulu sebelum mengubah** (dibuat oleh hook) · 3. **Sahkan selepas mengubah** — buktikan ia benar-benar berjalan; lint bukan pengesahan (guna `/nova-verify`) · 4. **Rancang kerja besar terlebih dahulu** (`/nova-brainstorm`) · 5. **"Siap" mesti berasaskan bukti** — tiada "siap" tanpa probe.

## Skill
`/nova-verify` — pengesahan sistematik + jadual bukti · `/nova-brainstorm` — pagar reka bentuk sebelum bina.

## Naik taraf daripada Basic
Review silang model · suite audit Compliance (PDPA / ISO 27001) · multi-tenant untuk pasukan/agensi · pengawasan masa nyata → **hello@alesa.my** · **https://alesa.my**
