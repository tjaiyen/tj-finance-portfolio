-- Fully illustrative generic make-vs-buy TCO scenario -- not based on real Amazon figures.
-- Demonstrates the make-vs-buy/TCO framework the JD calls for, using representative
-- category labels rather than any claimed real supplier or program data.
with tco as (
    select
        scenario_id,
        category_label,
        option_label,
        unit_cost_usd,
        annual_volume,
        round(unit_cost_usd * annual_volume, 2) as annual_tco_usd,
        is_illustrative,
        notes
    from {{ ref('stg_makevsbuy_scenario') }}
)

select
    scenario_id,
    category_label,
    option_label,
    unit_cost_usd,
    annual_volume,
    annual_tco_usd,
    round(annual_tco_usd - min(annual_tco_usd) over (partition by scenario_id), 2) as tco_delta_vs_cheaper_option_usd,
    is_illustrative,
    notes
from tco
