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

## 5. Ship — DONE, live

Shipped and verified in production. `origin/main` and `gh-pages` both carry it; the live page
serves 0 CDN references, exactly 49 `@font-face` rules (deduped), and `fonts/inter.css`,
`leo-operations-map.html` and `leo-dbt-docs/` all return 200. A clean shallow clone rebuilds the
page **byte-identically** and its tests pass, so the chain really is self-contained.

Note on pushing: there is no auto-push. Earlier pushes came from a second interactive session
working in the same checkout. With that session idle, `main` sat 5 commits ahead until pushed
explicitly — do not assume a commit ships itself.

## 6. Stress test of the build chain (2026-08-03)

Adversarial pass over `compile.py`, `assemble.py` and the emitted shim, plus an independent
fresh-context reviewer. Every gate below is now covered by `python3 tools/leo-mirror/test_compile.py`
(26 cases) — **run it before every commit**, because none of these input shapes occurs in
`reference.html` today, and a gate with no live trigger is indistinguishable from a broken one.

| # | Sev | Defect | Trigger | Status |
|---|---|---|---|---|
| 1 | HIGH | `python3 -O` strips all 12 `assert` guards; build exits 0 having skipped every deviation | `-O` + a one-char change to the Glossary button style → page shipped with **both** companion-page links gone, exit 0 | fixed: `require()` raises `SystemExit`. Re-verified under `-O`, `PYTHONOPTIMIZE=2`, plain |
| 2 | HIGH | `</script>` in a text node ends the emitted `<script>` — HTML tokenizing beats JS lexing | `<p>see </script> here</p>` | fixed: `</` → `<\/` before `script`, case-insensitive |
| 3 | HIGH | `expr_of`'s non-greedy match swallowed `}}`, splicing raw text into the generated JS | `<sc-if value="{{a}} {{b}}">` | fixed: `(?:(?!\}\}).)*` |
| 4 | MED | The helmet style block shipped **twice** — 31,685 bytes, 9% of the page. `page_css.replace(font_css,'')` compared against the already URL-rewritten copy, so it matched nothing | `grep -c @font-face` → 98, should be 49 | fixed: strip using the pre-rewrite text, plus two guards. Page 344,058 → **312,373** bytes |
| 5 | MED | `parse_attrs` silently **dropped** every attribute it could not parse — single-quoted, unquoted, bare boolean | `<a aria-current='page' class="x">` → the a11y attribute vanishes | fixed: residue check |
| 6 | MED | A non-`{{ }}` control attribute degraded to `false`/`null` — the block renders empty forever and the build reports success | `<sc-if value="a && b">` | fixed: hard error |
| 7 | MED | `{{ }}` bodies are spliced raw into JS; a backtick or `${` breaks or rewrites the page | ``{{ `x` }}`` | fixed: `check_expr` |
| 8 | MED | `style-hover` is concatenated into a CSS rule unescaped; and `{{ }}` there is never interpolated, so it is silently dead CSS | `style-hover="color:red}body{display:none"` | fixed: reject `{ } < @` |
| 9 | MED | `compile.py main()` was a divergent second entry point — 2 args short, `with(V)` not `with(__scope(V))`, and read `markup.html`, skipping every §3b–3d repair | `python3 compile.py` → artifact throws `ReferenceError: __g is not defined` | fixed: deleted; the test asserts it stays gone |
| 10 | MED | No tests for the build chain at all | — | fixed: `test_compile.py`. It immediately caught #11 being half-fixed |
| 11 | MED | `find_close` **and** the `compile_frag` dispatch matched the literal `<sc-if`, so `<sc-iffy>` counted as a nested tag | `<sc-if value="{{a}}"><sc-iffy>x</sc-iffy>Y</sc-if>` → `unclosed <sc-if>` | fixed in both places — the first fix touched only `find_close` and the test caught it |
| 12 | LOW | HTML comments compile as markup; `{{ }}` inside one still evaluates every render | `<!-- <div class="{{x}}">c</div> -->` | fixed: rejected (the dialect has no comment support) |

Second pass, over the emitted shim (`morph`, the event model, the deviation layer). All eight
were reproduced live in a browser, not read off the source:

