-- Fully synthetic period-level cash-flow totals -- actual_amount_usd is null for
-- future (not-yet-elapsed) periods; mart_cashflow_trend computes their forecast.
select
    cast(period as varchar) as period,
    cast(plan_amount_usd as bigint) as plan_amount_usd,
    cast(actual_amount_usd as bigint) as actual_amount_usd,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_cashflow_trend') }}
