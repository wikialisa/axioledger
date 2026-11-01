import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(ts|tsx)'],

  addons: [
    '@storybook/addon-essentials',    // Controls, Actions, Docs, Viewport, Backgrounds
    '@storybook/addon-a11y',          // Accessibility audit panel (axe-core)
    '@storybook/addon-themes',        // Light / Dark theme switcher
  ],

  framework: {
    name: '@storybook/react-vite',
    options: {},
  },

  docs: {
    autodocs: 'tag',
  },

  viteFinal: (config) => {
    // Align with vite.lib.config.ts alias
    config.resolve = {
      ...config.resolve,
      alias: { '@': new URL('../src', import.meta.url).pathname },
    };
    return config;
  },
};

export default config;
