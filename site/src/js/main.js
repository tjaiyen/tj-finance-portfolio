import '../css/styles.css'
import { initCalculators } from './calculator.js'

// copy-to-clipboard for code blocks
function initCopyButtons() {
  document.querySelectorAll('[data-copy-target]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const el = document.getElementById(btn.getAttribute('data-copy-target'))
      if (!el) return
      try {
        await navigator.clipboard.writeText(el.innerText)
        const original = btn.textContent
        btn.textContent = 'copied'
        setTimeout(() => { btn.textContent = original }, 1200)
      } catch { /* clipboard unavailable — no-op */ }
    })
  })
}

// mobile nav toggle
function initNav() {
  const btn = document.getElementById('nav-toggle')
  const menu = document.getElementById('nav-menu')
  if (!btn || !menu) return
  btn.addEventListener('click', () => menu.classList.toggle('hidden'))
  menu.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => menu.classList.add('hidden')))
}

window.addEventListener('DOMContentLoaded', () => {
  initCalculators()
  initCopyButtons()
  initNav()
})
