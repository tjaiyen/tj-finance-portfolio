-- Per-satellite manufacturing cost estimate, single point-in-time (no trend claimed).
select
    cast(as_of_date as date) as as_of_date,
    cast(low_estimate_usd as bigint) as low_estimate_usd,
    cast(high_estimate_usd as bigint) as high_estimate_usd,
    cast(constellation_target as bigint) as constellation_target,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_unit_cost') }}
