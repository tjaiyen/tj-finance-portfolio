-- Cumulative launch-vehicle reliability trend: running failure/delay/success
-- counts and adverse-event rate recomputed after each REAL dated event, showing
-- whether launch risk is worsening or easing over the observed period instead of
-- only the current aggregate. Reads stg_launch_vehicle_events directly (not
-- mart_launch_disruption_timeline) because that mart deliberately filters out
-- plain 'success' events -- it's a disruption-only overlay -- and this trend
-- needs the full event stream (including successes) to compute a meaningful
-- cumulative total/adverse-rate. No new data, no is_illustrative column (same
-- precedent as mart_operational_efficiency_trend / mart_launch_disruption_timeline:
-- pure real dates + arithmetic, nothing modeled). The 2 events without a disclosed
-- exact date can't be placed in a chronological running sequence -- they're
-- counted in mart_launch_vehicle_reliability's aggregate but excluded from this
-- trend, same as mart_launch_disruption_timeline already does for its own framing.
with dated as (
    select event_date, launch_vehicle, event_type, description, source, source_url
    from {{ ref('stg_launch_vehicle_events') }}
    where event_date is not null
),

flagged as (
    select
        *,
        case when event_type = 'failure' then 1 else 0 end as is_failure,
        case when event_type = 'delay' then 1 else 0 end as is_delay,
        case when event_type in ('success', 'success_with_incident') then 1 else 0 end as is_success
    from dated
),

undated_count as (
    select count(*) as n
    from {{ ref('mart_launch_disruption_timeline') }}
    where not has_exact_date
)

select
    f.event_date, f.launch_vehicle, f.event_type, f.description, f.source, f.source_url,
    sum(f.is_failure) over (order by f.event_date rows unbounded preceding) as running_failure_events,
    sum(f.is_delay) over (order by f.event_date rows unbounded preceding) as running_delay_events,
    sum(f.is_success) over (order by f.event_date rows unbounded preceding) as running_success_events,
    count(*) over (order by f.event_date rows unbounded preceding) as running_total_events,
    round(
        (sum(f.is_failure) over (order by f.event_date rows unbounded preceding) +
         sum(f.is_delay) over (order by f.event_date rows unbounded preceding))
        / count(*) over (order by f.event_date rows unbounded preceding)::double * 100, 1
    ) as running_adverse_event_rate_pct,
    'Running cumulative counts across ' || cast(count(*) over () as varchar) || ' dated launch events, ordered chronologically. ' ||
    cast(uc.n as varchar) || ' additional real event(s) lack a disclosed exact date and are excluded from this chronological trend (see mart_launch_disruption_timeline).' as calculation_note
from flagged f
cross join undated_count uc
order by f.event_date
