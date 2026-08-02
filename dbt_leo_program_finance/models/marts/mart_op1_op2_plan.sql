-- Pass-through of the synthetic multi-year roadmap, plus a computed year-over-year
-- capex delta so the chart layer doesn't need to re-derive it.
select
    fiscal_year,
    opex_usd,
    capex_usd,
    headcount,
    capex_usd - lag(capex_usd) over (order by fiscal_year) as capex_yoy_change_usd,
    is_illustrative,
    notes
from {{ ref('stg_op1_op2_plan') }}
order by fiscal_year
