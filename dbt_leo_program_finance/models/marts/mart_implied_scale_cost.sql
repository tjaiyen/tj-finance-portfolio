-- Fully transparent derived calculation: publicly-estimated per-satellite cost x Amazon's
-- own stated constellation target. This is a calculation performed here, not a published
-- Amazon figure -- the formula is shown alongside the output, not hidden behind it.
select
    as_of_date,
    low_estimate_usd as unit_cost_low_usd,
    high_estimate_usd as unit_cost_high_usd,
    constellation_target,
    low_estimate_usd * constellation_target as implied_scale_cost_low_usd,
    high_estimate_usd * constellation_target as implied_scale_cost_high_usd,
    'unit_cost_estimate x constellation_target (derived here, not a published Amazon figure)' as calculation_note,
    source,
    source_url
from {{ ref('stg_unit_cost') }}
