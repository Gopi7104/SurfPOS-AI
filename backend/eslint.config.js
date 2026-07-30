'use strict';

// ESLint flat config. See docs/08_ARCHITECTURE_DECISIONS.md § ADR-012 for why this project uses a
// lean custom ruleset (aligned to docs/07_CODING_RULES.md) plus eslint-config-prettier, rather than
// importing a large third-party style guide like Airbnb-base.

const js = require('@eslint/js');
const globals = require('globals');
const prettier = require('eslint-config-prettier');

module.exports = [
  {
    ignores: ['node_modules/**', 'coverage/**', 'src/logs/**'],
  },
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'commonjs',
      globals: {
        ...globals.node,
      },
    },
    rules: {
      // docs/07_CODING_RULES.md § 1 — no bare console.log, use utils/logger.js instead.
      'no-console': 'error',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-var': 'error',
      'prefer-const': 'error',
      eqeqeq: ['error', 'always'],
      'no-throw-literal': 'error',
    },
  },
  {
    files: ['tests/**/*.js', 'vitest.config.mjs'],
    languageOptions: {
      sourceType: 'module',
      globals: {
        ...globals.node,
      },
    },
  },
  {
    // Standalone CLI operator tools (docs/17_FOLDER_STRUCTURE.md) legitimately print to stdout —
    // the app's own utils/logger.js rule still applies to everything under src/.
    files: ['scripts/**/*.js'],
    rules: {
      'no-console': 'off',
    },
  },
  prettier,
];
