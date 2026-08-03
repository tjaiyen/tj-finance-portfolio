-- The four decomposed drivers must sum exactly to the total variance -- nothing lost or
-- double-counted (mirrors the "allocation ratios sum to 1" governance test in
-- dbt_gpu_cost_attribution). Returns offending rows; an empty result = pass.
select
    cost_center,
    period,
    total_variance,
    sum_of_drivers
from {{ ref('mart_variance_methodology_demo') }}
where abs(total_variance - sum_of_drivers) > 0.01
