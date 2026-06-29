# Finance AI-Native — a subscription-finance data product for analysts **and** agents

A dbt project that models subscription unit economics (MRR, cost-to-serve, gross margin, ARPU)
as a **governed data layer that both human analysts and AI agents read from**. Built to mirror the
"AI-native finance analytics engineer" pattern: dbt models + a MetricFlow **semantic layer** + an
enforced **data contract** + 3-tier testing, and it is **adapter-portable** — it runs locally on
**DuckDB** and on **Databricks** (cloud MPP) with only a target swap.

> Demonstration project on synthetic data. Verified end-to-end: `dbt build` → **PASS=29, 0 errors**
> (3 seeds, 6 models, 18 data tests, 1 unit test, 1 singular test, 1 enforced contract).

## What it demonstrates

| Capability | Where |
|---|---|
| **dbt modeling** — layered staging → intermediate → marts | `models/staging`, `models/intermediate`, `models/marts` |
| **Semantic / metrics layer** (MetricFlow) — `mrr`, `cost_to_serve`, `gross_profit`, `gross_margin_pct` (ratio), `arpu` (ratio) | `models/marts/semantic_models.yml` |
| **Data contract** (enforced) on the published fact | `models/marts/_marts.yml` (`contract: enforced: true`) |
| **3-tier testing** — data tests + a dbt **unit test** + a **singular** test | `_staging.yml`, `_intermediate.yml`, `tests/` |
| **AI-consumption design** — every model, column, and metric carries a `description:`, so the governed layer is legible to analysts, Claude, and agents alike | all `_*.yml` |
| **Adapter portability** — DuckDB (local) and Databricks (cloud MPP) | `profiles.yml` (two targets) |

## Architecture

```
seeds (raw_plans, raw_subscription_months, raw_service_costs)
  → staging  (stg_plans, stg_subscription_months, stg_service_costs)     [views]
  → intermediate (int_subscription_economics — the unit-tested calc)      [view]
  → marts    (dim_plan, fct_plan_monthly_economics [contract], metricflow_time_spine)  [tables]
  → semantic layer (metrics: mrr, gross_margin_pct, arpu, ...)
```

`fct_plan_monthly_economics` is the single governed fact (plan × region × month); the semantic layer
defines metrics on top of it so "MRR", "gross margin", and "ARPU" mean exactly one thing — whether a
person writes SQL, an analyst pulls a metric, or an agent resolves it.

## Run it locally (DuckDB — zero cloud setup)

```bash
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
dbt deps
DBT_PROFILES_DIR=. dbt build          # seeds + models + tests + contract  → PASS=29
```

## Run it on Databricks (cloud MPP)

Same code, different target. Credentials come from the environment only — nothing is committed.

```bash
export DBX_HOST="adb-xxxx.azuredatabricks.net"      # workspace host
export DBX_HTTP_PATH="/sql/1.0/warehouses/xxxx"     # SQL warehouse HTTP path
export DBX_TOKEN="dapi..."                           # personal access token (kept local)
export DBX_CATALOG="main"
export DBX_SCHEMA="finance_ai_native"
DBT_PROFILES_DIR=. dbt build -t databricks
```

A free Databricks workspace (Free Edition / trial) with a SQL warehouse is enough to run this.
The model SQL is written portably (`||` concat, `md5`, `nullif`, `cast(... as double/date)`); the only
Databricks-flavored adjustment is the contract `data_type`s in `models/marts/_marts.yml`
(`varchar` → `string`, `integer` → `int`; `double`/`date` are identical).

## Query the metrics (semantic layer)

With `dbt-metricflow` installed (in `requirements.txt`):

```bash
mf query --metrics mrr,gross_margin_pct,arpu --group-by economics_month__month
mf query --metrics gross_margin_pct --group-by plan_tier
```

## Why "AI-native"

The team this is built for designs for humans *and* agents: models, metrics, and documentation are
consumed by Finance analysts, by Claude, and by agents over MCP. This project takes that literally —
the governed semantic layer plus the documentation on every object is the contract that lets an agent
answer "what was gross margin for premium plans last month?" against the *same* definitions an analyst
would use. Pairs with the Anthropic-SDK finance agent and dbt projects elsewhere in this portfolio.
