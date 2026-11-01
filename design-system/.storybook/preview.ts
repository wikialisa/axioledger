import type { Preview } from '@storybook/react';
import React from 'react';
import { AxioProvider } from '../src/providers/AxioProvider';

// Import design system CSS tokens globally in Storybook
import '../tokens/variables.css';

const preview: Preview = {
  // Global decorators: wrap every story in AxioProvider
  decorators: [
    (Story, context) => {
      const theme = context.globals['theme'] ?? 'light';
      return React.createElement(
        AxioProvider,
        { theme },
        React.createElement(
          'div',
          {
            style: {
              padding: '24px',
              background: theme === 'dark' ? 'var(--color-background-primary)' : 'var(--color-background-primary)',
              minHeight: '100vh',
              fontFamily: 'var(--font-family-base)',
            },
          },
          React.createElement(Story)
        )
      );
    },
  ],

  // Global toolbar controls
  globalTypes: {
    theme: {
      description: 'Design system theme',
      defaultValue: 'light',
      toolbar: {
        title: 'Theme',
        icon: 'circlehollow',
        items: [
          { value: 'light',  title: 'Light',  icon: 'sun'  },
          { value: 'dark',   title: 'Dark',   icon: 'moon' },
          { value: 'system', title: 'System', icon: 'mirror' },
        ],
        dynamicTitle: true,
      },
    },
  },

  parameters: {
    // Default viewport sizes
    viewport: {
      viewports: {
        mobile: { name: 'Mobile (375px)',  styles: { width: '375px',  height: '812px' } },
        tablet: { name: 'Tablet (768px)',  styles: { width: '768px',  height: '1024px' } },
        desktop:{ name: 'Desktop (1280px)',styles: { width: '1280px', height: '800px' } },
      },
      defaultViewport: 'desktop',
    },

    // Accessibility config — run axe-core on every story
    a11y: {
      config: {
        rules: [
          { id: 'color-contrast', enabled: true },
          { id: 'aria-required-attr', enabled: true },
          { id: 'button-name', enabled: true },
          { id: 'label', enabled: true },
        ],
      },
      options: {
        runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21aa'] },
      },
    },

    actions: { argTypesRegex: '^on[A-Z].*' },

    controls: {
      matchers: {
        color: /(background|color)$/i,
        date:  /Date$/i,
      },
    },

    // Backgrounds disabled — handled by AxioProvider decorator above
    backgrounds: { disable: true },
  },
};

export default preview;
