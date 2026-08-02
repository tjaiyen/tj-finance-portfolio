-- MODELED RANGE, not a disclosed figure. Two scenarios, both using only rates already
-- disclosed in public reporting -- no new invented numbers:
--   upper: production ran continuously at the disclosed sustained/consistent rate for the
--          full elapsed period since deployment began (the "if Amazon never throttled down"
--          scenario)
--   lower: production was throttled down to track the realized deployment pace instead --
--          consistent with the disclosed fact that Amazon deliberately reduced output once
--          it couldn't launch as fast as it could build. NOTE: realized_peak is a
--          deployment/launch rate, not a production-capacity figure -- it's used here only
--          as a proxy for "production kept pace with what could ship," not as a claim about
--          manufacturing capability.
-- The formulas are shown alongside the outputs so both estimates are checkable, not a black box.
with start_marker as (
    select as_of_date as production_start_date
    from {{ ref('stg_deployment_checkpoints') }}
    where checkpoint_type = 'deployment_start_marker'
    limit 1
),

latest_observed as (
    select as_of_date, cumulative_satellites
    from {{ ref('stg_deployment_checkpoints') }}
    where checkpoint_type = 'observed'
    order by as_of_date desc
    limit 1
),

sustained_rate as (
    select satellites_per_day
    from {{ ref('stg_deployment_rate') }}
    where metric_type = 'sustained_consistent'
    limit 1
),

realized_rate as (
    select satellites_per_day
    from {{ ref('stg_deployment_rate') }}
    where metric_type = 'realized_peak'
    limit 1
)

select
    sm.production_start_date,
    lo.as_of_date as latest_observed_date,
    lo.cumulative_satellites as deployed_count,
    sr.satellites_per_day as assumed_sustained_rate,
    rr.satellites_per_day as assumed_throttled_rate,
    date_diff('day', sm.production_start_date, lo.as_of_date) as elapsed_days,
    round(date_diff('day', sm.production_start_date, lo.as_of_date) * sr.satellites_per_day, 0)
        as modeled_cumulative_produced_upper,
    round(date_diff('day', sm.production_start_date, lo.as_of_date) * sr.satellites_per_day, 0) - lo.cumulative_satellites
        as modeled_unlaunched_inventory_upper,
    round(date_diff('day', sm.production_start_date, lo.as_of_date) * rr.satellites_per_day, 0)
        as modeled_cumulative_produced_lower,
    round(date_diff('day', sm.production_start_date, lo.as_of_date) * rr.satellites_per_day, 0) - lo.cumulative_satellites
        as modeled_unlaunched_inventory_lower,
    'UPPER: elapsed_days x sustained_consistent_rate (production never throttled down). LOWER: elapsed_days x realized_peak deployment rate, used as a proxy for production throttled to track what could actually ship -- NOT a claimed production-capacity figure. Both are illustrative modeled scenarios, not disclosed production figures; real output was somewhere in this range, most likely.'
        as calculation_note
from start_marker sm
cross join latest_observed lo
cross join sustained_rate sr
cross join realized_rate rr
