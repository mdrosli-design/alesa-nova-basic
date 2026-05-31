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

**AI coding yang berdisiplin untuk pembina solo. Vibe code tanpa bencana.**

Marketplace ini menyediakan **ALESA NOVA Basic** — plugin Claude Code percuma yang melengkapkan
AI coding agent anda dengan pagar keselamatan **automatik**. Bukan sekadar peringatan — hook-nya
benar-benar bertindak pada saat berisiko: menyekat tindakan bahaya atau membuat backup dengan
sendiri. Ia direka untuk menangani masalah yang kerap timbul apabila kita coding laju bersama AI —
secret bocor, tetapan lalai yang tidak selamat (insecure default), kod sedia ada tertimpa-ganti,
dan kerja yang didakwa "siap" sedangkan tidak pernah disahkan.

## Apa yang ALESA NOVA Basic beri anda

| Pagar (gate) | Fungsinya | Bencana yang dielakkan |
|-------|--------------|----------------------|
| **secret-leak gate** | Menyekat API key / token / DB password / private key sebenar daripada masuk ke fail yang terdedah kepada client (client-exposed) atau ke dalam commit. | API key tertolak ke repo awam. |
| **insecure-default gate** | Menyekat RLS dimatikan, TLS-verify dimatikan, wildcard CORS dengan credentials, dan `DEBUG` dalam env prod. | Database terdedah luas dan lubang keselamatan. |
| **backup-before-edit** | Membuat backup `<file>.bak.auto` dengan sendiri sebelum agent mengedit fail sedia ada. | "AI tertimpa-ganti kod aku yang dah berjalan." |
| **change-annotation** | Mengingatkan agar nota `// [CHANGE] what · why · verify` ditinggalkan pada setiap edit kod. | Kod yang tiada siapa boleh fahami kemudian hari. |

Disertakan juga satu kaedah kerja (3 Laws · "siap" mesti berasaskan bukti · jangan percaya
sebelum disahkan) dan dua skill — `/nova-verify` (pengesahan sistematik + jadual bukti) dan
`/nova-brainstorm` (reka bentuk sebelum bina).

## Pasang (Install)

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```
Mulakan semula Claude Code, kemudian jalankan `/nova-basic` untuk melihat apa yang sedang aktif.

Kedua-dua security gate ini **menyekat secara lalai**. Tukarkan kepada mod amaran sahaja (warn)
sementara anda masih belajar: `NOVA_SECRET_GATE_MODE=warn` · `NOVA_INSECURE_GATE_MODE=warn`.

## Edisi

**Basic** (ini — percuma, untuk solo) → **Compliance** (berlesen: PDPA Malaysia · ISO/IEC 27001 ·
penjajaran MAMPU + suite keselamatan/audit) → multi-tenant untuk pasukan/agensi + pengawasan
masa nyata.

Pelesenan & edisi lebih tinggi: **hello@alesa.my** · **https://alesa.my**

---
© ALESA IT Services. Edisi Basic percuma untuk kegunaan individu — lihat LICENSE.txt plugin.
