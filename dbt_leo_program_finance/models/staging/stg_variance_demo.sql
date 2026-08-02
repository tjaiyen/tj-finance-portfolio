-- Synthetic price/volume/scope/timing variance-decomposition demo.
select
    cast(cost_center as varchar) as cost_center,
    cast(period as varchar) as period,
    cast(budget_amount as double) as budget_amount,
    cast(actual_amount as double) as actual_amount,
    cast(price_driver as double) as price_driver,
    cast(volume_driver as double) as volume_driver,
    cast(scope_driver as double) as scope_driver,
    cast(timing_driver as double) as timing_driver,
    cast(is_illustrative as boolean) as is_illustrative
from {{ ref('raw_variance_demo') }}
