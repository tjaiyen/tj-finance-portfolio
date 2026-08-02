-- Extends mart_unlaunched_inventory's exact upper/lower methodology (same disclosed
-- sustained_consistent and realized_peak rates) across every real observed checkpoint
-- instead of collapsing it into a single latest-snapshot number -- so the backlog range
-- shows whether it's widening or narrowing, not just how big it is today. Also computes
-- the REAL interval-to-interval launch rate and utilization % between each pair of
-- consecutive checkpoints (using the deployment_start_marker as the first interval's
-- starting point) -- this part is not modeled at all, just arithmetic on real dated counts.
-- Only 3 real observed checkpoints exist -- a thin trend (3 rows, 3 intervals), not a
-- rich monthly series; said explicitly in calculation_note rather than implied away.
with dated_points as (
    select as_of_date, cumulative_satellites, checkpoint_type
    from {{ ref('stg_deployment_checkpoints') }}
    where checkpoint_type in ('observed', 'deployment_start_marker')
),

start_marker as (
    select as_of_date as production_start_date
    from dated_points
    where checkpoint_type = 'deployment_start_marker'
    limit 1
),

sustained_rate as (
    select satellites_per_day from {{ ref('stg_deployment_rate') }} where metric_type = 'sustained_consistent' limit 1
),

realized_rate as (
    select satellites_per_day from {{ ref('stg_deployment_rate') }} where metric_type = 'realized_peak' limit 1
),

capacity_rate as (
    select satellites_per_day from {{ ref('stg_deployment_rate') }} where metric_type = 'capacity_ceiling' limit 1
),

with_prev as (
    select
        as_of_date,
        cumulative_satellites,
        checkpoint_type,
        lag(as_of_date) over (order by as_of_date) as prev_date,
        lag(cumulative_satellites) over (order by as_of_date) as prev_cumulative_satellites
    from dated_points
)

select
    w.as_of_date,
    w.cumulative_satellites as actual_cumulative_deployed,
    date_diff('day', sm.production_start_date, w.as_of_date) as elapsed_days_since_start,
    round(date_diff('day', sm.production_start_date, w.as_of_date) * sr.satellites_per_day, 0) as modeled_cumulative_built_upper,
    round(date_diff('day', sm.production_start_date, w.as_of_date) * rr.satellites_per_day, 0) as modeled_cumulative_built_lower,
    round(date_diff('day', sm.production_start_date, w.as_of_date) * sr.satellites_per_day, 0) - w.cumulative_satellites as modeled_backlog_upper,
    round(date_diff('day', sm.production_start_date, w.as_of_date) * rr.satellites_per_day, 0) - w.cumulative_satellites as modeled_backlog_lower,
    w.prev_date as interval_start_date,
    date_diff('day', w.prev_date, w.as_of_date) as interval_days,
    w.cumulative_satellites - w.prev_cumulative_satellites as interval_satellites,
    round((w.cumulative_satellites - w.prev_cumulative_satellites) / date_diff('day', w.prev_date, w.as_of_date)::double, 3) as interval_realized_rate_per_day,
    round((w.cumulative_satellites - w.prev_cumulative_satellites) / date_diff('day', w.prev_date, w.as_of_date)::double / cr.satellites_per_day * 100, 1) as interval_utilization_pct,
    cr.satellites_per_day as capacity_ceiling_per_day,
    'Real observed checkpoints and real disclosed rates throughout. The modeled_* backlog columns extend mart_unlaunched_inventory''s exact upper/lower methodology (same sustained_consistent and realized_peak rates) to every checkpoint instead of just the latest -- neither is a disclosed production figure. interval_realized_rate_per_day and interval_utilization_pct are not modeled at all: real cumulative counts, real dates, simple arithmetic. Only 3 real observed checkpoints exist -- a thin trend, not a rich monthly series.' as calculation_note
from with_prev w
cross join start_marker sm
cross join sustained_rate sr
cross join realized_rate rr
cross join capacity_rate cr
where w.checkpoint_type = 'observed'
order by w.as_of_date
