-- Pass-through: this mart's only job is a stable, domain-grouped ordering for the dashboard
-- scorecard. No computation happens here -- the framework's targets are fixed, illustrative
-- inputs, not derived figures.
select
    domain_order,
    domain,
    kpi_name,
    definition,
    target_benchmark,
    frequency,
    strategic_objective,
    is_illustrative,
    notes
from {{ ref('stg_operational_kpi_framework') }}
order by domain_order, kpi_name
