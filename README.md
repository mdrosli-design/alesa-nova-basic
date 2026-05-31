<!-- EN below · Bahasa Malaysia di bawah ↓ -->

# ALESA NOVA — Marketplace (free)

**Disciplined AI coding for solo builders. Vibe code without the disasters.**
*(Baca dalam Bahasa Malaysia ↓)*

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
/plugin marketplace add mdrosli-design/alesa-nova-basic
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

# 🇲🇾 ALESA NOVA — Marketplace (percuma)

**Coding-AI yang berdisiplin untuk pembina solo. Vibe code tanpa bencana.**

Marketplace ini menyediakan **ALESA NOVA Basic** — plugin Claude Code percuma yang menambah
pagar keselamatan **mekanikal** pada AI coding agent anda: hook yang **bertindak** pada saat risiko
(sekat atau backup), bukan sekadar peringatan. Ia jawapan kepada masalah sebenar AI coding laju —
secret bocor, tetapan tak selamat (insecure default), kerja tertimpa, dan dakwaan "siap" yang
sebenarnya tak pernah disahkan.

## Apa ALESA NOVA Basic beri anda

| Pagar (gate) | Apa ia buat | Bencana yang dielak |
|-------|--------------|----------------------|
| **secret-leak gate** | Sekat API key / token / DB password / private key sebenar daripada masuk ke fail client-exposed atau commit. | Tertolak API key ke repo public. |
| **insecure-default gate** | Sekat RLS-off, TLS-verify-off, wildcard CORS + credentials, `DEBUG` dalam env prod. | Database terdedah luas & lubang keselamatan. |
| **backup-before-edit** | Auto-simpan `<file>.bak.auto` sebelum agent edit fail sedia ada. | "AI tertimpa code aku yang dah jalan." |
| **change-annotation** | Ingatkan nota `// [CHANGE] what · why · verify` pada setiap edit code. | Code yang tak siapa faham kemudian. |

Tambah satu kaedah kerja (3 Laws · "siap" berasaskan bukti · jangan-percaya-sebelum-disahkan)
dan dua skill — `/nova-verify` (pengesahan sistematik + jadual bukti) dan `/nova-brainstorm`
(reka bentuk sebelum bina).

## Pasang (Install)

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```
Restart Claude Code, kemudian jalankan `/nova-basic` untuk lihat apa yang aktif.

Dua security gate **menyekat secara default**. Tukar ke amaran-sahaja (warn) semasa anda belajar:
`NOVA_SECRET_GATE_MODE=warn` · `NOVA_INSECURE_GATE_MODE=warn`.

## Edisi

**Basic** (ini — percuma, solo) → **Compliance** (berlesen: PDPA Malaysia · ISO/IEC 27001 ·
penjajaran MAMPU + suite keselamatan/audit) → multi-tenant pasukan/agensi + pengawasan masa-nyata.

Pelesenan & edisi lebih tinggi: **hello@alesa.my** · **https://alesa.my**

---
© ALESA IT Services. Basic percuma untuk kegunaan individu — lihat LICENSE.txt plugin.
