/**
 * ui — CSS Custom Properties (Design Tokens as CSS variables)
 * Usage: import 'ui/styles' in your app root.
 *
 * All values map 1-to-1 to the TS token files.
 */
const YOUR_TOKEN_CSS_VARIABLES = `
:root {
  /* ── Brand colors ─────────────────────────────────────────── */
  --YOUR_TOKEN-color-dark:       #000000;
  --YOUR_TOKEN-color-white:      #FFFFFF;
  --YOUR_TOKEN-color-info:       #0095FF;
  --YOUR_TOKEN-color-success:    #00D68F;
  --YOUR_TOKEN-color-warning:    #FFAA00;
  --YOUR_TOKEN-color-error:      #FF3D71;
  --YOUR_TOKEN-color-greyscale:  #2E3A59;

  /* ── Brand palette ─────────────────────────────────────────── */
  --YOUR_TOKEN-brand-dark:       #000000;
  --YOUR_TOKEN-brand-grey:       #EFEFEF;
  --YOUR_TOKEN-brand-magenta:    #FD9FDD;
  --YOUR_TOKEN-brand-orange:     #FC7339;
  --YOUR_TOKEN-brand-greeny:     #BEFF6C;
  --YOUR_TOKEN-brand-violet:     #AF96FB;
  --YOUR_TOKEN-brand-blue:       #49DBC8;
  --YOUR_TOKEN-brand-yellow:     #FFF172;

  /* ── Background ────────────────────────────────────────────── */
  --YOUR_TOKEN-bg-surface:       #FFFFFF;
  --YOUR_TOKEN-bg-muted:         #F5F6FA;
  --YOUR_TOKEN-bg-violet:        #AF96FB;
  --YOUR_TOKEN-bg-pink:          #FD9FDD;
  --YOUR_TOKEN-bg-greeny:        #BEFF6C;
  --YOUR_TOKEN-bg-yellow:        #FFF172;
  --YOUR_TOKEN-bg-orange:        #FC7339;

  /* ── Greyscale shades ─────────────────────────────────────── */
  --YOUR_TOKEN-grey-900: #000000;
  --YOUR_TOKEN-grey-800: #1A1F36;
  --YOUR_TOKEN-grey-700: #2E3A59;
  --YOUR_TOKEN-grey-600: #4A5568;
  --YOUR_TOKEN-grey-500: #718096;
  --YOUR_TOKEN-grey-400: #A0AEC0;
  --YOUR_TOKEN-grey-300: #CBD5E0;
  --YOUR_TOKEN-grey-100: #EDF2F7;

  /* ── Typography ────────────────────────────────────────────── */
  --YOUR_TOKEN-font-base:    'Work Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --YOUR_TOKEN-fw-regular:   400;
  --YOUR_TOKEN-fw-medium:    500;
  --YOUR_TOKEN-fw-semibold:  600;

  --YOUR_TOKEN-fs-h1:        6rem;
  --YOUR_TOKEN-fs-h2:        3.75rem;
  --YOUR_TOKEN-fs-h3:        3rem;
  --YOUR_TOKEN-fs-h4:        2.125rem;
  --YOUR_TOKEN-fs-h5:        1.5rem;
  --YOUR_TOKEN-fs-h6:        1.25rem;
  --YOUR_TOKEN-fs-subtitle1: 1rem;
  --YOUR_TOKEN-fs-subtitle2: 0.875rem;
  --YOUR_TOKEN-fs-body1:     1rem;
  --YOUR_TOKEN-fs-body2:     0.875rem;
  --YOUR_TOKEN-fs-caption:   0.75rem;
  --YOUR_TOKEN-fs-overline:  0.625rem;
  --YOUR_TOKEN-fs-btn-giant: 1.25rem;
  --YOUR_TOKEN-fs-btn-large: 1rem;
  --YOUR_TOKEN-fs-btn-md:    0.875rem;
  --YOUR_TOKEN-fs-btn-sm:    0.75rem;

  /* ── Spacing (base 4px) ────────────────────────────────────── */
  --YOUR_TOKEN-space-1:  4px;
  --YOUR_TOKEN-space-2:  8px;
  --YOUR_TOKEN-space-3:  12px;
  --YOUR_TOKEN-space-4:  16px;
  --YOUR_TOKEN-space-5:  20px;
  --YOUR_TOKEN-space-6:  24px;
  --YOUR_TOKEN-space-8:  32px;
  --YOUR_TOKEN-space-10: 40px;
  --YOUR_TOKEN-space-12: 48px;
  --YOUR_TOKEN-space-16: 64px;

  /* ── Border radius ─────────────────────────────────────────── */
  --YOUR_TOKEN-radius-sm:   4px;
  --YOUR_TOKEN-radius-md:   8px;
  --YOUR_TOKEN-radius-lg:   12px;
  --YOUR_TOKEN-radius-xl:   16px;
  --YOUR_TOKEN-radius-2xl:  24px;
  --YOUR_TOKEN-radius-full: 9999px;

  /* ── Shadows ───────────────────────────────────────────────── */
  --YOUR_TOKEN-shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
  --YOUR_TOKEN-shadow-md: 0 4px 12px rgba(0,0,0,0.10);
  --YOUR_TOKEN-shadow-lg: 0 8px 24px rgba(0,0,0,0.12);
  --YOUR_TOKEN-shadow-xl: 0 16px 48px rgba(0,0,0,0.16);
}

@keyframes YOUR_TOKEN-skeleton {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
`;

/** Inject CSS variables into <head>. Call once at app root. */
export function injectYOUR_TOKENTokens(): void {
  if (typeof document === "undefined") return;
  const id = "YOUR_TOKEN-tokens";
  if (document.getElementById(id)) return;
  const style = document.createElement("style");
  style.id = id;
  style.textContent = AXVN_CSS_VARIABLES;
  document.head.appendChild(style);
}

export { AXVN_CSS_VARIABLES };
