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
| **dangerous-command gate** | Blocks catastrophic Bash — `rm -rf /`, `DROP DATABASE`, `git push --force`, `curl \| bash`. | "The AI deleted my files / dropped my database." |
| **backup-before-edit** | Auto-saves `<file>.bak.auto` before the agent edits an existing file. | "The AI overwrote my working code." |
| **change-annotation** | Nudges a `// [CHANGE] what · why · verify` note on code edits. | Code nobody can understand later. |

Plus a working method (3 Laws · evidence-based "done" · untrusted-until-proven) and three skills —
`/nova-verify` (systematic verification + evidence table), `/nova-brainstorm` (design-before-build),
and `/nova-tdd` (test-first discipline: red → green → refactor).

## Why ALESA NOVA (what makes it different)

Most AI-coding helpers *advise* — they suggest, warn, or wait for you to switch on a "safe mode".
ALESA NOVA **acts**:

- **Mechanical, not advisory** — the gates *block* a risky action (exit 2); they don't just print a warning you can scroll past.
- **Always-on, nothing to remember** — once installed, the guards run automatically on every action, every session. There's no "careful mode" to enable; protection never depends on you remembering.
- **Built for the moment you don't know better** — for solo builders and people learning to code with AI, safety is on by default, not opt-in.
- **A real compliance path** — the licensed editions cover Malaysian PDPA, ISO/IEC 27001, and MAMPU-aligned work: discipline that holds up for agency, regulated, and banking-tier delivery — not just generic productivity.

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
| **dangerous-command gate** | Menyekat arahan Bash memusnahkan — `rm -rf /`, `DROP DATABASE`, `git push --force`, `curl \| bash`. | "AI padam fail aku / drop database aku." |
| **backup-before-edit** | Membuat backup `<file>.bak.auto` dengan sendiri sebelum agent mengedit fail sedia ada. | "AI tertimpa-ganti kod aku yang dah berjalan." |
| **change-annotation** | Mengingatkan agar nota `// [CHANGE] what · why · verify` ditinggalkan pada setiap edit kod. | Kod yang tiada siapa boleh fahami kemudian hari. |

Disertakan juga satu kaedah kerja (3 Laws · "siap" mesti berasaskan bukti · jangan percaya
sebelum disahkan) dan tiga skill — `/nova-verify` (pengesahan sistematik + jadual bukti),
`/nova-brainstorm` (reka bentuk sebelum bina), dan `/nova-tdd` (disiplin test-dahulu: red → green → refactor).

## Kenapa ALESA NOVA (apa yang membezakannya)

Kebanyakan alat bantu AI coding sekadar *menasihati* — ia mencadang, memberi amaran, atau menunggu
anda hidupkan "mod selamat". ALESA NOVA pula **bertindak**:

- **Mekanikal, bukan sekadar nasihat** — gate-nya *menyekat* tindakan berisiko (exit 2), bukan sekadar mencetak amaran yang boleh anda abaikan.
- **Sentiasa aktif, tiada apa-apa untuk diingat** — sebaik dipasang, guard berjalan automatik pada setiap tindakan, setiap sesi. Tiada "mod berhati-hati" untuk dihidupkan; perlindungan tidak pernah bergantung pada ingatan anda.
- **Direka untuk saat anda belum tahu** — untuk pembina solo dan mereka yang baru belajar coding dengan AI, keselamatan hidup secara lalai, bukan atas pilihan.
- **Laluan compliance yang sebenar** — edisi berlesen meliputi PDPA Malaysia, ISO/IEC 27001, dan kerja sejajar MAMPU: disiplin yang tahan untuk penyampaian agensi, regulated, dan banking-tier — bukan sekadar produktiviti umum.

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
© Novastack System Sdn. Bhd.. Edisi Basic percuma untuk kegunaan individu — lihat LICENSE.txt plugin.
