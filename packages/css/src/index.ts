/**
 * @axioledger/css
 *
 * Design token system, CSS variables engine, typography & layout resets.
 * Depends on: @axioledger/frontend
 */

/** Semantic design token names (mirrors tokens/variables.css). */
export const tokens = {
  colorPrimary: 'var(--color-primary)',
  colorSurface: 'var(--color-surface)',
  colorBorder:  'var(--color-border)',
  fontSans:     'var(--font-sans)',
  fontMono:     'var(--font-mono)',
  spacingUnit:  'var(--spacing-unit)',
} as const;

export type TokenKey = keyof typeof tokens;
