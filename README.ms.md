# ALESA NOVA Basic

**AI coding yang berdisiplin — percuma. Vibe code tanpa bencana.**

[English](README.md) · [Pemasangan makmal](docs/LAB-DEPLOYMENT.ms.md) · [Privasi](PRIVACY.md) · [Changelog](CHANGELOG.md)

Ejen AI coding sangat pantas — dan kepantasan itulah punca API key bocor, tetapan tidak selamat terlepas ke
produksi, kod yang sudah berjalan tertimpa, dan "siap ✅" yang rupa-rupanya tidak pernah diuji.
**ALESA NOVA Basic** ialah plugin Claude Code percuma yang menambah disiplin *mekanikal*: hook yang
**bertindak** pada saat berisiko — menyekat, membuat backup, atau menghantar ejen kembali untuk membuktikan
kerjanya — berserta kaedah kerja ringkas, kesinambungan projek, mod belajar dan doktor yang menguji dirinya
sendiri. Semuanya berjalan di mesin anda sahaja.

Dibina untuk **pembangun perisian**, **pelajar dan makmal komputer**, serta **stesen kerja AI on-prem** —
di mana-mana sahaja ejen AI boleh menjalankan arahan dan mengubah kod. Bahasa Inggeris dan Bahasa Malaysia.

## Apa yang anda dapat

| | Modul | Fungsinya |
|---|---|---|
| 🛡 | **Pagar kebocoran rahsia** | Menyekat kelayakan sebenar — awan, pembayaran, hos git dan kunci penyedia AI (OpenAI, Anthropic, Hugging Face, Groq, Replicate, OpenRouter, xAI, Perplexity, Google) — daripada masuk ke kod client, pemboleh ubah env awam, commit atau push. Mengimbas perubahan sebenar yang akan di-commit atau di-push (hingga 500 fail baharu, 1 MB setiap fail, 8 MB keseluruhan — anda dimaklumkan bila imbasan separa). |
| 🛡 | **Pagar arahan bahaya** | Menyekat padam pukal folder sistem/home, DROP/TRUNCATE, force-push, `--no-verify`, `curl … \| bash`, dan bahaya mesin dikongsi: docker prune semua, reboot/shutdown, `git reset --hard` atau `git clean` ke atas kerja yang belum di-commit. |
| 🛡 | **Pagar tetapan tidak selamat** | Menyekat RLS dimatikan, peraturan Firebase terbuka, pengesahan TLS dimatikan, wildcard CORS dengan credentials, DEBUG di produksi, Jupyter terbuka ke rangkaian tanpa token. Memberi amaran untuk pelayan model yang terdedah dan pautan awam Gradio. |
| 💾 | **Backup sebelum edit** | Menyalin setiap fail (termasuk notebook) sebelum ejen mengubahnya — sekali bagi setiap 5 minit, fail melebihi 20 MB dilangkau — di luar folder projek, jadi backup tidak akan ter-commit. |
| ⚖️ | **3 Laws** | Baca sebelum tulis · backup sebelum ubah · sahkan selepas ubah — diberi kepada ejen setiap sesi. Gate *siap mesti ada bukti* menghantar ejen kembali sekali bila ia mendakwa "siap" tanpa semakan yang lulus (larian gagal tidak dikira; perlukan python3). |
| 🔁 | **Kesinambungan** | `/nova-init`, `/nova-checkpoint`, `/nova-resume` (`/nova-sambung`): brief projek yang dibaca dahulu oleh setiap sesi baharu, di mana-mana mesin. |
| 🎓 | **Mod Coach** | Gaya output untuk pelajar: terangkan dahulu, langkah kecil, bahagian penting ditinggalkan untuk anda, semak kefahaman. |
| 📝 | **Laporan penggunaan AI** | `/nova-report` — apa yang dilakukan AI, berserta pernyataan pendedahan untuk disunting, bagi tugasan dan kerja klien. |
| 🩺 | **Doktor** | `/nova-doctor` — semakan kesihatan, ujian kendiri yang membuktikan pagar menyekat di mesin *ini*, dan laporan sokongan tanpa kandungan fail atau rahsia. |

