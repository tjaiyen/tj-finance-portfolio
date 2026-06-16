# site — case-study landing page

The Vite + Tailwind static site for the portfolio. Ties together the three projects in this repo and
deploys to GitHub Pages at **https://tjaiyen.github.io/tj-finance-portfolio/**.

The thesis: *compute the facts in code, use the model for judgment, verify before trust* — finance rigor
expressed as a trustworthy data + AI layer.

## Stack
Vite 5 · Tailwind CSS 3.4 · vanilla ES modules. No backend.

## Run locally (from this `site/` folder)
```bash
npm install
npm run dev        # http://localhost:5173/tj-finance-portfolio/
npm run build      # -> site/dist/
npm run preview    # serve the production build
```

## Deploy
CI lives at the **repo root** (`.github/workflows/deploy.yml`): on push to `main` it builds this `site/`
folder and publishes `site/dist` to the `gh-pages` branch. In repo Settings → Pages, set the source to
`gh-pages`.

> `base` in `vite.config.js` is `/tj-finance-portfolio/` — it must match the repo name, or every asset
> 404s into a blank page. If the repo is renamed, update it.

## Notes
- Synthetic data only. The sandbox numbers are computed client-side and deterministically.
- Margin/FinOps benchmarks are point-in-time (2026) and labeled as such.
