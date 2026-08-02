-- Fully synthetic capital-investment scenarios -- demonstrates the "ROI frameworks for
-- architecture and supplier decisions" JD line using generic categories, not a real
-- Amazon decision.
select
    cast(scenario_name as varchar) as scenario_name,
    cast(capex_usd as bigint) as capex_usd,
    cast(annual_benefit_usd as bigint) as annual_benefit_usd,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_roi_payback_scenarios') }}