| # | Sev | Defect | Trigger | Status |
|---|---|---|---|---|
| 13 | **CRIT** | A render-time throw left the page **looking loaded and completely inert** — `__handlers` was cleared *before* `renderVals()`, so all 34 `data-ev-*` indices pointed into an empty array, and no banner appeared (`hasErr` only covered a failed fetch/parse, not a failed render) | drop `d2d_pipeline` from the marts JSON → 0 KPI rows, every figure blank, clicking "Plain English" does nothing, no error shown | fixed: build into a local handler array, publish only on success, `catch` → clears `d` and sets `err` so the banner renders. Verified: banner shows, toggles respond |
| 14 | HIGH | **Tour footer keyboard trap.** Three sibling `sc-if`s (Back/Next/Finish) change the child count, and the positional diff realigns them: the node you focused as "Next" becomes "Back" | Tab to Next, Enter, Enter → you go *backwards*, oscillating between steps 1 and 2 forever | **FIXED** — keyed diff (§8). Measured: focus stays on "Next" across the step where the footer grows from [Next,×] to [Back,Next,×] |
| 15 | MED | A shrinking list retargets the control under focus; `PRESERVE_ATTRS['data-in']` pins the reveal flag to the *position*, not the row | unpin the first of three chips → focus stays on a node now showing a different pin; a second Enter removes something you never chose | **FIXED** — same keyed diff; 527 keyed elements, 0 duplicate keys across 183 parents |
| 16 | MED | A control that removes itself on activation dropped focus to `<body>`, restarting Tab from the top of a 4,200-line document | KPI filter → focus "Clear" → activate | fixed: record the ancestor path before the patch, land on the nearest survivor. Verified: `BODY` → `DIV (restored)` |
| 17 | MED | A **loudly failed build still rewrote the output tree** — fonts and `inter.css` were written before the first guard ran, leaving HTML at the previous build | mutate the Glossary style → `SystemExit`, but 8 font files written | fixed: writes buffered until every guard passes. Verified: failed build now leaves the directory empty |
| 18 | LOW | `PRESERVE_ATTRS['id']` was applied at every recursion level, not just the mount host, so any descendant that legitimately drops an `id` keeps a stale one | not reachable today (all 37 ids are unconditional) | fixed: root-scoped |
| 19 | LOW | My `__scope` widening used `k in t`, which walks the prototype chain **and** lets the ~102 names `renderVals()` omits on its pre-data early return escape to the global scope | latent — 0 collisions today | fixed: `hasOwnProperty`, own keys only. Keeps real globals reachable, closes the leak |
| 20 | LOW | An anchor whose data has no URL rendered `href=""`, which resolves to the current page — with `target="_blank"` that **opened a second copy of the page in a new tab** | a null `source_url` on any launch-disruption row | fixed: `href` is now emitted whole-or-not-at-all via `__a()`. Verified: null/empty/`javascript:` all emit no attribute |

**Predictions that were contradicted — dropped, not talked into findings:**

- *"The `__scope` fix leaks unknown names to `window`."* It does not, here: **0 of 142** template
  identifiers exist as a `window` property, and a build with the old claim-everything `has` renders
  byte-identical text and node counts. Behaviour-neutral, now proven rather than argued.
- *"The single-quoted `aria-current='page'` is being dropped."* It is a CSS selector inside a
  `<style>` block, not an attribute. The parser hole (#5) is real but has no live trigger.
- *"The map scrolls horizontally at desktop."* Measurement artifact — the pane reported
  `clientWidth: 0`. It does not scroll at 1280 or at 375.
- U+2028/2029 are legal template-literal characters; no break-out, no finding.

**Re-verified after all fixes:** 26/26 gate tests pass · build reproducible (same sha256) · rendered
page **0 geometry diffs across 2,564 elements** vs the pre-fix build · console clean · 6 tables valid ·
25 anchors, 0 emptied · `aria-pressed`/`aria-sort` flip on stable nodes · `data-in` stable at 36 ·
KPI re-sort produces 54 correctly-ordered rows with no ragged or blank cells · map still loads Inter
from `fonts/inter.css` with no CDN.

## 7. Keyed diff — DONE (was §7 "open")

`compile.py` stamps `data-k` on every `sc-for` body (from the item key `logic.js` already
computed but never rendered) and a synthetic per-site key on every `sc-if`; `morph` matches
children by key before falling back to position. Closes findings 14 and 15.

## 8. UX layer shipped on top

- **Mobile stacking** — Risk Register / Mitigation Roadmap / Cost Pareto collapse to one column
  under 560px. Document overflow at 375px: 752 → 375, zero unclipped leaks, column headers still
  in the accessibility tree.
- **Shareable URL state** — scenario, rate, plain-English and the KPI/risk filters and sorts
  round-trip through `location.hash`. Hostile input rejected (closed enums, rate clamped to
  0.5–5.0, unknown keys dropped). The link wins until the reader interacts, then they do.
- **Inline concept cards** — first prose mention of each glossary acronym carries its own
  definition. Anchored to the *text block*, not the term: anchored to the term, a mention near
  the right edge pushed a 320px card outside its container (reported by TJ, fixed).
- **Command palette** — ⌘K/Ctrl-K plus a visible "Jump to…" button. Mounted outside `#leo-app`
  so `morph` never sees it; drives the page by clicking existing controls.
- **Provenance strip** — *Data as of · Marts loaded · basis*, both values read from the payload
  so there is no second number to drift. Deliberately no dbt test count: the only source would
  be a hardcoded copy of a figure that already went stale once on the landing page.
- **Default scenario is Base**, not the reference's High (its 5.0/day ceiling). Opens at 3.6.

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
- **56 `style="…${__e(…)}…"` sites can inject CSS declarations**, the same class of hole `__u`
  closed for `href`. Not fixed, because every interpolated value is computed in `logic.js` — a
  palette lookup (`*.color`, via `tier()`) or a numeric width/percentage — never a raw JSON field
  passed straight through. The guarantee lives in the logic layer, not the escaping layer, which is
  weaker than `__u`'s. If a raw data field is ever bound into a `style=`, add a `__s()` that rejects
  `; { } <` and route that site through it.
- `hover_rules` is a module-level dict that is never reset, so two `compile_frag` calls in one
  process share class numbering. `assemble.py` calls it exactly once; the test suite clears it.
- `martsData.json` (99KB) and `markup.html` are committed but referenced by **no code** — `markup.html`
  lost its only reader when `main()` was deleted, and `martsData.json` never had one (it also differs
  from the live `leo_finance_dashboard_data.json`). Left in place because they may be provenance for
  the export; delete with `git rm tools/leo-mirror/martsData.json tools/leo-mirror/markup.html` if not.
