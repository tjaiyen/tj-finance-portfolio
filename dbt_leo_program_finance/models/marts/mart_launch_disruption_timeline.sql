-- Real, dated per-event pass-through -- distinct from mart_launch_vehicle_reliability's
-- aggregated-by-vehicle rollup. Used to overlay actual disruption events onto the
-- operational efficiency trend's timeline. has_exact_date is false for the 2 events
-- with no disclosed exact date (New Glenn failure, Vulcan Centaur delay) -- these are
-- never assigned a fabricated date or interval, only surfaced separately in narrative.
select
    event_date,
    launch_vehicle,
    event_type,
    date_confidence,
    (event_date is not null) as has_exact_date,
    description,
    source,
    source_url
from {{ ref('stg_launch_vehicle_events') }}
where event_type in ('failure', 'delay', 'success_with_incident')
order by event_date
