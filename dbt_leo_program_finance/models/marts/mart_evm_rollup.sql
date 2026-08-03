-- Program-level Earned Value Management roll-up over the same 22 subcategories as
-- mart_cashflow_breakdown -- same period, same cost scope, already reconciled (BAC/AC
-- here are literally the sums of that mart's plan_amount_usd/actual_amount_usd). This
-- is deliberately NOT anchored to the real disclosed program-cost figures elsewhere on
-- this page (mart_implied_scale_cost's hardware-only bill vs. mart_cost_escalation's
-- whole-program cost cover different cost scope) -- mixing those as BAC/AC would compare
-- apples to oranges dressed up as one metric.
--
-- TCPI-to-BAC handling: this scenario's AC already exceeds BAC (see mart_cashflow_trend --
-- actual has run ahead of plan every elapsed quarter). That makes TCPI-to-BAC
-- mathematically negative/degenerate (BAC - AC < 0): "recover to the original budget" is
-- not just unlikely, it's undefined, because more has already been spent than the whole
-- period's budget before the work is even earned. TCPI-to-EAC (using the CPI-based EAC,
-- the primary book number) is the metric that's actually interpretable here, and by
-- construction lands close to CPI itself.
with base as (
    select
        plan_amount_usd, actual_amount_usd, ev_usd
    from {{ ref('mart_cashflow_breakdown') }}
),

totals as (
    select
        sum(plan_amount_usd) as bac,
        sum(actual_amount_usd) as ac,
        sum(ev_usd) as ev
    from base
),

derived as (
    select
        bac, ac, ev,
        ev - ac as cv,
        ev - bac as sv,
        round(ev / ac::double, 4) as cpi,
        round(ev / bac::double, 4) as spi,
        bac - ac as bac_minus_ac
    from totals
)

select
    bac,
    ac,
    ev,
    cv,
    sv,
    cpi,
    spi,
    round(ac + (bac - ev), 0) as eac_typical,
    round(ac + (bac - ev) / cpi, 0) as eac_cpi,
    round(ac + (bac - ev) / (cpi * spi), 0) as eac_composite,
    round(bac - (ac + (bac - ev) / cpi), 0) as vac,
    (bac_minus_ac < 0) as ac_exceeds_bac,
    round((bac - ev) / (bac_minus_ac)::double, 4) as tcpi_to_bac,
    round((bac - ev) / ((ac + (bac - ev) / cpi) - ac)::double, 4) as tcpi_to_eac,
    true as is_illustrative,
    'BAC/AC/EV summed from mart_cashflow_breakdown''s 22 subcategories -- same period, same cost scope. AC already exceeds BAC in this scenario, which makes tcpi_to_bac mathematically negative/degenerate: recovering the original budget is not just unlikely, it is undefined. tcpi_to_eac (using eac_cpi, the primary book number) is the metric that is actually interpretable here.' as notes
from derived
