-- payback_years = capex / annual_benefit; roi_pct = annual_benefit / capex. Simple,
-- transparent capital-budgeting math -- the formula is the whole model, nothing hidden.
select
    scenario_name,
    capex_usd,
    annual_benefit_usd,
    round(capex_usd / annual_benefit_usd::double, 2) as payback_years,
    round(annual_benefit_usd / capex_usd::double * 100, 1) as roi_pct,
    is_illustrative,
    notes
from {{ ref('stg_roi_payback_scenarios') }}
order by payback_years
