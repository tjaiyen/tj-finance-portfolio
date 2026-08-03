-- Launch vehicle events by family (success / success_with_incident / delay / failure).
-- event_date is intentionally nullable -- two real events (New Glenn failure, Vulcan
-- delay) don't have a disclosed exact date in public reporting; date_confidence flags this.
select
    cast(event_date as date) as event_date,
    cast(launch_vehicle as varchar) as launch_vehicle,
    cast(event_type as varchar) as event_type,
    cast(date_confidence as varchar) as date_confidence,
    cast(description as varchar) as description,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_launch_vehicle_events') }}
