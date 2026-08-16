---
name: plan-evaluation-and-execution
title: Plan Evaluation & Execution Management
description: |
  Two-phase plan evaluation (project plan → execution plan) and hands-on execution supervision.
  Ensures clarity, realistic workload distribution, and Agent autonomy within bounded iteration limits.
  Core to CEO delegation and multi-Agent coordination.
keywords:
  - plan evaluation
  - execution plan
  - granularity
  - Agent delegation
  - CEO supervision
  - 30-iteration limit
  - two-phase review
---

# Plan Evaluation & Execution Management

This skill governs the full lifecycle from plan conception through execution completion. It handles **two separate evaluation phases** (project plan, then execution plan) and the **CEO supervision model** for autonomous Agent work within strict iteration limits.

## Core Model: Two-Phase Evaluation

### Phase 1: Project Plan Evaluation
The **strategic plan** defines WHAT to do and WHY.

**Evaluators:** Department heads (foundation, sysadmin, onyx, etc.)  
**Focus:** Feasibility, risks, cross-team coordination, achievability  
**Evaluation Template:** [handbook/templates/review-feedback](/handbook/templates/review-feedback) — standard format for all reviewers  
**Output:** ✅ Approved project plan (used as input to Phase 2)

**Structure (predefined in template):**
- Chapters 1–6: background, goals, approach, risks, scope, workload distribution
- Chapter 7–9: **Evaluation rounds** (pre-built for multiple rounds with empty result tables)
- Chapter 10–11: Execution phase tracking

Key principle: **Evaluation results FILL pre-built tables, they do NOT modify core plan text.** Each evaluation round has dedicated space; no scrubbing or rewriting of earlier content. Reviewers build pages with [review-feedback template](/handbook/templates/review-feedback), then CEO links them and fills the summary table.

---

### Phase 2: Execution Plan Evaluation
The **tactical execution plan** defines HOW and WHO.

**Created by:** CEO (after Phase 1 approval)  
**Evaluators:** The Agents who will execute (foundation, content-writer, etc.)  
**Evaluation Template:** [handbook/templates/review-feedback](/handbook/templates/review-feedback) — same as Phase 1, but with execution-specific focus  
**Execution-Plan Evaluation Checklist:** Agents evaluate against this before approving:
  - [ ] Can I read this once and start immediately? (Not too coarse)
  - [ ] Is every step concrete? (Input, output, verification are clear)
  - [ ] Are steps too prescriptive? (Am I doing git clone step-by-step when I know the tool?)
  - [ ] Is the iteration budget realistic for my tasks? (Will I stay ≤30 rounds?)
  - [ ] Are the problem-prediction cases comprehensive? (Will I know what to try before escalating?)
  - [ ] Are dependencies clear? (Do I know when other Agents finish so I can start?)

(See `references/execution-plan-review-checklist.md` for the full checklist template Agents use.)

**Output:** ✅ Approved execution plan (tasks + Agents ready to start)

**Structure (predefined in template):**
- Task overview, task decomposition table
- Detailed steps per task (organized by iteration budget)
- Problems/self-help table (Agent tries this first; if it fails, escalate)
- Chapter 7–9: **Execution Evaluation rounds** (pre-built with empty result tables)
- Chapter 10+: Execution tracking

Key principle: **Agents evaluate whether they can independently execute as written.** If granularity is too coarse or too fine, they flag it in their evaluation. CEO revises if needed and re-submits (Phase 2 round 2).

---

## Granularity Heuristic

Too coarse → Agent stuck, can't start:
- ❌ "Deploy application to production"

Acceptable:
- ✅ "Pull latest code from GitHub, update version in config.yaml to v1.2.3, run unit tests, log results to deployment.log"

Too fine → wastes iteration tokens:
- ❌ "Execute git clone. Pause 5 seconds. Check if return code == 0..."

**Litmus:** Can the Agent start immediately after reading once? Does every step say what goes in and what comes out? Is there branching (if X then do Y, else do Z)?

---

## Iteration Budget (30-Round Limit per Agent)

Each Agent has a hard cap of ~30 rounds (Agent ↔ CEO cycles) to complete their tasks.

**Estimation by task type:**
- Simple copy/paste: 1–2 rounds
- Code modification + test: 3–5 rounds
- Debugging/troubleshooting: 4–8 rounds
- Architectural decision: 5–10 rounds
- Complex integration: 8–15 rounds

**Total must not exceed 30 rounds.** If sum > 30, execution plan is overloaded → CEO revises scope or splits into separate plans.

---

## Problem Prediction & Self-Help Table

Before execution starts, populate a table in the execution plan:

| Problem | Symptom | Agent's First Try | If Fails → Escalate |
|---------|---------|-------------------|----------------------|
| Permission denied | 'access denied' in logs | Check IAM role in wiki, apply to test env first | @CEO: need prod role grant |

