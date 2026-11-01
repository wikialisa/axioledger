import { describe, it, expect } from 'vitest';
import { VERSION, PACKAGE } from '../src/index';

/**
 * Contract tests for @sequentichain/svm-adapter
 * Verifies the public surface area of the package entry point.
 */
describe('@sequentichain/svm-adapter', () => {
  it('exports PACKAGE name matching package.json', () => {
    expect(PACKAGE).toBe('@sequentichain/svm-adapter');
  });

  it('exports VERSION string in semver format', () => {
    expect(VERSION).toMatch(/^\d+\.\d+\.\d+/);
  });

  it('VERSION is not a placeholder (not 0.0.0)', () => {
    // Ensures the changeset bump has been applied before publishing
    expect(VERSION).not.toBe('0.0.0');
  });
});
