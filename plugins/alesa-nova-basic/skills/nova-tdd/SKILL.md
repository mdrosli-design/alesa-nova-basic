---
name: nova-tdd
description: "Test-driven development discipline — write the failing test FIRST, then the minimum code to make it pass, then refactor. For a bug: write a test that reproduces it before fixing. Iron rule: no production code without a failing test first. Use when: 'tdd', 'test first', 'write a test', building a function/feature, fixing a bug. BM: 'tulis test dulu', 'tdd', 'test dahulu sebelum kod', 'buat ujian dulu', sebelum membina fungsi/feature atau membaiki bug."
---

# nova-tdd — test first, then code

> 🇲🇾 **Ringkasan:** Tulis ujian (test) yang GAGAL dahulu → tulis kod minimum supaya ia lulus →
> kemas (refactor). Untuk bug: tulis ujian yang menghasilkan semula bug itu dahulu, baru baiki.
> Lebih yakin, kurang debug.

Writing the test first forces you to define *what "correct" means* before you build — so you code
toward a target, not into a fog. It's the cheapest confidence you can buy: a safety net that catches
regressions the moment they happen, and far less debugging later.

## The cycle — red → green → refactor
1. **Red** — write ONE small test for the behaviour you want. Run it; watch it **fail**. (Proves the test really tests something, and the feature isn't already there.)
2. **Green** — write the *minimum* code to make that one test pass. Nothing extra. Run it; watch it pass.
3. **Refactor** — clean up the code (and the test) with the green test as your safety net. Re-run; still green.
4. **Repeat** — one small behaviour at a time.

## Iron rules
- **No production code without a failing test first.** If you can't write a test for it, you don't yet understand what you're building — stop and clarify (pairs with `/nova-brainstorm`).
- **For a bug: reproduce it as a failing test FIRST, then fix.** The test proves the bug existed *and* that the fix works — and stops it from silently returning.
- **One behaviour per test** — small, named, fast. A test that checks five things tells you nothing when it fails.
- **A test you never saw fail is not trusted** — it might be passing for the wrong reason.

## Why this fits ALESA NOVA
More rigor (correctness defined up front, regressions caught instantly) with **less** effort (far
less debugging, confident refactors, a safety net you didn't have to think about). Ease + discipline,
fused. Pairs with `/nova-verify` — TDD builds the proof as you go; verify confirms the whole change.
