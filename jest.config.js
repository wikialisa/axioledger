/** @type {import('jest').Config} */
module.exports = {
  // Root-level jest config for E2E tests only.
  // Unit tests live in each workspace package (packages/*/jest.config.js).
  testMatch: ['<rootDir>/e2e/**/*.test.ts'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { tsconfig: { module: 'commonjs', esModuleInterop: true } }],
  },
  testEnvironment: 'node',
  testTimeout:     30000,
  moduleNameMapper: {
    // Allow direct imports from workspace packages in e2e tests
    '^../packages/evm-interop/src/(.*)$':          '<rootDir>/packages/evm-interop/src/$1',
    '^../packages/axio-design-system/src/(.*)$':   '<rootDir>/packages/axio-design-system/src/$1',
    '^../packages/axq-sdk/src/(.*)$':              '<rootDir>/packages/axq-sdk/src/$1',
    '^@axioledger/evm-interop$':                   '<rootDir>/packages/evm-interop/src/index.ts',
    '^@axioledger/axio-design-system$':            '<rootDir>/packages/axio-design-system/src/index.ts',
    '^@axioledger/axq-sdk$':                       '<rootDir>/packages/axq-sdk/src/index.js',
  },
  globals: {
    // ts-jest handles TypeScript without a separate build step
  },
};
