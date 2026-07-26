/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,js}'],
  theme: {
    extend: {
      // Colors are CSS-variable-backed (space-separated RGB triplets) so the whole palette
      // can flip for prefers-color-scheme without touching any utility class. Values live in
      // src/css/styles.css (:root = dark default, @media light = light overrides).
      colors: {
        'bg-primary':     'rgb(var(--c-bg-primary) / <alpha-value>)',
        'bg-card':        'rgb(var(--c-bg-card) / <alpha-value>)',
        'accent':         'rgb(var(--c-accent) / <alpha-value>)',
        'text-primary':   'rgb(var(--c-text-primary) / <alpha-value>)',
        'text-secondary': 'rgb(var(--c-text-secondary) / <alpha-value>)',
        'text-code':      'rgb(var(--c-text-code) / <alpha-value>)',
        'success':        'rgb(var(--c-success) / <alpha-value>)',
        'warning':        'rgb(var(--c-warning) / <alpha-value>)',
        'danger':         'rgb(var(--c-danger) / <alpha-value>)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
}