Setiap pagar ada suite ujian regresi (`plugins/alesa-nova-basic/tests/run-tests.sh`, 226 semakan) yang
dijalankan pada macOS (bash 3.2 dan 5) dan Linux — Ubuntu dan Debian, x86-64 dan ARM64 (asas Raspberry Pi
OS 64-bit dan stesen kerja AI ARM) — dalam tiga mod: dengan python3, dengan jq sahaja, dan pada mesin kosong
tanpa kedua-duanya, kerana pagar keselamatan tidak boleh gagal terbuka.

## Pasang

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```

Mulakan semula Claude Code, kemudian jalankan `/nova-doctor`. Untuk Bahasa Malaysia, tetapkan
`"NOVA_LANG": "ms"` dalam `"env"` tetapan Claude Code. Kemas kini: `claude plugin update
alesa-nova-basic@alesa-nova`, atau hidupkan kemas kini automatik sekali sahaja: `/plugin` → **Marketplaces**
→ `alesa-nova` → **Enable auto-update** (mati secara lalai untuk marketplace pihak ketiga).

**Makmal komputer dan mesin dikongsi** — pasang sekali untuk semua akaun, kunci tetapan pagar supaya tidak
boleh dimatikan oleh pengguna, guna cermin luar talian, dan kekal dikemas kini secara automatik:
[docs/LAB-DEPLOYMENT.ms.md](docs/LAB-DEPLOYMENT.ms.md).

## Arahan

| Arahan | |
|---|---|
| `/nova-basic` | Apa yang aktif dan cara guna |
| `/nova-init` | Brief projek + changelog + `.gitignore` selamat (tidak menimpa apa-apa) |
| `/nova-checkpoint [commit]` | Simpan kemajuan ke dalam brief (pilihan: commit tempatan) |
| `/nova-resume` · `/nova-sambung` | Sambung dari brief |
| `/nova-verify` · `/nova-brainstorm` · `/nova-tdd` | Jadual pengesahan · reka bentuk sebelum bina · ujian dahulu |
| `/nova-report` | Laporan penggunaan AI |
| `/nova-doctor [--save]` | Semakan kesihatan, ujian kendiri, laporan sokongan |
| Gaya output **Coach** | `/config` → Output style |

(Nama penuh ialah `/alesa-nova-basic:<arahan>`; bentuk ringkas berfungsi bila tiada arahan lain menggunakannya.)

## Ketelusan

Skrip bash biasa, kod sumber boleh dibaca, tiada akses rangkaian. Hook hanya menulis di bawah
`~/.nova-basic/` — backup, log pagar dengan format rahsia yang dikenali ditapis, dan log aktiviti setempat (alat, laluan fail,
permulaan arahan; tidak pernah kandungan fail). Butiran: [README plugin](plugins/alesa-nova-basic/README.md)
dan [PRIVACY.md](PRIVACY.md).

**Had yang jujur:** pagar menahan panggilan alat oleh ejen, bukan arahan yang anda taip sendiri; pengesanan
membaca teks arahan (bentuk biasa dan berkeyakinan tinggi, termasuk laluan berpetik dan gugusan pilihan) —
arahan yang disamarkan melalui pemboleh ubah, alias, `eval`, skrip atau tetapan config tidak kelihatan; gate siap
memerlukan python3; log aktiviti adalah setempat dan boleh disunting; Basic tidak menggantikan semakan kod.

## Framework ALESA NOVA

Basic ialah edisi percuma **ALESA NOVA**, framework disiplin kejuruteraan untuk ejen AI coding yang
berpegang pada satu prinsip: *bukti, bukan janji.* Edisi berlesen — untuk pasukan, agensi, institusi dan
kerja terkawal — menambah:

- semakan AI kedua yang bebas bagi setiap perubahan penting sebelum dihantar
- lejar blueprint, supaya tiada apa-apa dalam spesifikasi tertinggal secara senyap
- kitaran projek yang dikuatkuasakan (brief, checkpoint, tutup) untuk seluruh pasukan
- alatan pematuhan dan audit (perlindungan data, analisis jurang ISO/IEC 27001)
- konsol pasukan, pemantauan masa nyata, dan pemasangan on-prem

**https://alesa.my** · **hello@alesa.my**

---
© Novastack System Sdn. Bhd. · ALESA NOVA Basic percuma untuk kegunaan individu dan dalaman — lihat
[LICENSE.txt](plugins/alesa-nova-basic/LICENSE.txt).
