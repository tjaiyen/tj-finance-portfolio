# dbt GPU Cost Attribution

A small, runnable **dbt + DuckDB** project that attributes shared AI-inference compute cost to individual
tenants and computes per-tenant gross margin — using the **same overhead-absorption method a cost accountant
applies to a shared factory**, now applied to a shared GPU cluster.

This is the FinOps extension of my finance work (`../dbt_finance_variance/`, `../claude_finance_agent/`):
identical discipline — facts computed deterministically in SQL, governed by tests — pointed at cloud unit
economics instead of the GL.

## The idea in one line
Idle GPU capacity is **factory overhead**. You absorb it across tenants by an allocation key (token volume),
exactly like absorbing shared equipment cost across job orders by machine-hours.

## What it does
- **seeds** (synthetic; no employer data) — `raw_api_usage` (per-tenant tokens), `raw_gpu_billing`
  (provisioned vs. used GPU hours, by fleet), `raw_contracts` (usage-based pricing)
- **staging** — typed, cleaned rows; `fleet_type` keeps **training compute (R&D) out of COGS**
- **intermediate**
  - `int_daily_cluster_cost` — splits each day's inference cost into an **active pool** (used) and an
    **idle pool** (provisioned − used = the overhead to absorb)
  - `int_tenant_allocation` — the **absorption key**: `allocation_ratio = tenant_tokens / daily_total_tokens`,
    plus derived revenue from contract rates
- **mart** `fct_daily_tenant_costs` — per tenant per day: `direct_cost`, **`allocated_idle_cost`**,
  `total_cost`, `gross_margin_pct`, and a `margin_zone` (warning <40% / standard 40–65% / best-in-class >65%)
- **tests** (three tiers)
  - **data tests** — not_null/unique surrogate key, `relationships` (every tenant exists in contracts),
    `accepted_values` on `fleet_type` and `margin_zone`
  - **unit test** — pins the allocation + margin *logic* against mocked inputs in CI (0.75/0.25 token split
    over a 1000 active / 100 idle pool → 75/25 absorbed overhead → the right margin zones)
  - **singular tests** — allocation ratios sum to 1 per day (nothing lost/double-counted); no negative costs

## Run it (≈60 seconds, local, no cloud)
```bash
pip install dbt-duckdb
export DBT_PROFILES_DIR=.        # or: cp profiles.example.yml ~/.dbt/profiles.yml
dbt build                        # seed + models + data tests + unit test + singular tests
dbt docs generate && dbt docs serve   # optional: browse the lineage graph
```
Re-tune the zone thresholds or the COGS fleet filter without editing SQL:
```bash
dbt build --vars '{margin_warning_below: 0.50, margin_best_above: 0.70, inference_fleet: inference}'
```

## What the synthetic data shows
Three tenants, two days. The model surfaces that **`cust_c` runs at a negative margin** (its contract rates
don't cover its absorbed compute) while `cust_b` is best-in-class — the exact "which tenant is unprofitable
and why" question FinOps teams need answered, produced by tested, auditable models.

## Structure
```
dbt_gpu_cost_attribution/
  dbt_project.yml
  profiles.example.yml
  seeds/   raw_api_usage.csv, raw_gpu_billing.csv, raw_contracts.csv
  models/
    staging/       stg_api_usage, stg_gpu_billing, stg_contracts + staging.yml
    intermediate/  int_daily_cluster_cost, int_tenant_allocation
    marts/         fct_daily_tenant_costs.sql + marts.yml (data tests + unit test)
  tests/   assert_allocation_ratios_sum_to_one.sql, assert_no_negative_costs.sql
```

## Notes
- Synthetic data only — no employer or confidential information. GPU rates are point-in-time (2026) illustrative.
- Every figure is computed in SQL and verified by `dbt build`; nothing ships if a test fails.
- The cost-accounting → FinOps mapping: overhead absorption → idle-capacity allocation; standard-vs-actual
  variance → spend anomaly; subledger-to-GL reconciliation → the `relationships` test.
