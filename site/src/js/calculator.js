// Interactive sandbox — the same logic the dbt mart and the Python agent compute,
// run live in the browser so a reviewer can poke at it. All math is deterministic
// and documented inline; nothing here calls a model.

const $ = (id) => document.getElementById(id)
const fmtMoney = (n) =>
  isFinite(n) ? n.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }) : '—'
const fmtPct = (n) => (isFinite(n) ? (n * 100).toFixed(2) + '%' : '—')

// debounce so rapid typing doesn't thrash the DOM (matches the v4 spec's 100ms)
function debounce(fn, ms = 100) {
  let t
  return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms) }
}

// ---- Variance + materiality (mirrors fct_account_variance in the dbt project) ----
// variance_abs = current - prior
// variance_pct = variance_abs / prior        (guard prior == 0)
// is_material  = |variance_pct| >= threshold
function computeVariance() {
  const prior = parseFloat($('v-prior').value)
  const current = parseFloat($('v-current').value)
  const thresholdPct = parseFloat($('v-threshold').value)
  const threshold = isFinite(thresholdPct) ? thresholdPct / 100 : NaN

  if (!isFinite(prior) || !isFinite(current) || !isFinite(threshold)) {
    $('v-abs').textContent = '—'
    $('v-pct').textContent = '—'
    setBadge($('v-material'), null)
    return
  }

  const abs = current - prior
  const pct = prior === 0 ? NaN : abs / prior // null-guard, same as nullif(prior,0) in SQL
  const material = isFinite(pct) ? Math.abs(pct) >= threshold : false

  $('v-abs').textContent = fmtMoney(abs)
  $('v-pct').textContent = prior === 0 ? 'n/a (prior = 0)' : fmtPct(pct)
  setBadge($('v-material'), prior === 0 ? null : material)
}

function setBadge(el, material) {
  if (material === null) {
    el.textContent = '—'
    el.className = 'badge'
    return
  }
  el.textContent = material ? 'MATERIAL' : 'immaterial'
  el.className = material
    ? 'inline-block rounded-md px-2.5 py-1 text-xs font-mono font-bold bg-warning/15 text-warning border border-warning/40'
    : 'inline-block rounded-md px-2.5 py-1 text-xs font-mono bg-success/10 text-success border border-success/30'
}

// ---- Gross margin + zone ----
// gross_margin_% = (revenue - cost) / revenue * 100
// zones: <40% warning (red) | 40–65% standard (yellow) | >65% best-in-class (green)
function computeMargin() {
  const revenue = parseFloat($('m-revenue').value)
  const cost = parseFloat($('m-cost').value)

  if (!isFinite(revenue) || !isFinite(cost) || revenue <= 0) {
    $('m-margin').textContent = '—'
    $('m-zone').textContent = 'enter revenue > 0'
    $('m-zone').className = 'text-text-secondary text-sm'
    $('m-bar').style.width = '0%'
    return
  }

  const margin = (revenue - cost) / revenue // fraction
  const pct = margin * 100
  $('m-margin').textContent = pct.toFixed(1) + '%'

  let label, barColor, textColor
  if (pct < 40) { label = 'Warning — below AI-native floor'; barColor = 'bg-danger'; textColor = 'text-danger' }
  else if (pct <= 65) { label = 'AI-native standard (~40–65%)'; barColor = 'bg-warning'; textColor = 'text-warning' }
  else { label = 'Best-in-class (>65%)'; barColor = 'bg-success'; textColor = 'text-success' }

  $('m-zone').textContent = label
  $('m-zone').className = `${textColor} text-sm font-medium`
  // clamp the visual bar to [0, 100]
  $('m-bar').style.width = Math.max(0, Math.min(100, pct)).toFixed(1) + '%'
  $('m-bar').className = `h-full rounded-full transition-all duration-200 ${barColor}`
}

export function initCalculators() {
  const vIds = ['v-prior', 'v-current', 'v-threshold']
  const mIds = ['m-revenue', 'm-cost']
  const onV = debounce(computeVariance)
  const onM = debounce(computeMargin)
  vIds.forEach((id) => $(id) && $(id).addEventListener('input', onV))
  mIds.forEach((id) => $(id) && $(id).addEventListener('input', onM))
  // initial paint
  computeVariance()
  computeMargin()
}