**Agent discipline:** Consult this table before @CEO. Only escalate if your own try didn't work.

---

## CEO Supervision During Execution

### Daily Oversight
- Check `execution-log` for 🔴 risk flags (blocker, time slip, dependency mismatch, security)
- If 🔴 present: investigate + unblock within 4 hours
- Scan task progress: on track or slipping?

### Weekly Check
- Sum iteration spend across all Agents: how close to 30-round limit?
- Identify critical-path delays that cascade
- Forecast completion vs. deadline

### Sign-Off
- All verification checklists for each task are ✅
- All outputs in specified locations
- execution-log is complete
- CEO signature → Phase 2 done

---

## Escalation Boundaries

**Agent handles independently:**
- Code errors, syntax mistakes
- Tool/command usage questions (Wiki, man pages)
- Test failures
- Conditional branches in the plan

**Agent must escalate 🔴 immediately:**
- Permissions/IAM blockers
- Task blocked waiting for another Agent's output
- Predicted overrun (will exceed 30 rounds)
- Cross-task conflicts
- Security/stability risk
- Out-of-plan requirement (needs scoping)

---

## Pitfalls

1. **Conflating Phase 1 and Phase 2 evaluators.** Project plan reviewers (department heads, asking "is this smart?") ≠ execution plan reviewers (executing Agents, asking "can I do this?"). Don't ask foundation to vet whether content-writer can solo-write docs. Let content-writer decide in Phase 2.

2. **Conflating Phase 1 and Phase 2 evaluation scope.** Phase 1 focuses on strategy (risks, feasibility). Phase 2 focuses on tactics (granularity, iteration budget, self-help). A plan can be strategically sound but tactically underbaked (too coarse to execute).

2. **Granularity creep.** CEO writes steps that are too vague or too prescriptive. Solution: Agents flag during Phase 2 eval, CEO revises and re-submits (Phase 2 round 2).

3. **Ignoring iteration budget until too late.** Estimate *before* Phase 2 approval. During eval, Agents flag if they think a task is underestimated.

4. **Letting 🔴 flags linger.** CEO response time matters. Even a partial unblock lets Agents retry independently.

5. **Not pre-populating the problem/self-help table.** Invest 20 min upfront to list likely blockers and fixes. Prevents Agents over-escalating on every hiccup.

6. **CEO as proxy coder.** If Agent says code breaks, ask "what have you tried?" and point to tools/docs. Only CEO acts on system-level blockers (permissions, infrastructure).

7. **Skipping Phase 2 entirely.** CEO approves Phase 1 project plan, then goes straight to delegation without creating or reviewing an execution plan. Phase 2 is where executing agents check step granularity, iteration budget, dependencies, and self-help tables before work starts. Without it, every task is improvised and every problem is a surprise. This is the most destructive shortcut.

8. **CEO marks "done" before all agents sign off.** CEO sees one agent report HTTP 200, declares project complete. Meanwhile test-ds hasn't run verification. Correct order: all agents sign off → CEO marks done. Never swap these.

9. **Verification is "reachability" only, never "readability".** Every step tests HTTP status codes and link reachability. Nobody opens an actual file, nobody curl's the raw content. A 38-file deployment can ship broken content and pass all checks. Fix: every verification step must include at least one content-level spot-check (cat the file, curl the raw content, read the first 30 lines).

10. **CEO writes conclusions from stale data without re-verifying.** CEO formed a diagnosis 2 hours ago, system changed, but CEO writes the postmortem from the stale diagnosis. Result: postmortem itself contains wrong facts. Fix: before writing any summary, conclusion, or postmortem, re-verify current state with a fresh check (ssh, curl, read_file, wiki get).

11. **CEO writes full analysis instead of launching plan process.** CEO sees a research document from one agent and immediately writes a long analysis (what's good, what's missing, suggested additions) — effectively doing all departments' work himself. This is the same pattern as writing a full solution and asking for approval. Correct: create a draft page with ONLY the problem statement, broadcast @all, let each department contribute from their dimension. CEO's own thoughts go into the synthesis AFTER departments submit — not before.

12. **CEO forgets two-phase process immediately after postmortem.** CEO completes a detailed postmortem admitting he skipped Phase 2, documents the lesson, then immediately starts a new project and skips Phase 2 again. The postmortem is not valid unless behavior changes. Before ANY new project: check against the 9-step workflow summary — are both phases being followed?

---

## Workflow Summary

```
1. Draft project plan (Ch 1–6)
2. Project plan eval Round 1 → Modify if needed
3. CEO approves (Ch 9 signature) → ✅ Approved
4. CEO drafts execution plan
5. Execution plan eval Round 1 → Modify if coarse/fine
6. CEO approves execution
7. Agents execute (daily logs, 🔴 escalations only)
8. CEO supervises (daily risk, weekly forecast)
9. CEO sign-off (verification, completion)
```

