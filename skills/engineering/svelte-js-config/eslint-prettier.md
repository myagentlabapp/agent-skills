# ESLint + Prettier Integration

## The Problem

ESLint and Prettier can fight over formatting. ESLint has formatting rules (indent, quotes, semi). Prettier has opinions about the same things. If both are active, you get conflicting errors.

## Three Packages: Different Jobs

### `eslint-config-prettier`

**Turns OFF** ESLint rules that conflict with Prettier. Does nothing else. Must be imported and placed **last** in config array to override earlier configs.

```js
// flat config (eslint.config.js)
import eslintConfigPrettier from 'eslint-config-prettier/flat'

export default [
  js.configs.recommended,
  tseslint.configs.recommended,
  eslintConfigPrettier // LAST — overrides formatting rules from above
]
```

**When needed:** Only if ESLint configs above it enable formatting rules. Legacy configs (`airbnb`, `standard`) do. Modern `recommended` configs do not.

**When NOT needed:** If `pnpm exec eslint-config-prettier src/some-file.js` reports "No rules that are unnecessary or conflict with Prettier were found."

**If installed but not imported:** Zero effect. Safe to remove.

### `eslint-plugin-prettier`

Runs Prettier **as an ESLint rule**. Reports formatting differences as ESLint errors.

```js
import prettier from 'eslint-plugin-prettier'

export default [
  {
    plugins: { prettier },
    rules: { 'prettier/prettier': 'warn' } // or 'off' to just register plugin
  }
]
```

**Generally not recommended.** Slower than running Prettier separately. Worse editor experience, red squiggles for formatting. Prefer running Prettier via format-on-save or `prettier --check` in CI.

**Pattern seen in the wild:** Register plugin but disable rule (`'prettier/prettier': 'off'`). Registers Prettier as plugin without running it as linter. Unclear benefit, possibly leftover from migration.

### `svelte.configs.prettier` (built into `eslint-plugin-svelte`)

Disables Svelte-specific rules that conflict with Prettier. Same concept as `eslint-config-prettier` but scoped to `eslint-plugin-svelte` rules only.

```js
import svelte from 'eslint-plugin-svelte'

export default [
  svelte.configs.recommended,
  svelte.configs.prettier // disables svelte formatting rules
]
```

## Verification

```sh
# Check if ANY active rules conflict with Prettier
pnpm exec eslint-config-prettier src/some-file.js
pnpm exec eslint-config-prettier src/components/Example.svelte
pnpm exec eslint-config-prettier src/pages/index.astro

# Check which rules are active (look for formatting rules)
pnpm exec eslint --print-config src/some-file.js | grep -i "indent\|quotes\|semi\|comma\|spacing"
```

## Flat Config Pattern: Astro + Svelte + TS

Two real-world flat-config examples.

### Minimal (no prettier plugin, no a11y)

```js
import eslintPluginAstro from 'eslint-plugin-astro'
import eslintPluginSvelte from 'eslint-plugin-svelte'
import tsParser from '@typescript-eslint/parser'
import * as depend from 'eslint-plugin-depend'

export default [
  ...eslintPluginAstro.configs['flat/recommended'],
  ...eslintPluginSvelte.configs['flat/recommended'],
  depend.configs['flat/recommended'],
  {
    files: ['**/*.svelte', '**/*.svelte.ts', '**/*.svelte.js'],
    languageOptions: {
      parserOptions: { parser: tsParser, extraFileExtensions: ['.svelte'] }
    }
  },
  {
    files: ['**/*.ts'],
    languageOptions: { parser: tsParser }
  }
]
```

### Full (defineConfig, a11y, prettier plugin disabled, globals)

```js
import { defineConfig } from 'eslint/config'
import globals from 'globals'
import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import astro from 'eslint-plugin-astro'
import svelte from 'eslint-plugin-svelte'
import prettier from 'eslint-plugin-prettier'

const tsParser = tseslint.parser
const astroParser = astro.parser

export default defineConfig([
  // defineConfig() flattens nested config arrays, so array presets (tseslint/astro configs.recommended) need no ... spread
  { languageOptions: { globals: { ...globals.browser, ...globals.node } } },
  js.configs.recommended,
  tseslint.configs.recommended,
  { plugins: { prettier }, rules: { 'prettier/prettier': 'off' } },
  {
    files: ['**/*.ts', '**/*.tsx'],
    rules: { '@typescript-eslint/no-unused-vars': ['warn', { varsIgnorePattern: '^_' }] }
  },
  astro.configs.recommended,
  astro.configs['jsx-a11y-recommended'],
  {
    files: ['**/*.astro'],
    languageOptions: {
      parser: astroParser,
      parserOptions: {
        parser: tsParser, extraFileExtensions: ['.astro'],
        sourceType: 'module', ecmaVersion: 'latest'
      }
    },
    rules: { 'no-undef': 'off', '@typescript-eslint/no-explicit-any': 'warn' }
  },
  svelte.configs.recommended,
  {
    files: ['**/*.svelte'],
    languageOptions: { parserOptions: { parser: tsParser } },
    rules: {
      'svelte/no-at-html-tags': 'off',
      '@typescript-eslint/no-unused-expressions': 'warn'
    }
  },
  // *.svelte.ts = TS runes modules, NOT SFCs
  // svelte-eslint-parser breaks on TS-only syntax like #field: Type
  {
    files: ['**/*.svelte.ts'],
    languageOptions: {
      parser: tsParser,
      parserOptions: { ecmaVersion: 'latest', sourceType: 'module' }
    }
  },
  { ignores: ['dist/**', '**/*.d.ts', '.github/'] }
])
```

### Key: `*.svelte.ts` needs its own config block

Svelte 5 runes modules (`*.svelte.ts`, `*.svelte.js`) are pure TS/JS. `svelte-eslint-parser` breaks on TS-only syntax like private fields (`#field: Type`). Give them a separate block with `tsParser` directly.

## Stylelint: `config-recommended` vs `config-standard`

| Config | What it includes |
| --- | --- |
| `stylelint-config-recommended` | Error-prevention rules only (duplicate selectors, invalid values) |
| `stylelint-config-standard` | Everything in recommended + stylistic conventions (hex length, shorthand, color notation) |

`standard` requires more rule overrides to disable opinions you don't want. If you null out most stylistic rules, switch to `recommended`.

## Resources

- [You Probably Don't Need eslint-config-prettier](https://www.joshuakgoldberg.com/blog/you-probably-dont-need-eslint-config-prettier-or-eslint-plugin-prettier/): Josh Goldberg
- [ESLint discussion #17971](https://github.com/eslint/eslint/discussions/17971): maintainer consensus
- [eslint-config-prettier repo](https://github.com/prettier/eslint-config-prettier): official docs, CLI checker, flat config
- [Prettier: Integrating with Linters](https://prettier.io/docs/integrating-with-linters): official recommendation
- [eslint-plugin-svelte user guide](https://sveltejs.github.io/eslint-plugin-svelte/user-guide/): svelte.configs.prettier docs
