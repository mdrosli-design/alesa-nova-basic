---
name: nova-brainstorm
description: "Design before you build. Force a short plan — goal, approach, risks, what could break — and get it agreed BEFORE writing code, so the agent doesn't sprint in the wrong direction. Use when: 'how should I build', 'plan this', 'design', starting a non-trivial feature, or when a request is ambiguous."
---

# nova-brainstorm — think before the agent sprints

The fastest way to waste an AI coding session is to let it write 200 lines toward the wrong
goal. This skill inserts a short design step first.

## Method

1. **Restate the goal in one sentence.** If you can't, the request is ambiguous — ask 1–3
   clarifying questions before any code (audience, success criterion, what's out of scope).
2. **Sketch 1–2 approaches**, not just the first idea. For each: what it does, main trade-off,
   what it touches.
3. **List what could break** — empty input, errors, the loading state, race conditions, existing
   callers, data already in the system.
4. **Pick one approach and say why.** Name the files you'll create/modify and the order.
5. **Get a thumbs-up before building** if the change is non-trivial or hard to reverse.

## Guardrails
- Don't silently expand scope ("while I'm here, I also refactored…"). Touch only what the goal
  needs; if you spot something else, mention it — don't just do it.
- Prefer the smallest change that fully solves the problem over a clever rewrite.
- If two approaches are close, pick the simpler one and note the alternative.

Output of a brainstorm = a short plan the human can approve in 10 seconds — not an essay.
