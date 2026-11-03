/**
 * @axioledger/ui-runtime
 *
 * Base component context, reconciler binding and shared state primitives.
 * All UI packages should depend on this library rather than importing
 * React directly, ensuring a single reconciler instance across the monorepo.
 */
export {
  createContext,
  useContext,
  useState,
  useEffect,
  useRef,
  useCallback,
  useMemo,
  useReducer,
  forwardRef,
  memo,
  Fragment,
  createElement,
  type ReactNode,
  type ReactElement,
  type FC,
  type PropsWithChildren,
  type Ref,
} from 'react';
export { createRoot, hydrateRoot } from 'react-dom/client';

// ── Shared context primitives ─────────────────────────────────────────────────

export interface ThemeContextValue {
  colorScheme: 'light' | 'dark' | 'system';
  setColorScheme: (scheme: 'light' | 'dark' | 'system') => void;
}

export interface LocaleContextValue {
  locale: string;
  setLocale: (locale: string) => void;
}
