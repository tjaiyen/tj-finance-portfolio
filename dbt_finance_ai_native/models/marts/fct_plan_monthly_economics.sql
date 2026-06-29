-- Governed fact table for finance reporting and the semantic layer.
-- One row per plan x region x month, with a deterministic surrogate key.
-- Surrogate key uses md5 + the || concat operator — portable across DuckDB and Databricks.

select
    cast(
        md5(
            cast(month   as {{ dbt.type_string() }}) || '|' ||
            cast(plan_id as {{ dbt.type_string() }}) || '|' ||
            region
        ) as {{ dbt.type_string() }}
    )                       as economics_sk,
    month,
    plan_id,
    plan_tier,
    region,
    active_subscriptions,
    mrr_usd,
    cost_to_serve_usd,
    gross_profit_usd,
    gross_margin_pct
from {{ ref('int_subscription_economics') }}
