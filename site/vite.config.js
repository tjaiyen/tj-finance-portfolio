import { defineConfig } from 'vite'

// base MUST match the GitHub repo name for GitHub Pages project sites.
// Repo https://github.com/tjaiyen/tj-finance-portfolio  ->  base '/tj-finance-portfolio/'
// Without it, Pages serves assets from '/' and every JS/CSS 404s into a blank page.
export default defineConfig({
  base: '/tj-finance-portfolio/',
  root: 'src',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: { main: './src/index.html' }
    }
  }
})
