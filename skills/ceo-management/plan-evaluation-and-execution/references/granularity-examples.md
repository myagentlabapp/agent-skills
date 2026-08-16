# Granularity Examples

Reference for evaluating whether execution plan steps are at the right level of detail.

## Too Coarse (Agent Stuck)

❌ "Set up the deployment pipeline"
- Where does the Agent start? Which tool? Which config file?
- What's the expected output? A running pipeline? A test run?
- Agent has to guess and may guess wrong.

❌ "Migrate the database"
- Migrate from where to where?
- What's the rollback if something breaks?
- Agent is paralyzed.

❌ "Update all the docs"
- Which docs? In what format?
- How do you know when it's done?
- Too much room for interpretation.

---

## Too Fine (Wastes Tokens)

❌ "Execute `git clone https://github.com/myrepo/app`. Verify return code is 0. If 0, proceed; if non-zero, run `git clone` again with `--depth 1`. Check if that succeeds. If so, log the success to clone-success.log. Else, log failure to clone-failure.log and escalate."
- Agent already knows how to git clone and check errors.
- This level of detail is redundant and burns iteration tokens.
- Assumes Agent needs hand-holding on a basic tool.

❌ "For each file in the config/ directory: (1) open file, (2) locate line starting with 'version:', (3) replace with 'version: 1.2.3', (4) save file, (5) verify line was replaced by reading file again."
- Agent knows how to edit a file and verify the change.
- Over-specifying each micro-step wastes tokens and insults Agent's autonomy.

---

## Just Right (Agent Can Start & Finish)

✅ "Clone the GitHub repository to `/opt/app`, then verify the clone succeeded by checking that `/opt/app/README.md` exists."
- **What:** Clone and verify.
- **Where:** To `/opt/app`, from the repo URL.
- **How to verify:** Explicit, not ambiguous.
- **Agent can start immediately:** Yes, one clear sentence per step.

✅ "Update all version references in `config/versions.yaml` from `1.0.0` to `1.2.3`. Verify by running `./scripts/verify-versions.sh` and confirming it exits with code 0."
- **What:** Update version in one file, verify with a script.
- **Agent can do this alone:** Yes.
- **Enough detail:** Yes (filename, exact old/new versions, verification script).
- **Not over-detailed:** No (doesn't say "open file with vim" or "grep for 1.0.0").

✅ "Run unit tests with `npm test`. If tests pass (exit code 0), log the result to `test-results.log` and proceed to the next task. If tests fail (exit code 1), review the error output and attempt a fix (consult `tests/README.md` for common failures). If you fix it, re-run tests. If you can't fix it within 2 attempts, @CEO with the full error output."
- **What:** Run tests, handle pass/fail.
- **Conditional branching:** Clear (pass → proceed; fail → debug; can't fix → escalate).
- **Agent autonomy:** High (Agent tries 2x before asking).
- **Not over-specified:** Doesn't say "press Enter 3 times" or "wait 5 seconds for npm to load."

✅ "Backup the current database to `/backups/db-backup-$(date +%Y%m%d).sql` before making schema changes. If backup creation fails, stop and @CEO with the error."
- **What:** Backup with timestamp, fail safely.
- **Concrete enough:** Yes (backup path, timestamp format, failure action).
- **Agent can execute:** Yes, without guessing.

---

## Decision Tree

When writing a step:

1. **Can Agent start this immediately?** (Yes → keep; No → too coarse, add detail)
2. **Does Agent know what "done" looks like?** (Yes → keep; No → add verification)
3. **Is there a tool/library Agent should use?** (Yes → name it; No → it's implicit)
4. **Are there error cases Agent should handle first?** (Yes → list them; No → assume happy path)
5. **Is this step a 1–2 sentence or a paragraph?** (1–2 sentences → probably right; Paragraph → probably too fine)

---

## Token Budget Correlation

- Coarse steps → Agent asks for clarification (costs iterations)
- Fine steps → Agent spends iterations reading unnecessary detail
- Right-sized steps → Agent executes in 1–2 iterations per step

