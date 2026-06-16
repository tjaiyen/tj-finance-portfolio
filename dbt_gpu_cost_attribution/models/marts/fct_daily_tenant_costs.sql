-- Per-tenant, per-day fully-loaded cost and gross margin.
--   direct_cost         = allocation_ratio x active_cost      (variable compute)
--   allocated_idle_cost = allocation_ratio x idle_cost        (absorbed overhead)
--   total_cost          = direct_cost + allocated_idle_cost
--   gross_margin_pct    = (revenue - total_cost) / revenue
-- Every figure is computed here in SQL — deterministic, testable, no model in the loop.
with alloc as (
    select * from {{ ref('int_tenant_allocation') }}
),

cluster as (
    select * from {{ ref('int_daily_cluster_cost') }}
),

joined as (
    select
        md5(a.customer_id || '|' || cast(a.usage_date as varchar)) as cost_sk,
        a.usage_date,
        a.customer_id,
        a.tenant_tokens,
        a.allocation_ratio,
        a.revenue,
        round(a.allocation_ratio * cl.active_cost, 4)  as direct_cost,
        round(a.allocation_ratio * cl.idle_cost, 4)    as allocated_idle_cost
    from alloc a
    join cluster cl on a.usage_date = cl.usage_date
),

costed as (
    select
        *,
        round(direct_cost + allocated_idle_cost, 4) as total_cost
    from joined
)

select
    cost_sk,
    usage_date,
    customer_id,
    tenant_tokens,
    allocation_ratio,
    revenue,
    direct_cost,
    allocated_idle_cost,
    total_cost,
    round((revenue - total_cost) / nullif(revenue, 0), 4) as gross_margin_pct,
    case
        when revenue = 0 then 'warning'
        when (revenue - total_cost) / revenue < {{ var('margin_warning_below') }} then 'warning'
        when (revenue - total_cost) / revenue > {{ var('margin_best_above') }} then 'best_in_class'
        else 'standard'
    end as margin_zone
from costed
