// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  site: 'https://mr-1311.github.io',
  base: '/',
  integrations: [
    starlight({
      title: 'Puppet',
      social: {
        github: 'https://github.com/Mr-1311/puppet',
      },
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Introduction', slug: 'guides/getting-started' },
          ],
        },
        {
          label: 'Core Concepts',
          items: [
            { label: 'Architecture', slug: 'guides/architecture' },
            { label: 'Menus', slug: 'guides/menus' },
          ],
        },
        {
          label: 'Development',
          items: [
            { label: 'Plugin Development', slug: 'guides/plugin-development' },
          ],
        },
      ],
    }),
  ],
});
