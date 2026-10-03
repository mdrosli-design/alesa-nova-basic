# Deploying ALESA NOVA Basic in a computer lab or on shared machines

[Bahasa Malaysia](LAB-DEPLOYMENT.ms.md)

For administrators of university and school labs, training centres, research groups — and anyone running
Claude Code on a machine shared by several accounts, including on-prem AI workstations and Raspberry Pi
classroom kits.

## What this setup gives you

- Installed **once per machine**, active for **every user account** at their next Claude Code session.
- Users **cannot switch it off** from their own settings or shell: managed settings take precedence over every
  other scope, and hooks from a plugin force-enabled there keep running even if a user disables hooks.
- Guard modes and language **pinned centrally** (managed `env` values override variables a user exports).
- **Automatic updates** online, or from your own mirror offline.
- Each user's backups and activity log stay in **their own home folder** (`~/.nova-basic`, mode 700).

## Requirements

- Claude Code installed for the users. How they sign in and which model they use (Anthropic, a cloud
  provider, or a gateway to a local model) is configured separately — the guards work the same way in each case.
- `bash` and `git`; `python3` recommended (Ubuntu, Debian and Raspberry Pi OS include it). Tested on macOS,
  Ubuntu and Debian, on x86-64 and ARM64.
- Administrator (root) access to write the managed settings file.

## Option A — online (machines can reach GitHub)

Create or extend the managed settings file:

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
    "NOVA_LANG": "en",
    "NOVA_SECRET_GATE_MODE": "enforce",
    "NOVA_DANGER_GATE_MODE": "enforce",
    "NOVA_INSECURE_GATE_MODE": "enforce",
    "NOVA_DONE_GATE_MODE": "enforce"
  }
}
```

If the file already exists, merge these keys into it rather than replacing other policy. At each user's next
session, Claude Code registers the marketplace and installs the plugin for that user.

## Option B — offline or air-gapped

1. On a machine with internet access: `git clone https://github.com/mdrosli-design/alesa-nova-basic.git`
   (or download a release archive from GitHub).
2. Copy the folder to each lab machine, for example `/opt/alesa-nova-basic`, readable by all users
   (`chmod -R a+rX /opt/alesa-nova-basic`).
3. In the managed settings above, use a directory source instead of GitHub:
   `"source": { "source": "directory", "path": "/opt/alesa-nova-basic" }` (keep `"autoUpdate": true`).
4. To update: replace `/opt/alesa-nova-basic` with the new release, or `git pull` from an internal mirror.
   Users receive it at their next session (or with `claude plugin update alesa-nova-basic@alesa-nova`).

For machine images and containers that cannot clone at runtime, Claude Code also supports a pre-populated
plugin seed directory (`CLAUDE_CODE_PLUGIN_SEED_DIR`) — see the Claude Code documentation on managing plugins
for an organization.

## Option C — users install it themselves

```
/plugin marketplace add mdrosli-design/alesa-nova-basic
/plugin install alesa-nova-basic@alesa-nova
```

## Recommended settings for student labs

| Setting (in managed `env`) | Suggested | Why |
|---|---|---|
| `NOVA_LANG` | `ms` or `en` | Messages and the session briefing in Bahasa Malaysia or English |
| `NOVA_*_GATE_MODE` | `enforce` | Keep every guard blocking |
| `NOVA_LOG_KEEP_DAYS` | `120` | Keep activity logs for a whole semester, for `/nova-report` |
| `NOVA_BACKUP_KEEP_DAYS` | `14` | Backups are for undoing recent edits |

Optional, outside `env`:

- `"outputStyle": "<the Coach style name>"` — start every session in **Coach** learning mode. Open
  `/config` → Output style once to see the exact name Claude Code shows for it (typically
  `alesa-nova-basic:coach`) and use that value.
- `"allowManagedHooksOnly": true` — only managed hooks and force-enabled plugins' hooks run; other hooks a
  user adds are ignored.

## Check each machine

As a normal (non-admin) user, start Claude Code in any folder and run `/nova-doctor`. Expect:

- `Managed setup: … (enables alesa-nova-basic@alesa-nova for every user)`
- `Hooks : 8/8 present, executable, syntax OK`
- `Self-test : … 27 passed · 0 failed`

`claude plugin list` should show `alesa-nova-basic@alesa-nova` as enabled.

## Privacy, for administrators and students

- The plugin sends nothing off the machine and has no accounts or telemetry ([PRIVACY.md](../PRIVACY.md)).
- Activity logs live in each user's home folder (mode 700): other students cannot read them; an administrator
  with root access can. Tell your users.
- Students create their own AI-use report with `/nova-report` when coursework asks them to declare AI use.

## Remote support

Run `/nova-doctor --save` and send the file to **hello@alesa.my**. It contains versions, settings and masked
guard events — no file contents and no secrets.

## Limits

- The guards stop the AI agent's tool calls, not commands a user types in a terminal — keep normal OS
  controls (no admin rights for students, disk quotas).
- A user with administrator rights can change the managed settings.
- Detection is pattern-based: common, high-confidence cases, not every possible mistake.
