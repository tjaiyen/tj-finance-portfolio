-- Fully synthetic make-vs-buy TCO scenario -- generic category labels, not real Amazon data.
select
    cast(scenario_id as integer) as scenario_id,
    cast(category_label as varchar) as category_label,
    cast(option_label as varchar) as option_label,
    cast(unit_cost_usd as double) as unit_cost_usd,
    cast(annual_volume as bigint) as annual_volume,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes
from {{ ref('raw_makevsbuy_scenario') }}
