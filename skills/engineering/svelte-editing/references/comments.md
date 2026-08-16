# Comment survival test

The detail behind the comment rule in [SKILL.md](../SKILL.md). The body states the headline (default
DELETE, bounded by the never-remove rule); this file is the full test, ban-list, and procedure.

## Survival test

A comment you write or touch defaults to DELETE. The code already says WHAT, so a comment restating
WHAT is noise. It earns its place only if ALL hold:

1. **It teaches something the code cannot show**: a non-obvious invariant, a hidden constraint, a
   subtle race, a workaround for a specific external bug, a contract a future reader would otherwise
   violate.
2. **It still helps a reader fluent in the language.** A note narrating language mechanics a fluent
   reader already sees is noise; one explaining WHY unusual syntax exists is not.
3. **It will not become a lie within one refactor.** Anchor comments to invariants, not to history: a
   note about code that was removed dies on the next rename.
4. **It has no editorial filler** (see the ban-list below).
5. **It is at the right scale** (see the `/** */` rule in SKILL.md): multi-line rationale in a block,
   short notes inline.

A comment carrying information (a `HINT`/`TODO`/`FIXME` keyword, a cross-reference, a non-obvious WHY)
is protected by the never-remove rule, which outranks default-DELETE. Default-DELETE only ever
removes noise.

## Banned filler

Delete on sight: `per plan`, `per spec`, `per locked decision`, `fire-and-forget`, `for safety`,
`just in case`, `obviously`, `simply`, `basically`, `actually`, `of course`, `as you can see`,
`note that`, `this is`, `we use`, and any restated function name, parameter list, or return value.

Allowed: section anchors (`// request validation`) and inherited keywords (`HINT:`, `TODO:`,
`FIXME:`, cross-references).

## Procedure when editing

Judge each comment in the touched region against the test and delete the failures in the same edit,
one by one, not batched for later. Do not rewrite a weak comment to be "less bad": needing to rewrite
it is the signal it fails rule 1, so delete it. After the edit, re-read to confirm no orphan blank
lines or dangling `*` markers remain.

## Example

```typescript
// ❌ BAD: restates what void does
// fire-and-forget the unmount promise
void unmount(component);

// ❌ BAD: references removed code, becomes a lie on the next refactor
// no longer recomputes the radius on zoom

// ✅ GOOD: says WHY the unusual syntax exists
// svelte 5 unmount() is async, void satisfies no-floating-promises
void unmount(component);
```
