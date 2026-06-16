/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{html,js}'],
  theme: {
    extend: {
      colors: {
        'bg-primary':     '#0A0F1D',
        'bg-card':        '#1E293B',
        'accent':         '#06B6D4',
        'text-primary':   '#F1F5F9',
        'text-secondary': '#94A3B8',
        'text-code':      '#22D3EE',
        'success':        '#10B981',
        'warning':        '#F59E0B',
        'danger':         '#EF4444',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
}
