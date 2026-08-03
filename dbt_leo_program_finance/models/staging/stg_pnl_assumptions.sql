-- Fully synthetic revenue assumption -- Leo has not launched full commercial
-- service in this scenario; illustrative early enterprise-pilot revenue only.
select
    cast(period as varchar) as period,
    cast(revenue_usd as bigint) as revenue_usd,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_pnl_assumptions') }}
