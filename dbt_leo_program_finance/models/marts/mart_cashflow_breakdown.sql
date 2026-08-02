-- Latest-period (2026-Q3) direct/indirect cash-flow breakdown, 22 subcategories.
-- category_order/cost_type_order encode build-logical sequencing (not alphabetical)
-- so the dashboard table reads Spacecraft Manufacturing -> Ground Segment ->
-- Launch & Integration -> Test & Qualification, mirroring how a Finance Manager
-- would actually walk a program's direct cost stack.
with base as (
    select
        *,
        case cost_type when 'direct' then 1 else 2 end as cost_type_order,
        case category
            when 'Spacecraft Manufacturing' then 1
            when 'Ground Segment' then 2
            when 'Launch & Integration' then 3
            when 'Test & Qualification' then 4
            when 'Engineering & Program Overhead' then 5
            when 'Facilities & Supply Chain' then 6
            when 'G&A & Corporate Allocation' then 7
            else 99
        end as category_order
    from {{ ref('stg_cashflow_breakdown') }}
)
select
    period,
    cost_type,
    cost_type_order,
    category,
    category_order,
    subcategory,
    plan_amount_usd,
    actual_amount_usd,
    actual_amount_usd - plan_amount_usd as variance_usd,
    round((actual_amount_usd - plan_amount_usd) / plan_amount_usd::double * 100, 1) as variance_pct,
    percent_complete,
    -- EVM per subcategory: PV = plan_amount_usd, AC = actual_amount_usd (both already
    -- above), EV = plan x percent_complete (the one new illustrative input). CV/SV/CPI/SPI
    -- follow directly -- no hidden assumptions beyond percent_complete itself.
    round(plan_amount_usd * percent_complete, 0) as ev_usd,
    round(plan_amount_usd * percent_complete, 0) - actual_amount_usd as cv_usd,
    round(plan_amount_usd * percent_complete, 0) - plan_amount_usd as sv_usd,
    round((plan_amount_usd * percent_complete) / actual_amount_usd::double, 3) as cpi,
    round(percent_complete, 3) as spi,
    is_illustrative,
    notes
from base
order by cost_type_order, category_order, subcategory
