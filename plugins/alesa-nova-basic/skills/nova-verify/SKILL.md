---
name: nova-verify
description: "Systematic verification before claiming a change is done. Iron rule — LINT IS NOT VERIFICATION; prove it works by running the actual thing, then show an evidence table. Use when: 'verify', 'is this done', 'did it work', 'test this change', before saying done/fixed/deployed, or before a commit/PR. BM: 'sahkan', 'dah siap ke belum', 'berjalan ke tidak', 'test perubahan ni', 'buktikan ia berjalan', sebelum mengatakan siap/deploy."
---

# nova-verify — prove it, don't assume it

A change is **not done** until you have exercised the same thing the user cares about and shown
proof. Compiling, clearing a cache, or a green lint says nothing about whether the behaviour is
correct. This skill is the practical form of "evidence-based done".

## Method

1. **Name the failure mode.** What would "broken" look like for THIS change? Your verification
   must exercise that exact thing (a schema change → run the query; a route change → hit the
   route; a UI change → render the page).
2. **Run the real probe**, not a proxy:
   - Code/logic → run the test, or call the function/endpoint with a real input.
   - HTTP → `curl -s -o /dev/null -w '%{http_code}'` and check the expected status.
   - Data/DB → a `SELECT`/count before & after, plus an invariant check.
   - UI → actually render it (and check a small viewport too).
   - CLI/script → run it and read the output + exit code.
3. **Add a negative test** for anything security/auth-related (e.g. an unauthenticated request
   should be rejected — confirm it is).
4. **Show an evidence table** before you say done:

   | # | Probe | Expected | Actual | Verdict |
   |---|-------|----------|--------|---------|
   | 1 | `curl /api/x` → status | 200 | 200 | pass |
   | 2 | unauth POST → status | 401 | 401 | pass |

5. **Only claim "done" if every row is green.** Any red → fix → re-run → re-table. Never spin a
   failed probe as success.

## Honesty rules
- Don't say *done / fixed / works / deployed / verified* without a probe behind it.
- State confidence and name what you did **not** check. Never claim 100%.
- If a full test is risky (e.g. on production), run a safe read-only equivalent and state the
  residual risk explicitly.
