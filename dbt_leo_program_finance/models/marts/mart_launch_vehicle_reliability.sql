-- Launch vehicle event counts by family -- the core bottleneck behind the milestone-risk
-- shortfall isn't manufacturing, it's launch supply: two of Amazon Leo's three rocket
-- families have had a disclosed failure or delay this program year.
select
    launch_vehicle,
    count(*) as total_events,
    sum(case when event_type = 'failure' then 1 else 0 end) as failure_events,
    sum(case when event_type = 'delay' then 1 else 0 end) as delay_events,
    sum(case when event_type in ('success', 'success_with_incident') then 1 else 0 end) as success_events,
    sum(case when event_type = 'success_with_incident' then 1 else 0 end) as success_with_incident_events
from {{ ref('stg_launch_vehicle_events') }}
group by launch_vehicle
order by launch_vehicle
