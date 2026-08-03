# Leo mirror — remaining work

The page at `site/src/public/leo-program-finance.html` is generated. **Never hand-edit it.**
Regenerate with `python3 tools/leo-mirror/assemble.py` (self-contained; verified to produce
byte-identical output from the repo copy alone).

## Done

- Build chain moved out of `/tmp` into this directory; all paths relative.
- Root-cause render fix: in-place DOM patch (`morph`) instead of whole-tree `innerHTML`.
  Cleared six defects at once — replayed animations, cancelled smooth scroll, broken slider
  drag, destroyed focus, detached ResizeObserver, unbounded IntersectionObserver growth.
- Deliberate deviations from the byte-exact mirror (all in `assemble.py` §3b/§3c, commented):
  Operations Map link, Data Lineage link, `href="./"` home, `aria-pressed` on 3 toggles.
- 7 Inter woff2 self-hosted under `site/src/public/fonts/` (staged, must be committed —
  the reference's Google Fonts CDN links were deliberately stripped, so these are load-bearing).

## 1. Table semantics — DONE

Implemented as `assemble.py` §3d: a tag-tree pass adds `role="table"` to the container,
`role="rowgroup"` to any wrapper between container and rows, `role="row"` to header and data
rows, and `role="columnheader"` / `role="cell"` to their children. No `<table>` markup — the
layout is CSS Grid and real table elements would destroy it.

Six tables annotated. The earlier ten-row list in this file was a hypothesis and four of its
entries did not survive inspection:

| Section | grid-template-columns | |
|---|---|---|
| Rolling Variance Trend | `1.4fr .7fr .8fr .8fr .8fr repeat(4,.7fr) .8fr` | ✅ 10 cols |
| Cash-Flow, per expanded group | `minmax(160px,2fr) .8fr .8fr .8fr .6fr .8fr .6fr .6fr` | ✅ 8 cols |
| Capitalised Inventory Roll-Forward | `minmax(110px,1fr) repeat(5,1fr)` | ✅ 6 cols |
| The Full Operational KPI Framework | `minmax(96px,.8fr) minmax(150px,1.4fr) …` | ✅ 5 cols |
| Program Delivery Risk Index | `78px 1fr 52px 44px` | ✅ 4 cols |
| Mitigation Roadmap | `minmax(150px,1.5fr) minmax(160px,1.6fr) minmax(180px,2fr)` | ✅ 3 cols — **was missing from the list** |

Deliberately **not** annotated, with the reason:

- **EAC Sensitivity**, **Cost-Driver Pareto**, **Manufacturing-to-Launch Efficiency** — no
  header row exists in the reference design. A table with no `columnheader` restores none of
  the lost `<th>` meaning, and one EAC cell is a tornado bar rather than a value. Adding
  headers would be a design change, not a semantics repair.
- **Risk Register** (`minmax(200px,2fr) …`) — each "row" is a card with nested headings and
  badges, and there is no header row. It is a list of cards that happens to align.
- **Cash-Flow group toggles** (`16px minmax(150px,1.7fr) …`) — every row is a disclosure
  `<button>`. `role="row"` would strip the button role. Left native; the detail table it
  expands *is* annotated.

So 6 of the old page's 16 `<thead>`s come back. The other ten had no counterpart to restore.

The KPI header cells are `<button>`s, so `role="columnheader"` costs them their announced
button role; `aria-sort` is added to the three sortable ones to give the affordance back.
Every comparator in `logic.js` is ascending and the buttons pick the active column rather than
flipping direction, so the values are `ascending` / `none`.

Guardrails: the pass asserts two row nodes per spec, exactly one header row, cell count equal
to the expanded column count, and that the container really is an ancestor of every row. A
reference change that breaks any of those fails the build instead of silently skipping.

**Verified** (all pre-registered before running):

- Rendered DOM, all 6 tables: cell counts match `getComputedStyle().gridTemplateColumns`
  exactly (10/8/6/5/4/3), one header row each, zero rows outside a table, zero rows nested in
  a roleless wrapper, zero empty cells. The 6th only exists once a Cash-Flow group is
  expanded — checked after expanding.
- **Zero visual change, proven not asserted:** a no-roles build of the same commit was
  generated and both pages measured at 1280px — 2,564 elements, identical tag + bounding box
  + text length, **0 diffs**.
- `aria-sort` flips on the same node across a sort (morph preserves identity); slider drag
  holds all intermediate values; `data-in` count stable at 36 across a state change;
  `aria-pressed` flips on a stable node; console clean; build reproducible (same sha256 on
  re-run).

## 2. Compiler hardening (`compile.py`)

All four done. Each was probed by lifting the shipped function out of the built page and
running it, not by reading the source.

- **`__scope` proxy** — `has` is now `k in t` (plus the helper exclusions). Before, the proxy
  claimed every name, so `Math` resolved to `undefined` inside `with()`, threw, and `__g`
  swallowed it into `''`. Probe: `with(__scope({a:1})) Math.round(1.6)` → `2` (was a throw),
  `JSON.stringify([1])` → `"[1]"`, own keys still resolve.
- **`EVENT_PROPS`** — cut to the three the shim actually delegates. The reference only ever
  uses `on-click` (47), `on-input` (1), `on-change` (1), so nothing was in use. A
  `sc-camel-on-*` outside the three is now a build error rather than a literal attribute that
  looks wired and never fires.
- **href scheme allowlist** — new `__u()`; `compile.py` routes `href` through it. It is **11**
  sites, not 9, and all are pure `{{ expr }}`, so no mixed literal/interpolation case exists.
  Probe: `https:`/`http:`/`//host`/`/abs`/`#frag`/`rel/`/`./x` pass; `javascript:`,
  `JaVaScript:`, leading-whitespace `javascript:`, NUL- and newline-obfuscated `java\0script:`,
  `data:`, `vbscript:`, `mailto:` all render an empty href. On the live page: 25 anchors, 0
  emptied — nothing legitimate was rejected.
- **`morph` stripping `id="leo-app"`** — fixed via `PRESERVE_ATTRS`. Probe: `getElementById`
  non-null after a state change (was null).

## 3. Operations map upgrade — DONE

The described symptom was right (no `@font-face`, no type tokens) but understated: the map was
pulling Inter from **Google Fonts over the CDN** while the finance page deliberately
self-hosts. So this was a consistency and privacy gap, not only typography.

- `assemble.py` now also writes `fonts/inter.css` — the same extracted `@font-face` block,
  one source for both pages. The map `<link>`s it; the finance page keeps its copy inline
  because it is the self-contained artifact.
- The map's 3 Google Fonts `<link>`s are gone. Neither page now touches a CDN.
- Added `--c-font-body` / `--c-font-mono` and routed all 9 hand-written stacks through them.
  `--c-*` prefix, not `--font-*`: that is this file's own convention. `--shadow-*` was already
  there as `--c-shadow-sm/md/lg`, so nothing to add.

**Caught in verification, not in review:** the first build 404'd every face. A stylesheet
resolves `url()` against itself, so the document-relative `fonts/x.woff2` became
`fonts/fonts/x.woff2`. `assemble.py` now strips the prefix for the file version and asserts
none survives. After the fix: 7 Inter faces loaded, `document.fonts.check('14px Inter')` true,
and body text measures 237px against Inter's 237px and serif's 200px — genuinely applied, not
merely declared.

## 4. Verification — results

Passing: both pages render, console clean, no failed requests, 6 tables valid, `aria-sort`
and `aria-pressed` flip on stable nodes, `data-in` stable at 36, slider holds every
intermediate value, `#leo-app` survives state changes, build reproducible (same sha256).

**Failing — mobile 375px, finance page.** Document scrolls sideways: `scrollWidth` 752 against
a 375 viewport. Two distinct causes, one fixed:

- *Fixed* — the header control cluster was `flex:0 0 auto` with `flex-wrap:nowrap`, forcing
  588px of controls through 375. Now wraps (§3c(d)); 752 → 588. The two added nav links widen
  it but are **not** the cause: removing them still overflowed.
- *Open* — three sections have grid column minimums wider than a phone: Risk Register
  `200+120+80+80` = 564px, Mitigation Roadmap 538px, Cost Pareto 390px, none inside a scroll
  container. Fixing it means either a media query narrowing the minmax floors or wrapping each
  in an `overflow-x:auto` region (with `tabindex="0"`, or keyboard users cannot reach the
  scroll). Both are responsive-design changes to three sections, beyond a verification pass —
  **left for a decision.** Desktop is unaffected (1280: no horizontal scroll, tables valid).
  The operations map is clean at 375 (no document-level horizontal scroll).

Still owed:

- Section-by-section DOM diff vs the reference **below the fold**.
- The 686-char text delta (mirror 40,368 vs reference 39,682) is still unexplained. Note the
  comparison may not be like-for-like at all: the reference renders `hint-placeholder-count`
  placeholder rows while the mirror renders real dbt row counts, so a text-length diff is
  expected and the number may be measuring nothing. Establish that before chasing it.
- `__g` swallow count has no probe (it is closure-scoped); `emptyCells == 0` plus a clean
  console is the current proxy.
- Slider range is 0.5–5.0 — values above 5 clamp and look like a frozen control.

## 5. Ship — staged, needs TJ

Local steps are done: secret scan, `git fetch` + drift check, commit. **Nothing is pushed.**
Push, CI watch and live-URL verification (including that `fonts/*.woff2` and `fonts/inter.css`
actually deploy) are TJ's call — see the handoff at the end of the session.

## Accepted limitations

- A strict CSP would break the page: one large inline `<script>`, three inline `<style>`
  blocks, pervasive inline `style=`. Needs `'unsafe-inline'` for script and style.
- Theme toggle, focus mode, data-as-of and test-count badges are gone — the reference has
  none. Reversible as deliberate additions if wanted.
- Confirm Inter's licence before the font binaries land in a public repo (SIL OFL expected;
  the UUID filenames are a CDN-export shape, so worth a look).
- `__u()` strips every character from U+0000 to U+0020, so a raw space inside an href is removed rather than
  rejected. Over-strict by design — control characters are how `java\nscript:` sneaks past a
  scheme test, and a URL with an unencoded space is malformed anyway.
- `compile.py`'s `main()` is a stale second entry point: it emits `__tpl(V, __h, __e)` — wrong
  arity for two generations now — reads `markup.html` directly (so it skips every §3b–3d
  repair) and writes `template.gen.js` / `hover.gen.css`, which nothing reads and which do not
  exist on disk. `assemble.py` is the only real build. Deleting it is the obvious call but is
  not this change's business; flagged rather than folded in.
- Mobile 375px on the finance page still overflows in three sections — see §4.
