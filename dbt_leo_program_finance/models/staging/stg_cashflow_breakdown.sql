-- Fully synthetic latest-period direct/indirect cash-flow breakdown -- generic
-- hardware-program categories, not a real Amazon decision.
select
    cast(period as varchar) as period,
    cast(cost_type as varchar) as cost_type,
    cast(category as varchar) as category,
    cast(subcategory as varchar) as subcategory,
    cast(plan_amount_usd as bigint) as plan_amount_usd,
    cast(actual_amount_usd as bigint) as actual_amount_usd,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_cashflow_breakdown') }}
