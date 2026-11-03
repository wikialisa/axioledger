/**
 * @axioledger/cli-engine
 *
 * Internal CLI development framework. Provides:
 *  - Command parsing via Commander.js
 *  - Interactive terminal prompts via Inquirer.js
 *  - Coloured, levelled logger via Chalk
 */
export { Command, Option, Argument } from 'commander';
export type { OptionValues } from 'commander';

export { default as inquirer } from 'inquirer';

import chalk from 'chalk';

// ── Levelled logger ───────────────────────────────────────────────────────────

export const logger = {
  info:    (msg: string) => console.log(chalk.cyan('  info ') + msg),
  success: (msg: string) => console.log(chalk.green('   ok  ') + msg),
  warn:    (msg: string) => console.warn(chalk.yellow('  warn ') + msg),
  error:   (msg: string) => console.error(chalk.red(' error ') + msg),
  debug:   (msg: string) => console.debug(chalk.gray(' debug ') + msg),
} as const;

export { chalk };
