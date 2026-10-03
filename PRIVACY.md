# Privacy — ALESA NOVA Basic

*Applies to ALESA NOVA Basic, a free Claude Code plugin published by Novastack System Sdn. Bhd.*
*[Bahasa Malaysia below](#privasi--ringkasan)*

**ALESA NOVA Basic collects no data.** It has no accounts, no telemetry and no analytics, and it makes no
network requests: nothing is sent, uploaded or fetched by the plugin.

## What stays on your machine

The plugin's hooks write only under `~/.nova-basic/` in your own user account (folder mode 700):

| What | Contents | Kept for |
|---|---|---|
| Backups | copies of files taken just before the AI agent edited them | 14 days (`NOVA_BACKUP_KEEP_DAYS`) |
| Guard logs | time, which guard acted, why, the file or command — credential samples masked | until you delete them |
| Activity log | per tool call: time, session id, working folder, tool name, file path, the first 300 characters of a command (known secret formats and `password=`-style values redacted), a URL without its query string, a search query — never file contents | 90 days (`NOVA_LOG_KEEP_DAYS`) |
| State files | small markers (e.g. last housekeeping date) | until you delete them |

Redaction is pattern-based: a credential in an unusual format typed directly into a command could still be
logged — turn the activity log off with `NOVA_ACTIVITY_LOG=off` if that matters for your work. Delete everything at any time by removing the
`~/.nova-basic` folder. On a shared machine, an administrator with root access can read users' home folders.

## What the plugin does not change

Your prompts and code still go to the AI model provider you configured in Claude Code, under that provider's
terms. ALESA NOVA Basic does not add any destination.

## Support reports

`/nova-doctor --save` writes a report to your machine only when you ask for it. It contains versions,
settings and masked guard events — no file contents and no secrets. You decide whether to send it to us.

## Contact

Novastack System Sdn. Bhd. · hello@alesa.my · https://alesa.my

---

## Privasi — ringkasan

**ALESA NOVA Basic tidak mengumpul sebarang data.** Tiada akaun, tiada telemetri, tiada analitik dan tiada
permintaan rangkaian. Hook hanya menulis di bawah `~/.nova-basic/` dalam akaun anda sendiri (mod 700):
backup fail sebelum diedit oleh ejen (14 hari), log pagar dengan rahsia ditapis, dan log aktiviti (alat,
laluan fail, 300 aksara pertama arahan dengan rahsia ditapis; tidak pernah kandungan fail; 90 hari). Matikan
log aktiviti dengan `NOVA_ACTIVITY_LOG=off`; padam semuanya bila-bila masa dengan membuang folder
`~/.nova-basic`. Prompt dan kod anda tetap dihantar kepada penyedia model AI yang anda tetapkan dalam Claude
Code, tertakluk kepada terma penyedia itu — plugin ini tidak menambah destinasi lain.
