---
name: er-bundle
description: "Use this skill when the user wants to turn SQL DDL or design Markdown into a long-lived ER design bundle (.erd.json) that drives an interactive web page — not a one-shot Mermaid snippet. Trigger when the request mentions an ER / entity-relationship diagram together with color-coded layers / sub-domains, multiple diagram views of the same schema, a write-flow / data-flow narrative, or an old-vs-new design decision log. Also trigger when the user asks to update an existing .erd.json, to render / preview / view an existing bundle as HTML, or anything matching erd-bundle.schema.json. Do NOT trigger for pure 'draw a quick ER diagram' requests — Mermaid erDiagram is faster for that."
---

# er-bundle — ER design bundle workflow

## What you produce

**Primary output**: a JSON file conforming to `references/schema.json` (conventional extension `.erd.json`).

**Secondary output** (produce by default unless the user explicitly only wants the JSON): inject the bundle into the bundled `examples/demo.html` template to produce a standalone interactive HTML viewer. Run `scripts/render_html.py` and open the result — the user should not have to drop to a terminal for this step.

## Why a bundle instead of Mermaid

| Need | bundle | Mermaid `erDiagram` |
|---|---|---|
| Color-coded layers | ✅ | ❌ |
| Multiple views of the same schema | ✅ `diagrams[]` | Manual: split into multiple code blocks |
| Flow cards / write paths | ✅ `dataFlows` | ❌ |
| Old-vs-new design decision logs | ✅ `designDecisions` | ❌ |
| Custom coordinates + localStorage drag memory | ✅ `positions` | ❌ |
| Renders natively on GitHub | ❌ needs a host page | ✅ |

**Rule of thumb**: static diagram in a README → Mermaid. Product design doc, evolves over time, multiple audiences → this skill.

## Workflow

1. **Read the schema**: `references/schema.json` lists required and optional fields. **Read it once before starting** — recent additions (`tableConstraints` / `onDelete` / `cardinality` / `enumValues`) are easy to miss.
2. **Parse the input** (SQL DDL or Markdown) and extract:
   - Table names, columns, types
   - Single-column PK / FK / UQ → `cols[*].tag`
   - Composite PK / UQ, INDEX, CHECK → `tableConstraints`
   - `NOT NULL` → `nullable: false`; `DEFAULT` → `default` (preserve SQL literal verbatim, including quotes or function names)
   - FK actions `ON DELETE` / `ON UPDATE` → matching column fields
   - Enums (from CHECK constraints or comments) → `enumValues`
3. **Layers and status**: choose semantic groupings, fill `layers` with colors; for each table set `layer` / `status` (`existing` / `new` / `future`) / `comment`.
4. **Each diagram**: `diagrams[]` should have at least one "full view"; add sub-domain diagrams when there are many tables. `connections.label` is usually the FK column name. Set `cardinality`:
   - FK column **NOT NULL** → `"1:N"` (or `"1:1"` if the column is also UNIQUE)
   - FK column **nullable** → `"0:N"` (or `"0:1"`) — represents an optional upstream
   - Many-to-many junction tables → draw `"1:N"` from the junction to each side
   - Reference: [examples/team.erd.json](examples/team.erd.json) — users / teams mutually optional, demonstrates `0:1` and `0:N` naturally
   - **`dashed: true`** is only for "logical relations, not physical FKs" (e.g., reverse self-references, cross-service logical refs, semantically-present-but-not-yet-implemented relations). For a regular FK, **do not** set `dashed`; the rendering default is solid.
   - **`isNew: true`** is only for "diff views" (this bundle vs. a previous version, highlighting newly added relations). On a first-time bundle, **do not** mark every connection with `isNew` — that erases the highlight.
5. **Coordinates**: see `references/layout-heuristics.md`.
6. **(Optional)** Fill in `dataFlows` (write paths, actor → action) and `designDecisions` (old vs. v3). Reference: `examples/ecommerce.erd.json`.
7. **Validate**: `python3 scripts/validate.py <your-bundle>.json`. **Mandatory** — do not deliver if it fails.
8. **Render preview** (proactive, no terminal for the user): once the bundle validates, **render an HTML preview and open it** unless the user has explicitly said they only want the JSON. Run:
   ```bash
   python3 <skill-path>/scripts/render_html.py <bundle.json> -o /tmp/<bundle-stem>.html && open /tmp/<bundle-stem>.html
   ```
   If the user later says they want to re-render (e.g. after editing the JSON manually), do the same — they should never need to drop to a terminal for this.

## Anti-patterns (common mistakes)

- ❌ `connections` `from` / `to` references a table not in `tables` → schema doesn't catch it, but the host page breaks. **Cross-check yourself.**
- ❌ Missing a table from `positions` → that table won't appear on the diagram. Each `diagram`'s `positions` keys must cover every table to be shown.
- ❌ `tables[*].layer` points at a non-existent layer key → schema doesn't catch it, but the host page can't find a color and crashes.
- ❌ Marking every column of a composite PK with `tag: "PK"` → semantically wrong. Composite keys go in `tableConstraints` **only**.
- ❌ Writing `default: active` when you meant `default: 'active'` → invalid JSON or wrong semantics. `default` is a string holding the SQL literal verbatim (including quotes or function names).
- ❌ Setting `dashed: true` or `isNew: true` on every connection → drains the meaning. `dashed` = logical relation; `isNew` = diff view only. Regular FKs need neither.

## Reference files

- `references/schema.json` — authoritative JSON Schema
- `references/layout-heuristics.md` — coordinate rules
- `examples/minimal.erd.json` — smallest example (two tables, one edge)
- `examples/ecommerce.erd.json` — full example (7 tables, 2 views, `dataFlows` + `designDecisions`)
- `examples/ecommerce.sql` — the DDL that derives it
- `examples/team.erd.json` — 0:1 / 0:N example (optional relations)
- `examples/team.sql` — the DDL that derives it
- `scripts/validate.py` — schema + cross-check validator
