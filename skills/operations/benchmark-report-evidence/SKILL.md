---
name: benchmark-report-evidence
description: "Defend benchmark reports with verifiable evidence chains."
version: 0.1.0
author: Hermes
metadata:
  hermes.tags:
    - Benchmark
    - Evidence
    - Wiki
    - Quality
---
# Benchmark Report Evidence Chain

Produce and defend benchmark/evaluation reports where every data point traces to a verifiable source. When a reader challenges "is this fabricated?", you produce raw evidence on the spot — not explanations.

## When to Use

- Writing a benchmark, comparison, or evaluation report for Wiki
- A reader challenges methodology ("what exactly did you test?")
- A reader challenges data authenticity ("did you make this up?")
- Reviewing/improving an existing report that lacks reproducibility
- CEO asks "依据呢？" (where's your evidence?)

## Prerequisites

- Test artifacts saved to disk with timestamps (not deleted after testing)
- Tool databases accessible (SQLite, log files) for token/cost extraction
- `wiki push` / `wiki pull` for publishing and verifying
- A venv with pytest installed for live re-verification

## How to Run

1. Write the report with a complete methodology section (see Procedure).
2. Push to Wiki, then pull back and verify structure.
3. When challenged on methodology: show the exact test prompt, environment, commands, and judgment criteria.
4. When challenged on data authenticity: produce raw evidence via `terminal` tool — file listings, live test runs, database queries.
5. Clearly label estimated vs measured data. Never present estimates as measurements.

## Quick Reference

```
# File existence with timestamps
ls -la --time-style=full-iso <artifact-dir>/*

# Live re-run of tool-produced tests
/tmp/bench-venv/bin/python -m pytest test_todo.py -q

# Token data from tool databases
python3 -c "import sqlite3; ..."

# Push and verify Wiki page
wiki push <path> <file> && wiki pull <path>
```

## Procedure

### 1. Methodology Section — 6 Mandatory Subsections

A benchmark report's methodology section is insufficient if it cannot be reproduced. Include ALL of:

1. **测试题（逐字原文）**: The exact prompt every subject received, verbatim. No paraphrasing. Add translation and a breakdown of what capabilities it tests.
2. **统一环境**: Model, API key, OS, runtime versions, working directories, execution method (parallel/serial). Every value specific, not "latest" or "standard".
3. **每个工具的具体执行命令**: The real launch command for each tool. Include config notes (which env vars, which config files, which flags were needed).
4. **判定标准**: What counts as pass/fail. How timing was measured. Where token data came from. How quality was assessed.
5. **测试的局限与已知偏差**: Honest disclosure — post-fix results, estimated values, suspicious readings, parallel competition effects, test difficulty level, CLI-vs-real-form gaps. This is the section that builds trust.
6. **决策过程**: Why this model/method was chosen, what alternatives were tried and abandoned, what went wrong in earlier rounds.

### 2. Publishing and Verifying

- Edit the report file locally (e.g., `/tmp/report.md`).
- Push: `wiki push <wiki-path> <file>` via `terminal` tool.
- Verify: `wiki pull <wiki-path>` and check section structure (row counts, key terms present).

### 3. Defending Data Authenticity (When Challenged)

Produce evidence in this order — each step is a `terminal` call:

**Step A — Prove artifacts exist with timestamps:**
```
ls -la --time-style=full-iso <test-dir>/*.py
```
Timestamps should match the reported test execution window.

**Step B — Prove different tools generated different code:**
Show file headers (first 3 lines of each tool's output). Different tools produce different docstrings, imports, and structures — proves they weren't copy-pasted.

**Step C — Live re-run the tests:**
```
cd <test-dir> && /tmp/bench-venv/bin/python -m pytest test_todo.py -q
```
Real pytest output with pass counts. Strongest proof — machine-generated, reproducible right now.

**Step D — Query token data from databases:**
```python
import sqlite3
conn = sqlite3.connect('<tool-db-path>')
c = conn.cursor()
c.execute("SELECT tokens_input, tokens_output FROM ...")
print(c.fetchone())
```
Machine data from the tool's own storage — not handwritten.

**Step E — Classify every data point:**
| Classification | Meaning | Action |
|---|---|---|
| Measured | Machine-recorded, queryable now | Show the query |
| Estimated | Calculated from indirect signals | Label clearly in report |
| Suspicious | Recorded value doesn't match reality | Flag in report's limitations |

### 4. Evidence Labels in the Report

Every data table should have a source column or note:
- `实测`: Ran the command, got this output
- `SQLite查询`: Queried the tool's local database
- `日志解析`: Parsed from tool's log output
- `估算`: Calculated from indirect data, not directly recorded
- `修复后`: Result after manual fix (always note the original value too)

## Pitfalls

- **Thin methodology = zero credibility**: An 8-line methodology section invites "你到底测了什么" challenges. Write it so a stranger can reproduce the test from it alone.
- **Mixing measured and estimated without labels**: If even one number is estimated but presented as measured, the entire report's credibility collapses when discovered.
- **Deleting artifacts after testing**: Keep all product files, databases, and logs on disk. They are your evidence chain. Without them, you can only argue — not prove.
- **Post-fix results presented as raw**: If you fixed a tool's bug and re-ran, always disclose the original result. Hiding it = fabrication by omission.
- **Parallel test interference**: Running N tools simultaneously on the same API key creates competition. Document this as a limitation.
- **Tool-reported metrics can be buggy**: Cross-check implausible values (e.g., completion_tokens=40 for 124 lines of code).

## Verification

The report is defensible if, when challenged on any single data point, you can produce a raw machine artifact (file, database row, or live test run) within one `terminal` call that matches the reported value. If you cannot, that data point must be labeled "估算" or "待验证" in the report.
