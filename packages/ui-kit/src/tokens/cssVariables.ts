/**
 * ui — CSS Custom Properties (Design Tokens as CSS variables)
 * Usage: import 'ui/styles' in your app root.
 *
 * All values map 1-to-1 to the TS token files.
 */
const AXVN_CSS_VARIABLES = `
:root {
  /* ── Brand colors ─────────────────────────────────────────── */
  --AXVN-color-dark:       #000000;
  --AXVN-color-white:      #FFFFFF;
  --AXVN-color-info:       #0095FF;
  --AXVN-color-success:    #00D68F;
  --AXVN-color-warning:    #FFAA00;
  --AXVN-color-error:      #FF3D71;
  --AXVN-color-greyscale:  #2E3A59;

  /* ── Brand palette ─────────────────────────────────────────── */
  --AXVN-brand-dark:       #000000;
  --AXVN-brand-grey:       #EFEFEF;
  --AXVN-brand-magenta:    #FD9FDD;
  --AXVN-brand-orange:     #FC7339;
  --AXVN-brand-greeny:     #BEFF6C;
  --AXVN-brand-violet:     #AF96FB;
  --AXVN-brand-blue:       #49DBC8;
  --AXVN-brand-yellow:     #FFF172;

  /* ── Background ────────────────────────────────────────────── */
  --AXVN-bg-surface:       #FFFFFF;
  --AXVN-bg-muted:         #F5F6FA;
  --AXVN-bg-violet:        #AF96FB;
  --AXVN-bg-pink:          #FD9FDD;
  --AXVN-bg-greeny:        #BEFF6C;
  --AXVN-bg-yellow:        #FFF172;
  --AXVN-bg-orange:        #FC7339;

  /* ── Greyscale shades ─────────────────────────────────────── */
  --AXVN-grey-900: #000000;
  --AXVN-grey-800: #1A1F36;
  --AXVN-grey-700: #2E3A59;
  --AXVN-grey-600: #4A5568;
  --AXVN-grey-500: #718096;
  --AXVN-grey-400: #A0AEC0;
  --AXVN-grey-300: #CBD5E0;
  --AXVN-grey-100: #EDF2F7;

  /* ── Typography ────────────────────────────────────────────── */
  --AXVN-font-base:    'Work Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --AXVN-fw-regular:   400;
  --AXVN-fw-medium:    500;
  --AXVN-fw-semibold:  600;

  --AXVN-fs-h1:        6rem;
  --AXVN-fs-h2:        3.75rem;
  --AXVN-fs-h3:        3rem;
  --AXVN-fs-h4:        2.125rem;
  --AXVN-fs-h5:        1.5rem;
  --AXVN-fs-h6:        1.25rem;
  --AXVN-fs-subtitle1: 1rem;
  --AXVN-fs-subtitle2: 0.875rem;
  --AXVN-fs-body1:     1rem;
  --AXVN-fs-body2:     0.875rem;
  --AXVN-fs-caption:   0.75rem;
  --AXVN-fs-overline:  0.625rem;
  --AXVN-fs-btn-giant: 1.25rem;
  --AXVN-fs-btn-large: 1rem;
  --AXVN-fs-btn-md:    0.875rem;
  --AXVN-fs-btn-sm:    0.75rem;

  /* ── Spacing (base 4px) ────────────────────────────────────── */
  --AXVN-space-1:  4px;
  --AXVN-space-2:  8px;
  --AXVN-space-3:  12px;
  --AXVN-space-4:  16px;
  --AXVN-space-5:  20px;
  --AXVN-space-6:  24px;
  --AXVN-space-8:  32px;
  --AXVN-space-10: 40px;
  --AXVN-space-12: 48px;
  --AXVN-space-16: 64px;

  /* ── Border radius ─────────────────────────────────────────── */
  --AXVN-radius-sm:   4px;
  --AXVN-radius-md:   8px;
  --AXVN-radius-lg:   12px;
  --AXVN-radius-xl:   16px;
  --AXVN-radius-2xl:  24px;
  --AXVN-radius-full: 9999px;

  /* ── Shadows ───────────────────────────────────────────────── */
  --AXVN-shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
  --AXVN-shadow-md: 0 4px 12px rgba(0,0,0,0.10);
  --AXVN-shadow-lg: 0 8px 24px rgba(0,0,0,0.12);
  --AXVN-shadow-xl: 0 16px 48px rgba(0,0,0,0.16);
}

@keyframes AXVN-skeleton {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
`;

/** Inject CSS variables into <head>. Call once at app root. */
export function injectAXVNTokens(): void {
  if (typeof document === "undefined") return;
  const id = "AXVN-tokens";
  if (document.getElementById(id)) return;
  const style = document.createElement("style");
  style.id = id;
  style.textContent = AXVN_CSS_VARIABLES;
  document.head.appendChild(style);
}

export { AXVN_CSS_VARIABLES };
