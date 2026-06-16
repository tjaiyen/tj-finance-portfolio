-- Typed GPU billing rows. fleet_type lets us keep training compute (R&D) out of COGS downstream.
select
    cast(usage_date as date)          as usage_date,
    cast(fleet_type as varchar)       as fleet_type,
    cast(gpu_type as varchar)         as gpu_type,
    cast(hours_provisioned as double) as hours_provisioned,
    cast(hours_used as double)        as hours_used,
    cast(hourly_rate as double)       as hourly_rate
from {{ ref('raw_gpu_billing') }}
