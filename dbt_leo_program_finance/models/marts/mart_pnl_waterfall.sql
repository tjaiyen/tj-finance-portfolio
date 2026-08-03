-- Revenue - Direct COGS - Indirect OpEx = Margin, for the same latest period as
-- mart_cashflow_breakdown. Direct/indirect totals are ACTUAL spend (not plan), so
-- this reflects the period as it actually happened, joined to the (separately
-- synthetic) revenue assumption. Illustrative pre-commercial-launch framing: Leo
-- has not launched full service in this scenario, so revenue is a small
-- enterprise-pilot figure, not a claim about real Amazon revenue.
with direct_total as (
    select period, sum(actual_amount_usd) as direct_cogs_usd
    from {{ ref('mart_cashflow_breakdown') }}
    where cost_type = 'direct'
    group by period
),
indirect_total as (
    select period, sum(actual_amount_usd) as indirect_opex_usd
    from {{ ref('mart_cashflow_breakdown') }}
    where cost_type = 'indirect'
    group by period
)
select
    r.period,
    r.revenue_usd,
    d.direct_cogs_usd,
    i.indirect_opex_usd,
    r.revenue_usd - d.direct_cogs_usd as gross_margin_usd,
    r.revenue_usd - d.direct_cogs_usd - i.indirect_opex_usd as operating_margin_usd,
    r.is_illustrative,
    r.notes
from {{ ref('stg_pnl_assumptions') }} r
join direct_total d on d.period = r.period
join indirect_total i on i.period = r.period
