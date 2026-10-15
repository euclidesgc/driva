import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    fileParallelism: false,
    globals: true,
    include: ['test/**/*.e2e-spec.ts'],
    hookTimeout: 15000,
    testTimeout: 15000,
  },
});
