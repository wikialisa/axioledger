/**
 * @axioledger/cli (binary entry)
 *
 * Bootstrap the root CLI program.
 */
import { Command } from '@axioledger/cli-engine';
import { logger } from '@axioledger/cli-engine';

const program = new Command()
  .name('axq')
  .description('Axioledger workspace CLI')
  .version('0.1.0');

program.command('scaffold').description('Scaffold a new workspace package').action(() => {
  logger.info('scaffold — coming soon');
});

program.command('migrate').description('Run pending migrations').action(() => {
  logger.info('migrate — coming soon');
});

program.parseAsync(process.argv).catch((err) => {
  logger.error(String(err));
  process.exit(1);
});
