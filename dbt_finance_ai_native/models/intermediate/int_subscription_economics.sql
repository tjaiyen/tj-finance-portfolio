-- Monthly subscription unit economics: revenue, cost to serve, gross profit and
-- margin at the plan x region x month grain. Pure transformation (no surrogate key)
-- so the calculation is independently unit-testable.

with subs as (

    select * from {{ ref('stg_subscription_months') }}

),

costs as (

    select * from {{ ref('stg_service_costs') }}

),

plans as (

    select * from {{ ref('stg_plans') }}

)

select
    subs.month,
    subs.plan_id,
    plans.plan_tier,
    subs.region,
    subs.active_subscriptions,
    subs.mrr_usd,
    cast(coalesce(costs.cost_to_serve_usd, 0.0) as double)                       as cost_to_serve_usd,
    cast(subs.mrr_usd - coalesce(costs.cost_to_serve_usd, 0.0) as double)         as gross_profit_usd,
    cast((subs.mrr_usd - coalesce(costs.cost_to_serve_usd, 0.0)) / nullif(subs.mrr_usd, 0)
         as double)                                                              as gross_margin_pct
from subs
left join costs
    on  subs.month   = costs.month
    and subs.plan_id = costs.plan_id
    and subs.region  = costs.region
left join plans
    on subs.plan_id = plans.plan_id
