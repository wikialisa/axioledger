/**
 * @axioledger/frameworks
 *
 * SDK connector, plugin loader, dynamic module loader.
 * Depends on: @axioledger/core, @axioledger/validation
 */
import type { ZodSchema } from '@axioledger/validation';

export interface Plugin<TConfig = unknown> {
  name: string;
  configSchema?: ZodSchema<TConfig>;
  setup(config: TConfig): void | Promise<void>;
}

const registry = new Map<string, Plugin>();

export function registerPlugin<T>(plugin: Plugin<T>): void {
  registry.set(plugin.name, plugin as Plugin);
}

export function getPlugin(name: string): Plugin | undefined {
  return registry.get(name);
}
