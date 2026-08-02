-- Fully synthetic multi-year OpEx/CapEx/headcount roadmap -- demonstrates the "financial
-- models for headcount planning, OpEx, and CapEx across multi-year program roadmaps" JD
-- line using a generic capital-program shape, not a claim about Amazon's real Leo P&L.
select
    cast(fiscal_year as integer) as fiscal_year,
    cast(opex_usd as bigint) as opex_usd,
    cast(capex_usd as bigint) as capex_usd,
    cast(headcount as integer) as headcount,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_op1_op2_plan') }}
