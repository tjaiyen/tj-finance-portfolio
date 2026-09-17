-- Typed rate-card rows: list price per service/resource/region before any tenant-level discount.
select
    cast(service as varchar)       as service,
    cast(resource_type as varchar) as resource_type,
    cast(region as varchar)        as region,
    cast(unit as varchar)          as unit,
    cast(list_unit_price as double) as list_unit_price
from {{ ref('raw_cloud_pricing') }}
