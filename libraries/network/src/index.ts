/**
 * @axioledger/network
 *
 * Standardised HTTP client built on Axios.
 * Provides:
 *  - Auth-token injection via request interceptor
 *  - Exponential-backoff retry on transient failures
 *  - Rate-limiting header handler
 *  - Typed response parsing via Zod schema
 */
import axios, { type AxiosInstance, type AxiosRequestConfig } from 'axios';
import type { ZodSchema } from 'zod';

// ── Internal retry helper ─────────────────────────────────────────────────────

const RETRYABLE_STATUS = new Set([429, 502, 503, 504]);

function withRetry(instance: AxiosInstance, maxRetries = 3): void {
  instance.interceptors.response.use(undefined, async (error) => {
    const config = error.config as AxiosRequestConfig & { _retryCount?: number };
    const status: number = error.response?.status ?? 0;
    if (!RETRYABLE_STATUS.has(status)) throw error;

    config._retryCount = (config._retryCount ?? 0) + 1;
    if (config._retryCount > maxRetries) throw error;

    const delay = 2 ** config._retryCount * 100; // 200ms, 400ms, 800ms…
    await new Promise((r) => setTimeout(r, delay));
    return instance.request(config);
  });
}

// ── Factory ───────────────────────────────────────────────────────────────────

export interface NetworkClientOptions {
  baseURL: string;
  getToken?: () => string | null;
  maxRetries?: number;
}

export function createHttpClient(options: NetworkClientOptions): AxiosInstance {
  const instance = axios.create({ baseURL: options.baseURL });

  // Auth token injection
  if (options.getToken) {
    instance.interceptors.request.use((cfg) => {
      const token = options.getToken!();
      if (token) cfg.headers = { ...cfg.headers, Authorization: `Bearer ${token}` };
      return cfg;
    });
  }

  withRetry(instance, options.maxRetries ?? 3);
  return instance;
}

// ── Typed fetch utility ───────────────────────────────────────────────────────

export async function fetchTyped<T>(
  client: AxiosInstance,
  url: string,
  schema: ZodSchema<T>,
  config?: AxiosRequestConfig,
): Promise<T> {
  const { data } = await client.get(url, config);
  return schema.parse(data);
}

export { axios };
export type { AxiosInstance, AxiosRequestConfig };
