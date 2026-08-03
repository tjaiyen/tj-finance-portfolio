-- Synthetic price/volume/scope/timing variance decomposition -- demonstrates the FinOps-
-- standard driver-decomposition method (drivers reconcile to the total, never blended into
-- one number), on illustrative data.
select
    cost_center,
    period,
    budget_amount,
    actual_amount,
    round(actual_amount - budget_amount, 2) as total_variance,
    price_driver,
    volume_driver,
    scope_driver,
    timing_driver,
    round(price_driver + volume_driver + scope_driver + timing_driver, 2) as sum_of_drivers,
    is_illustrative
from {{ ref('stg_variance_demo') }}
