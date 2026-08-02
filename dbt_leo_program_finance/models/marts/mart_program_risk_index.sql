-- Program Delivery Risk Index: a rule-based composite over 5 signals, NOT a
-- statistical failure-probability model (there's no training data for "did this
-- program fail" -- fabricating one would be dishonest). Weighted 30/25/20/15/10
-- (milestone/launch/cost/supplier/safety), each capped 0-1, output as a TIER
-- (low/watch/elevated/critical) rather than a bare decimal -- several inputs are
-- single or few-data-point signals and a decimal score would imply false
-- precision. Capacity utilization gap is deliberately NOT a separate input here:
-- it and launch reliability both derive from the same realized_peak_per_day
-- number in stg_deployment_rate, so scoring both would double-count one root
-- cause. Milestone/launch/cost/safety are computed from this project's own real,
-- sourced marts; supplier concentration blends a real bottleneck-component list
-- with illustrative supplier counts (flagged per-signal on the dashboard, not
-- averaged away).
with near_milestone as (
    select modeled_projected_shortfall, satellites_required
    from {{ ref('mart_milestone_risk') }}
    order by milestone_date
    limit 1
),

launch_agg as (
    select
        sum(failure_events) as total_failures,
        sum(delay_events) as total_delays,
        sum(total_events) as total_events
    from {{ ref('mart_launch_vehicle_reliability') }}
),

cost_latest as (
    select pct_change_from_prior
    from {{ ref('mart_cost_escalation') }}
    where metric_type = 'cumulative_total_program' and pct_change_from_prior is not null
    order by as_of_date desc
    limit 1
),

supplier_agg as (
    select
        sum(case when risk_tier = 'high_concentration_risk' then 1 else 0 end) as high_risk_count,
        count(*) as total_count
    from {{ ref('mart_supplier_concentration_risk') }}
),

safety_agg as (
    select count(*) as incident_count
    from {{ ref('mart_safety_coordination_incidents') }}
),

signals as (
    select
        least(1.0, greatest(0.0, nm.modeled_projected_shortfall / nm.satellites_required::double)) as milestone_signal,
        (la.total_failures + la.total_delays) / la.total_events::double as launch_signal,
        least(1.0, greatest(0.0, ce.pct_change_from_prior)) as cost_signal,
        sa.high_risk_count / sa.total_count::double as supplier_signal,
        case when sf.incident_count > 0 then 1.0 else 0.0 end::double as safety_signal
    from near_milestone nm
    cross join launch_agg la
    cross join cost_latest ce
    cross join supplier_agg sa
    cross join safety_agg sf
),

weighted as (
    select
        milestone_signal, launch_signal, cost_signal, supplier_signal, safety_signal,
        milestone_signal * 0.30 as milestone_weighted,
        launch_signal * 0.25 as launch_weighted,
        cost_signal * 0.20 as cost_weighted,
        supplier_signal * 0.15 as supplier_weighted,
        safety_signal * 0.10 as safety_weighted
    from signals
),

totaled as (
    select
        *,
        milestone_weighted + launch_weighted + cost_weighted + supplier_weighted + safety_weighted as composite_score
    from weighted
)

select
    round(composite_score * 100, 1) as composite_score_pct,
    case
        when composite_score < 0.25 then 'low'
        when composite_score < 0.50 then 'watch'
        when composite_score < 0.75 then 'elevated'
        else 'critical'
    end as risk_tier,
    round(milestone_signal * 100, 1) as milestone_signal_pct,
    round(launch_signal * 100, 1) as launch_signal_pct,
    round(cost_signal * 100, 1) as cost_signal_pct,
    round(supplier_signal * 100, 1) as supplier_signal_pct,
    round(safety_signal * 100, 1) as safety_signal_pct,
    round(milestone_weighted / composite_score * 100, 1) as milestone_attribution_pct,
    round(launch_weighted / composite_score * 100, 1) as launch_attribution_pct,
    round(cost_weighted / composite_score * 100, 1) as cost_attribution_pct,
    round(supplier_weighted / composite_score * 100, 1) as supplier_attribution_pct,
    round(safety_weighted / composite_score * 100, 1) as safety_attribution_pct,
    true as is_illustrative,
    'Composite index over 5 signals, weighted 30/25/20/15/10 (milestone/launch/cost/supplier/safety). A rule-based index, not a statistical failure-probability model.' as notes
from totaled
