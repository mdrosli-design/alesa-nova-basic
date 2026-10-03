# Memasang ALESA NOVA Basic di makmal komputer atau mesin dikongsi

[English](LAB-DEPLOYMENT.md)

Untuk pentadbir makmal universiti dan sekolah, pusat latihan, kumpulan penyelidikan — dan sesiapa yang
menjalankan Claude Code pada mesin yang dikongsi beberapa akaun, termasuk stesen kerja AI on-prem dan kit
Raspberry Pi bilik darjah.

## Apa yang diperoleh

- Dipasang **sekali bagi setiap mesin**, aktif untuk **setiap akaun pengguna** pada sesi Claude Code seterusnya.
- Pengguna **tidak boleh mematikannya** melalui tetapan atau shell sendiri: tetapan terurus (managed settings)
  mengatasi semua skop lain, dan hook daripada plugin yang dipaksa-hidup di situ terus berjalan walaupun
  pengguna mematikan hook.
- Mod pagar dan bahasa **dikunci secara berpusat** (nilai `env` terurus menimpa pemboleh ubah yang dieksport
  pengguna).
- **Kemas kini automatik** dalam talian, atau daripada cermin anda sendiri secara luar talian.
- Backup dan log aktiviti setiap pengguna kekal dalam **folder home masing-masing** (`~/.nova-basic`, mod 700).

## Keperluan

- Claude Code dipasang untuk pengguna. Cara mereka log masuk dan model yang digunakan (Anthropic, penyedia
  awan, atau gerbang ke model tempatan) ditetapkan berasingan — pagar berfungsi sama dalam setiap kes.
- `bash` dan `git`; `python3` disyorkan (Ubuntu, Debian dan Raspberry Pi OS sudah menyertakannya). Diuji pada
  macOS, Ubuntu dan Debian, x86-64 dan ARM64.
- Akses pentadbir (root) untuk menulis fail tetapan terurus.

## Pilihan A — dalam talian (mesin boleh mencapai GitHub)

Cipta atau tambah fail tetapan terurus:

- Linux: `/etc/claude-code/managed-settings.json`
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`

```json
{
  "extraKnownMarketplaces": {
    "alesa-nova": {
      "source": { "source": "github", "repo": "mdrosli-design/alesa-nova-basic" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "alesa-nova-basic@alesa-nova": true
  },
  "env": {
    "NOVA_LANG": "ms",
    "NOVA_SECRET_GATE_MODE": "enforce",
    "NOVA_DANGER_GATE_MODE": "enforce",
    "NOVA_INSECURE_GATE_MODE": "enforce",
    "NOVA_DONE_GATE_MODE": "enforce"
  }
}
```

Jika fail itu sudah wujud, gabungkan kunci ini ke dalamnya — jangan gantikan polisi lain. Pada sesi
seterusnya setiap pengguna, Claude Code mendaftarkan marketplace dan memasang plugin untuk pengguna itu.

## Pilihan B — luar talian (air-gapped)

1. Pada mesin yang ada internet: `git clone https://github.com/mdrosli-design/alesa-nova-basic.git`
   (atau muat turun arkib keluaran dari GitHub).
2. Salin folder itu ke setiap mesin makmal, contohnya `/opt/alesa-nova-basic`, boleh dibaca semua pengguna
   (`chmod -R a+rX /opt/alesa-nova-basic`).
3. Dalam tetapan terurus di atas, guna sumber direktori menggantikan GitHub:
   `"source": { "source": "directory", "path": "/opt/alesa-nova-basic" }` (kekalkan `"autoUpdate": true`).
4. Untuk kemas kini: gantikan `/opt/alesa-nova-basic` dengan keluaran baharu, atau `git pull` daripada cermin
   dalaman. Pengguna menerimanya pada sesi seterusnya (atau dengan
   `claude plugin update alesa-nova-basic@alesa-nova`).

Untuk imej mesin dan kontena yang tidak boleh clone semasa berjalan, Claude Code juga menyokong direktori
seed plugin yang diisi terlebih dahulu (`CLAUDE_CODE_PLUGIN_SEED_DIR`) — lihat dokumentasi Claude Code tentang
pengurusan plugin untuk organisasi.

## Pilihan C — pengguna memasang sendiri

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```

## Tetapan disyorkan untuk makmal pelajar

| Tetapan (dalam `env` terurus) | Cadangan | Sebab |
|---|---|---|
| `NOVA_LANG` | `ms` atau `en` | Mesej dan taklimat sesi dalam Bahasa Malaysia atau Inggeris |
| `NOVA_*_GATE_MODE` | `enforce` | Semua pagar terus menyekat |
| `NOVA_LOG_KEEP_DAYS` | `120` | Simpan log aktiviti sepanjang semester, untuk `/nova-report` |
| `NOVA_BACKUP_KEEP_DAYS` | `14` | Backup adalah untuk mengundur edit terkini |

Pilihan, di luar `env`:

- `"outputStyle": "<nama gaya Coach>"` — setiap sesi bermula dalam mod belajar **Coach**. Buka `/config` →
  Output style sekali untuk melihat nama tepat yang dipaparkan Claude Code (lazimnya
  `alesa-nova-basic:coach`) dan guna nilai itu.
- `"allowManagedHooksOnly": true` — hanya hook terurus dan hook plugin yang dipaksa-hidup berjalan; hook lain
  yang ditambah pengguna diabaikan.

## Semak setiap mesin

Sebagai pengguna biasa (bukan pentadbir), mulakan Claude Code dalam mana-mana folder dan jalankan
`/nova-doctor`. Jangkaan:

- `Managed setup: … (enables alesa-nova-basic@alesa-nova for every user)`
- `Hooks : 8/8 present, executable, syntax OK`
- `Self-test : … 27 passed · 0 failed`

`claude plugin list` sepatutnya menunjukkan `alesa-nova-basic@alesa-nova` aktif.

## Privasi, untuk pentadbir dan pelajar

- Plugin ini tidak menghantar apa-apa keluar dari mesin, tiada akaun dan tiada telemetri ([PRIVACY.md](../PRIVACY.md)).
- Log aktiviti disimpan dalam folder home setiap pengguna (mod 700): pelajar lain tidak boleh membacanya;
  pentadbir yang mempunyai akses root boleh. Maklumkan kepada pengguna anda.
- Pelajar menghasilkan laporan penggunaan AI sendiri dengan `/nova-report` bila tugasan meminta pendedahan
  penggunaan AI.

## Sokongan jauh

Jalankan `/nova-doctor --save` dan hantar fail itu ke **hello@alesa.my**. Ia mengandungi versi, tetapan dan
peristiwa pagar yang ditapis — tiada kandungan fail dan tiada rahsia.

## Had

- Pagar menahan panggilan alat oleh ejen AI, bukan arahan yang ditaip pengguna di terminal — kekalkan kawalan
  OS biasa (tiada hak pentadbir untuk pelajar, kuota cakera).
- Pengguna yang mempunyai hak pentadbir boleh mengubah tetapan terurus.
- Pengesanan berasaskan corak: kes biasa dan berkeyakinan tinggi, bukan setiap kesilapan yang mungkin berlaku.
