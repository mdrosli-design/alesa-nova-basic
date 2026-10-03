# Contributing to ALESA NOVA Basic

Thank you for helping. Bug reports, false positives and missed cases are the most useful contributions: a guard
that blocks everyday work gets uninstalled, and a guard that misses a common form protects nobody.

## Before you open a pull request

- **Security issues** (a way past a guard, a problem in the plugin itself): report privately — see
  [SECURITY.md](SECURITY.md). Please do not open a public issue for them.
- **Licence:** contributions are accepted under the [Contributor Licence Agreement](CLA.md). Tick the box in the
  pull-request template to accept it. The repository itself is under the [Mozilla Public License 2.0](LICENSE.txt);
  the names and logo are not ([TRADEMARKS.md](TRADEMARKS.md)).

## Rules for changes

- One concern per pull request. Explain what was wrong, what changes, and how you checked it.
- Every guard change comes with test cases in `tests/run-tests.sh`: one that must be blocked and one everyday command
  that must still pass.
- Hooks must keep working with **bash 3.2** (macOS) and on a machine **without python3 or jq** — a security guard must
  never fail open on a minimal machine.
- No network calls, no telemetry, nothing written outside `~/.nova-basic/`.

## Checking your change

```
bash tests/run-tests.sh          # full suite (python3, jq-only and bare modes)
/bin/bash tests/run-tests.sh     # on macOS: the system bash 3.2
```

All checks must pass. CI runs the same suite on Ubuntu (x86-64 and ARM64) and macOS.
