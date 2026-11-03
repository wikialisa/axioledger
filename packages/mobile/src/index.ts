/**
 * @axioledger/mobile
 *
 * Cross-platform runtime adapter — native storage bridge.
 * Depends on: @axioledger/ui-runtime, @axioledger/network
 */
export * from '@axioledger/ui-runtime';

/** Minimal async key/value storage contract — implementations differ per platform. */
export interface AsyncStorage {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
  removeItem(key: string): Promise<void>;
}
