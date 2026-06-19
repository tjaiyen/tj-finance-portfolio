# Decks — Quarto reveal.js presentations

Interview-grade slide decks built from Markdown with [Quarto](https://quarto.org) (reveal.js).
Off-Drive, version-controlled, and **data-driven** — charts run from the repo's real seed data.

## One-time setup
- **Quarto CLI** lives at `~/.local/bin/quarto` (installed from the macOS tarball — no sudo). Put it on
  PATH: `export PATH="$HOME/.local/bin:$PATH"`. (Or `brew install quarto`, which needs a sudo password.)
- **Python env** for the data slides is already created at `decks/.venv` (jupyter + matplotlib + pandas,
  via `uv`). Nothing else to install.

## Build / present
```bash
cd decks
export QUARTO_PYTHON="$PWD/.venv/bin/python"     # run code chunks in the deck venv
quarto preview portfolio-overview.qmd           # live-reload in the browser
quarto render  portfolio-overview.qmd           # -> _site/portfolio-overview.html
```
In the deck: `F` fullscreen · `S` speaker notes · `O` slide overview · `E` PDF-export view.

## PDF export (optional)
Needs Chrome/Chromium installed: `quarto render portfolio-overview.qmd --to pdf`.

## Add another deck
Copy `portfolio-overview.qmd`, change the front-matter `title`, write slides:
`##` starts a new slide · `. . .` is an incremental reveal · `::: notes` … `:::` are speaker notes ·
a fenced ```{python}``` chunk pulls a project CSV for a live chart.

_Build outputs (`_site/`, `.quarto/`, `*_files/`) and `.venv/` are gitignored._
