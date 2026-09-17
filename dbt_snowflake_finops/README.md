# dbt Snowflake FinOps

A small, runnable **dbt + Snowflake** project that allocates multi-tenant cloud cost, computes
per-tenant chargeback margin, and flags month-over-month spend anomalies — the same overhead-
absorption and variance discipline as `../dbt_gpu_cost_attribution/`, now run on a real cloud
data warehouse instead of DuckDB.

**What this demonstrates:** Snowflake SQL (`qualify`, window functions, `parse_json`), VARIANT /
semi-structured ingestion, warehouse compute management (auto-suspend, X-Small sizing), dbt-on-
Snowflake (vs. dbt-on-DuckDB elsewhere in this portfolio), and medallion architecture
(bronze/silver/gold).

## The idea in one line
A cloud bill is a shared-cost problem, exactly like a shared factory: usage gets metered per
tenant, discounted by contract terms, marked up for internal chargeback, and reviewed for margin
and month-over-month drift — the same cost-accounting discipline applied to a cloud account
instead of a GL.

## Medallion architecture
- **Bronze** (`models/bronze/`) — raw usage, pricing, and contract rows, typed and cast. Usage
  rows carry a semi-structured `tags_json` field (env/team/cost_center) ingested via Snowflake's
  **VARIANT** type (`parse_json()`'s native return type, no explicit cast needed) and unpacked
  with colon-notation field access —
  the same shape a real AWS Cost & Usage Report or Azure Cost Management export requires, since
  tag schemas vary per resource and can't be flattened into a fixed CSV column set upstream.
- **Silver** (`models/silver/`) — usage joined to the rate card and priced, deduplicated via
  `qualify row_number()` (Snowflake-idiomatic, no DuckDB equivalent the same way), then rolled up
  to one row per tenant per day with contract-adjusted actual cost and chargeback revenue.
- **Gold** (`models/gold/`) — the marts: per-tenant daily margin with a margin zone, and
  month-over-month cost variance per tenant via `lag()` over each tenant's own history.

## What it does
- **seeds** (synthetic; no real company data) — `raw_cloud_usage` (per-tenant, per-service usage
  with JSON tags), `raw_cloud_pricing` (rate card by service/resource/region), `raw_tenant_contracts`
  (committed-use discount + chargeback markup per tenant)
- **bronze** — typed, VARIANT-parsed staging models (see above)
- **silver**
  - `silver_usage_priced` — usage priced at list rate, deduplicated
  - `silver_daily_tenant_cost` — one row per tenant per day: total list cost, contract-adjusted
    actual cost, chargeback revenue
- **gold**
  - `fct_daily_tenant_margin` — per tenant per day: actual cost, chargeback revenue,
    `gross_margin_pct`, and a `margin_zone` (warning <15% / standard 15-30% / best-in-class >30%)
  - `fct_tenant_cost_mom_variance` — month-over-month actual-cost variance per tenant
- **tests** (three tiers)
  - **data tests** — not_null/unique surrogate key, `relationships` (every tenant exists in
    contracts), `accepted_values` on `service`, `tag_env`, and `margin_zone`
  - **unit test** — pins the discount/markup/margin *logic* against mocked inputs in CI (three
    tenants, three different discount/markup pairs, exercising all three margin zones)
  - **singular tests** — no negative costs or revenue; chargeback revenue never falls below
    actual cost (a markup-inversion governance check)

## Run it (needs a Snowflake account — see below; no cloud needed to read the SQL)
```bash
pip install dbt-snowflake
cp profiles.example.yml ~/.dbt/profiles.yml   # or: export DBT_PROFILES_DIR=.
export SNOWFLAKE_ACCOUNT=...   SNOWFLAKE_USER=...   SNOWFLAKE_PASSWORD=...
export SNOWFLAKE_ROLE=...      SNOWFLAKE_DATABASE=...   SNOWFLAKE_WAREHOUSE=...   SNOWFLAKE_SCHEMA=...
dbt build                        # seed + models + data tests + unit test + singular tests
```
Re-tune the margin thresholds without editing SQL:
```bash
dbt build --vars '{margin_warning_below: 0.20, margin_best_above: 0.35}'
```

### Getting a Snowflake account (free, no credit card)
Sign up at [signup.snowflake.com](https://signup.snowflake.com/) — $400 in trial credit over 30
days, no payment method required to start. Set the warehouse to auto-suspend after 60 seconds of
inactivity (a real "cost management on Snowflake" practice, not just a demo shortcut). A project
this size, run on an X-Small warehouse with auto-suspend, typically burns single-digit dollars.

## What the synthetic data shows
Three tenants, spanning a partial August and a partial September. The model surfaces that
**`tenant_beta`'s actual cost jumps +79% month-over-month** (an egress-cost spike) and
`tenant_gamma` grows +75% (scaling GPU compute), while `tenant_alpha` stays roughly flat at +8% —
the exact "whose spend moved and why" question a FinOps review needs answered, produced by tested,
auditable models instead of a spreadsheet.

## Structure
```
dbt_snowflake_finops/
  dbt_project.yml
  profiles.example.yml
  seeds/   raw_cloud_usage.csv, raw_cloud_pricing.csv, raw_tenant_contracts.csv
  models/
    bronze/   stg_cloud_usage (VARIANT parsing), stg_cloud_pricing, stg_tenant_contracts + bronze.yml
    silver/   silver_usage_priced, silver_daily_tenant_cost + silver.yml
    gold/     fct_daily_tenant_margin, fct_tenant_cost_mom_variance + gold.yml (incl. unit test)
  tests/   assert_no_negative_costs.sql, assert_chargeback_covers_cost.sql
```

## Notes
- Synthetic data only — no employer or confidential information. Cloud rates are illustrative,
  point-in-time (2026).
- Every figure is computed in SQL and verified by `dbt build`; nothing ships if a test fails.
- CI (`.github/workflows/dbt-ci.yml`, job `dbt-build-snowflake-finops`) is wired but skips cleanly
  until real Snowflake credentials exist as repo secrets — it won't break the green badge for the
  other dbt projects in this repo while this one is pre-account.
