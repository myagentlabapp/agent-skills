# Gap-Filling a Doc Chain with Authoring Skills (worked example, 2026-08-16)

How to upgrade an existing project doc chain (需求/设计/架构/test/上线) using the
content-authoring skills rather than only re-publishing.

## Setup

- Loaded authoring skills: `prd`, `architecture-blueprint-generator`,
  `documentation-and-adrs`, `documentation-writer` — plus publishing skills
  `wiki-page-authoring`, `wiki-maintenance-and-file-io`.
- Target doc: `departments/infrastructure/docs/plans/tokenbom-style-marketplace`
  (TokenBom quota-marketplace). 16161 chars → 20087 chars after gap-fill.

## Gap-detection method

Run each existing section against its authoring skill's schema. Concrete greps to
find the holes (do NOT rely on "I think the doc is fine"):

```bash
wiki get <path> | sed -n '/--- Content ---/,$p' | sed '1d' > /opt/data/gap.md
for kw in "用户故事" "As a" "验收标准" "KPI" "成功指标" "Non-Goal" "非目标" "ADR" "决策记录" "架构图" "C4"; do
  echo "$kw: $(grep -c "$kw" /opt/data/gap.md)"
done
```

Zero on all of these = the doc has natural-language goals but no testable spec
and no decision record. That is the gap.

## What was added (per skill)

1. **`prd` → 需求规格 subsection** in the 目标 section:
   - 角色 line (提供者/开发者/平台管理员).
   - `US-1..N` table: ID | 用户故事 (As a [user], I want [action] so that [benefit]) | 验收标准(可测).
   - `Non-Goals` list (explicit "we are NOT building X" to prevent scope creep —
     separate from a Phase-1 边界 list).
   - `成功标准 KPI` table (dimension | metric | 达标线) — measurable, not "should work well".
2. **`documentation-and-adrs` → §8.9 ADR 决策记录**:
   - Replaced the old "技术评审待定项" checklist with a "最终决策" table (all resolved).
   - Added numbered `ADR-00x` blocks, each with: Status / Context / Decision /
     Alternatives (with per-alternative reject reasons) / Consequences.
   - ADR is the highest-value addition — records WHY a decision was made and
     what was rejected, which code/docs never capture.
3. **`architecture-blueprint-generator` → 决策表**: convert pending infra choices
   (SQLite vs Postgres, 官方镜像 vs 魔改, 域名, 定价策略) into a resolved-decision table.

## Verification before push (publishing-skill discipline)

- `grep -c '^#'` count of headings; confirm added anchors present AND every
  pre-existing section anchor still present (0 loss).
- Push with `wiki push <path> <file.md>` (file-arg form), then re-`wiki get` and
  `grep -c '<new-anchor>'` to confirm ≥1.
- Do NOT use `wiki get > file` as the editable source (metadata head pollutes content).

## Pitfall hit

Treated generic methodology skills (plan-process / wiki-lifecycle-management) as
if they covered content writing → got corrected "写文档你不用写文档的skill那是在乱搞？".
Fix: pull BOTH halves (authoring + publishing) for doc tasks; don't invent
content from memory when a `prd`/`architecture-blueprint-generator` schema exists.
