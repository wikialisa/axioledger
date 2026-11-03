/**
 * @axioledger/validation
 *
 * Schema-first validation engine. Re-exports Zod plus
 * project-wide helper utilities for schema composition.
 */
export { z, ZodError } from 'zod';
export type { ZodSchema, ZodTypeAny, infer as ZodInfer } from 'zod';

/**
 * Safely parse data against a schema, returning a discriminated-union result
 * instead of throwing — suitable for both server-side request parsing and
 * client-side form validation.
 */
export function safeParse<T>(
  schema: import('zod').ZodSchema<T>,
  data: unknown,
): { success: true; data: T } | { success: false; errors: import('zod').ZodError } {
  const result = schema.safeParse(data);
  if (result.success) return { success: true, data: result.data };
  return { success: false, errors: result.error };
}
