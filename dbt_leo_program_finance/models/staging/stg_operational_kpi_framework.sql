-- A generic, industry-typical operational-KPI framework (finance, accounting, manufacturing,
-- launch, supply chain, systems engineering, commercial, vendor, and quality domains) applied
-- to this case. Target benchmarks here are NOT sourced to any Amazon disclosure -- they're
-- illustrative targets a Finance Manager would set for a program like this, same discipline as
-- mart_makevsbuy_scenario / mart_variance_methodology_demo.
select
    cast(domain_order as integer) as domain_order,
    cast(domain as varchar) as domain,
    cast(kpi_name as varchar) as kpi_name,
    cast(definition as varchar) as definition,
    cast(target_benchmark as varchar) as target_benchmark,
    cast(frequency as varchar) as frequency,
    cast(strategic_objective as varchar) as strategic_objective,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_operational_kpi_framework') }}
