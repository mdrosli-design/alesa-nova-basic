# Security — ALESA NOVA Basic

## Reporting a vulnerability

If you find a way past one of the guards, or a security problem in the plugin itself, report it privately by
email to **hello@alesa.my** with "Security: ALESA NOVA Basic" in the subject. Please do not open a public issue
for it. Include the plugin version (`/nova-doctor` shows it), your operating system, and the smallest command or
file that reproduces the problem.

Reports are investigated with reasonable care. A confirmed issue is fixed in a new release and noted in the
[CHANGELOG](CHANGELOG.md).

## Scope

The guards stop the AI agent's tool calls, not commands you type yourself, and they read the command text. A
command hidden through variables, aliases, `eval`, a script or a config override is a documented limit (README,
"Honest limits"), not a vulnerability — but a common, everyday form that slips through is worth reporting.
Product questions and ordinary bugs go to [GitHub issues](https://github.com/mdrosli-design/alesa-nova-basic/issues).

---

**Laporan keselamatan (BM):** hantar secara peribadi ke **hello@alesa.my** dengan subjek "Security: ALESA NOVA
Basic" — jangan buka isu awam. Sertakan versi plugin (`/nova-doctor`), sistem pengendalian, dan arahan atau fail
paling kecil yang menghasilkan masalah itu.
