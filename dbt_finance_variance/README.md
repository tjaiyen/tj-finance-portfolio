# dbt Finance Variance

A small, runnable **dbt** project that turns raw financial line items into a tested, canonical
**account-variance** model — prior vs. current period, absolute and % variance, and a materiality flag —
with schema tests and data governance baked in.

This is the dbt rebuild of my Python/Claude variance tool (`../claude_finance_agent/`): same finance logic,
expressed the modern-data-stack way — sources → staging → marts, with `dbt test` enforcing integrity.

## Why it exists
I'm a cost accountant who builds the reporting layer, not just the report. I already do data modeling, ETL,
and financial-data governance in SQL/Python/Power BI; this project is me doing the same work in dbt — the
tooling delta, closed. It runs on **DuckDB**, so there's no warehouse to set up: clone and build.

## What it does
- **seed** `raw_financials` — two periods of GL line items (synthetic; no employer data)
- **staging** `stg_financials` — typed, cleaned canonical rows (one row per account/period)
- **mart** `fct_account_variance` — pivots prior vs. current, computes `variance_abs`, `variance_pct`, and
  `is_material` against a configurable threshold (`materiality_threshold`, default 5%)
- **tests** — not_null + unique keys, accepted_values on the materiality flag, and a relationship test so
  the mart can never reference an account that isn't in the source (the governance guardrail, in dbt form)

## Run it (≈60 seconds, local, no cloud)
```bash
pip install dbt-duckdb
# put the example profile where dbt looks for it, or keep it in-project:
cp profiles.example.yml ~/.dbt/profiles.yml      # (or: export DBT_PROFILES_DIR=.)
dbt deps          # (no-op; no packages required)
dbt build         # runs seed + models + tests
dbt docs generate && dbt docs serve   # optional: browse the lineage graph
```
Change the threshold or periods without editing models:
```bash
dbt build --vars '{materiality_threshold: 0.03, prior_period: 2026Q1, current_period: 2026Q2}'
```

## Structure
```
dbt_finance_variance/
  dbt_project.yml
  profiles.example.yml      # DuckDB profile (local file db)
  seeds/raw_financials.csv  # synthetic GL, two periods
  models/
    staging/ stg_financials.sql + staging.yml
    marts/   fct_account_variance.sql + marts.yml
  .gitignore
```

## Notes
- Synthetic data only — no employer or confidential information.
- Numbers are computed in SQL/dbt and verified by `dbt test`; nothing ships if a test fails.
- Mirrors a real pattern I use: model the facts deterministically, govern them with tests, then let
  reporting/AI sit on top of a trustworthy layer.
