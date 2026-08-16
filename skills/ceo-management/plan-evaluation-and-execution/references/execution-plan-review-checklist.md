# Execution Plan Review Checklist

Agents use this when evaluating an execution plan in Phase 2. Fill it out during your review of the execution plan and flag issues as problems in your [review-feedback](/handbook/templates/review-feedback).

---

## Readability & Clarity

- [ ] I understand what each task (T1, T2, ...) does in one sentence
- [ ] Each task's goal is unambiguous (not "improve performance" but "reduce cluster latency from 500ms to <200ms")
- [ ] I know where to start for my task (don't have to ask "what's the first step?")
- [ ] I know what "done" looks like (verification criteria are explicit)

---

## Granularity (Goldilocks Zone)

- [ ] Steps are not too coarse (I can start immediately, no "what tool?" or "which file?" ambiguity)
- [ ] Steps are not too fine (not micro-managing git commands or file I/O like I'm a beginner)
- [ ] Each step fits in 1–2 sentences
- [ ] Conditional branches are clear (if X happens, do Y; else do Z)

---

## Completeness

- [ ] My task list is complete (no missing sub-tasks hiding in the shadows)
- [ ] Dependencies are clear (if I depend on another Agent's output, it's explicitly listed)
- [ ] Inputs and outputs are specified for each major step
- [ ] Success criteria are measurable (not "it works" but "exit code 0 AND logs contain 'success'")

---

## Iteration Budget (30-Round Limit)

- [ ] Work estimate per task seems realistic (not "5 rounds" for a complex debug)
- [ ] Total rounds across all my tasks: _____ (should be ≤30)
- [ ] If sum > 30: flag as ⚠️ (CEO needs to descope or split)

---

## Problem Prediction & Self-Help

- [ ] Problem table covers the likely blockers in my domain
- [ ] Each problem has a "first try" action (I can attempt without immediately escalating)
- [ ] If I try and fail, the escalation path is clear (who to @CEO, what info to include)
- [ ] Are there risks the table misses? (if yes, flag and suggest additions)

---

## Autonomy & CEO Boundaries

- [ ] I can solve typical issues myself (tool errors, syntax mistakes, test failures)
- [ ] It's clear when to escalate 🔴 (permissions, cross-task blockers, time risk, security)
- [ ] CEO's role is clear (not "do this for me" but "unblock me")

---

## Final Signal

- [ ] ✅ **I can execute this plan with high confidence, solo.**
- [ ] ⚠️ **I can execute, but with concerns (specify in review-feedback).**
- [ ] ❌ **This plan needs revision before I can commit.**

---

## How to Report Issues

If any checklist item is ❌ or ⚠️:

1. **Use [review-feedback template](/handbook/templates/review-feedback)**
2. **Set conclusion to:** ⚠️ (conditional pass) or ❌ (has problems)
3. **List each problem:**
   - What's wrong (too coarse, missing step, etc.)
   - How it affects you (I'll be stuck on step 5, iteration estimate is off, etc.)
   - What granularity/level of detail would fix it
4. **Priority:** 🔴 (blocks me from starting) or 🟡 (makes it harder)
5. **Suggest fix:** What the revised text should say

---

## Example Checklist Fill

**Task T3: Deploy to staging**

- [ ] ✅ Understand what task does
- [ ] ✅ Goal is unambiguous ("build Docker image, push to registry, run smoke tests")
- [ ] ✅ Know where to start ("pull latest code from main branch")
- [ ] ⚠️ **"Done" criteria unclear** — "logs should contain 'deployment successful'" but what about timing? How long do I wait?
  - **Priority:** 🟡 (important but not blocking)
  - **Fix:** Add "Wait up to 5 min for services to stabilize, then check /health endpoint returns 200"
- [ ] ✅ Steps are right-sized (1–2 sentences each)
- [ ] ✅ Conditional branches clear (if smoke test fails, roll back; if pass, proceed to manual QA)

**Recommendation:** ⚠️ Conditional pass. One refinement needed: clarify "done" for deployment. Otherwise I can execute.

