-- Month-over-month actual-cost variance per tenant, using lag() over the tenant's own history --
-- the exact "which tenant's spend moved and by how much" question a FinOps review needs answered
-- without opening a spreadsheet. Note: the demo seed data covers partial months (a handful of
-- days each in Aug/Sep) -- real production use would normalize for day-count in a still-open
-- current month rather than comparing raw partial-month sums directly, as done here for clarity.
with monthly as (
    select
        tenant_id,
        date_trunc('month', usage_date) as cost_month,
        sum(actual_cost) as monthly_actual_cost
    from {{ ref('silver_daily_tenant_cost') }}
    group by tenant_id, date_trunc('month', usage_date)
),

with_prior as (
    select
        tenant_id,
        cost_month,
        monthly_actual_cost,
        lag(monthly_actual_cost) over (partition by tenant_id order by cost_month) as prior_month_actual_cost
    from monthly
)

select
    tenant_id,
    cost_month,
    monthly_actual_cost,
    prior_month_actual_cost,
    monthly_actual_cost - prior_month_actual_cost as mom_variance_abs,
    round(
        (monthly_actual_cost - prior_month_actual_cost) / nullif(prior_month_actual_cost, 0)
    , 4) as mom_variance_pct
from with_prior
