# Honeycomb grid: worked nesting example

A real-world-shaped walkthrough of the upfront-specificity-analysis workflow: a grid whose hover-desaturate rule crosses parent-child boundaries, where naive incremental nesting triggers cascading stylelint errors.

## Context

A component's `<style>` block (`HoneycombGrid.svelte`) uses flat selectors and must be nested with `&`. Incremental edits fail here because each edit shifts specificity ordering, triggering cascading stylelint errors. Plan the full ordering before editing.

## Constraints

Two stylelint rules (from `stylelint-config-standard`, not overridden in your `stylelint.config.js`):

- **`no-descending-specificity`**: selectors matching the SAME element must appear in ascending specificity in source order
- **`no-duplicate-selectors`**: no two rule blocks with the same resolved selector

## The problem

The desaturate rule `.honeycomb:has(:hover) .hex-wrapper:not(:has(:hover))` has specificity (0,4,0) and matches `.hex-wrapper` elements. It MUST appear after ALL other `.hex-wrapper`-matching selectors. But it is nested under `.honeycomb`. If the `.honeycomb` block comes first and the `.hex-wrapper` block second, the linter flags descending specificity.

## Solution

Put the `.hex-wrapper` block FIRST, the `.honeycomb` block SECOND. They target different elements, so source order between them does not trigger the linter. The desaturate rule inside `.honeycomb` at the end naturally comes after all `.hex-wrapper` selectors.

Nest `.hex-tile` and `.hex-label` inside `.hex-wrapper` (matching DOM hierarchy).

### Specificity order proof (selectors matching `.hex-wrapper`)

```
.hex-wrapper                           (0,1,0)  <- .hex-wrapper block start
.hex-wrapper:has(:hover)               (0,2,0)  <- &:has(:hover)
.hex-wrapper:nth-child(*)              (0,2,0)  <- mobile grid rules
.hex-wrapper:nth-child(*) @media       (0,2,0)  <- desktop grid rules
.hex-wrapper:first-child:nth-last-child(3)        (0,3,0)  <- special 3-item
.hex-wrapper:..~ .hex-wrapper:nth-child(2)        (0,4,0)  <- sibling in 3-item
.honeycomb:has(:hover) .hex-wrapper:not(:has(:hover))  (0,4,0)  <- desaturate (LAST)
```

### Specificity order proof (selectors matching `.hex-tile`)

```
.hex-wrapper .hex-tile                 (0,2,0)  <- & .hex-tile
.hex-wrapper:has(:hover) .hex-tile     (0,3,0)  <- ascending
.honeycomb:has(:hover) ...  .hex-tile  (0,5,0)  <- desaturate (LAST)
```

## Steps

1. **Run the component's existing tests as a baseline.** Expect all pass.
2. **Before measurement**: take pixel-perfect baselines on your dev server using `browser_evaluate` (getBoundingClientRect on `.honeycomb`, `.hex-wrapper`, `.hex-tile`).
3. **Replace the entire `<style>` block** with the nested version (one edit, not incremental).
4. **Run stylelint** on the component. Expect zero errors.
5. **Re-run the tests** (same command). Expect all pass with 0 failures.
6. **After measurement**: same measurements, compare side-by-side, expect 0px diff.
7. **Visual spot-check**: hover behaviour (scale, brightness, desaturate) still works.

## Target CSS

```css
.hex-wrapper {
    /* base */
    & .hex-tile {
        /* base */
        & .hex-label { /* base */ }
    }
    &:has(:hover) {
        /* hover state */
        & .hex-tile { filter: brightness(1.15); }
    }
    /* mobile nth-child */
    @media (width > 500px) {
        /* desktop nth-child, special layouts */
    }
}

.honeycomb {
    /* base + custom props */
    @media (width > 500px) { /* desktop overrides */ }
    /* desaturate: highest specificity, LAST */
    &:has(:hover) .hex-wrapper:not(:has(:hover)) {
        & .hex-tile { /* grayscale */ }
    }
}
```
