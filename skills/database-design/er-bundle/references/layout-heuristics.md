# Layout heuristics

The host page renders cards at `CARD_W = 214` and `CARD_H_APPROX = 172` pixels. `positions[table] = { cx, cy }` is the **center** of the card.

## Default grid

- Horizontal spacing: **`CARD_W × 1.4 ≈ 300`**
- Vertical spacing: **`CARD_H_APPROX × 1.6 ≈ 280`**
- Top / left margin: roughly `120` to `140`

## Layer by FK dependency

Arrange tables left-to-right by "what depends on what":

1. **Root tables** with no FKs (`accounts`, `products`) → leftmost column
2. **Tables that are referenced but reference nothing else** (`carts`) → middle column
3. **Aggregator tables that reference multiple others** (`orders`) → right column
4. **Detail / 1:N child tables** (`*_items`) → directly below the parent, `cy = parent_cy + 280`

## Canvas size

- `canvas.w` ≈ `(max x) + CARD_W/2 + 120`
- `canvas.h` ≈ `(max y) + CARD_H_APPROX/2 + 120`
- The margin gives connections room to route around cards — **do not** size to the exact bounding box.

## Multiple views (`diagrams[]`)

- **Full view**: all tables, canvas around `1100 × 560` for 7–10 tables.
- **Sub-domain view**: only 4–6 related tables, shrink canvas to ~`800 × 400`.
- **Flow view** (optional): only tables touched by a specific `dataFlow`; use `dashed: true` for logical (non-physical-FK) relations.

## Minimize line crossings

- Put **frequently-related** tables close together (e.g. `orders` ↔ `order_items` ↔ `products` form a triangle).
- Avoid connections that span the entire canvas. If unavoidable, **duplicate that table in another `diagram`** rather than forcing it onto one view.
- N:N junction tables usually sit **centered between** the two sides they bridge, or directly below.

## Anti-patterns

- ❌ Cramming every table into a single row → connections will inevitably cross.
- ❌ Round-number coordinates that don't fit the canvas (e.g. `cx: 900` on a 600-wide canvas) → cards get clipped off-canvas.
- ❌ Copying coordinates between diagrams → positions are per-diagram. A sub-domain view almost always needs a fresh layout.
