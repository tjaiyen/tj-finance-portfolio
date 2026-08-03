-- Compares Kirkland factory theoretical capacity against the highest realized deployment
-- rate actually achieved (April 2026) -- even at its best month, the program has been
-- constrained by launch-vehicle availability, not manufacturing capacity (per GeekWire).
with capacity as (
    select satellites_per_day
    from {{ ref('stg_deployment_rate') }}
    where metric_type = 'capacity_ceiling'
),

realized as (
    select satellites_per_day, note, source, source_url
    from {{ ref('stg_deployment_rate') }}
    where metric_type = 'realized_peak'
)

select
    c.satellites_per_day as capacity_ceiling_per_day,
    r.satellites_per_day as realized_peak_per_day,
    round(c.satellites_per_day - r.satellites_per_day, 2) as capacity_gap_per_day,
    round(r.satellites_per_day / c.satellites_per_day, 4) as utilization_pct,
    'launch_vehicle_availability' as constraint_root_cause,
    r.note as realized_peak_note,
    r.source as source,
    r.source_url as source_url
from capacity c
cross join realized r
