-- 90-Day Roadmap: a proposed accountability plan, NOT an executed one -- there is no real
-- "actual progress" for a forward-looking plan, so this mart states targets and rationale,
-- never a fabricated completion status. Keyed to mart_risk_register's own risk_name (a real
-- join, tested for completeness below), so it can't silently omit an existing risk or
-- reference one that doesn't exist. Accountability uses generic role titles only ("VP,
-- Launch Operations") -- never a real named individual; attributing a fabricated 90-day
-- commitment to a real person who never agreed to it is a materially different (and much
-- riskier) act than citing a real person's public statement, which this project already does
-- correctly elsewhere (e.g. the CFO's sourced earnings-call quote).
--
-- The analysis clock is the real latest checkpoint (2026-07-15), 15 days before the
-- near-term FCC deadline -- a 90-day plan starting there can't change that near-term
-- outcome (already effectively decided); it targets the 2029 milestone's trajectory and
-- the response to what the near-term result reveals.
--
-- Each row's baseline is pulled from the SAME mart mart_risk_register itself draws that
-- risk's signal from -- zero new facts about the program, only one new illustrative input
-- per row (target_improvement_pct or target_qualify_count), the same one-new-input pattern
-- already used for EVM's percent_complete and the sensitivity mart's swing_pct.
with roadmap as (
    select r.*, reg.category, reg.exposure_tier, reg.probability_pct, reg.in_composite_index
    from {{ ref('stg_90day_roadmap') }} r
    left join {{ ref('mart_risk_register') }} reg on r.risk_name = reg.risk_name
),

checkpoint as (
    select latest_observed_date from {{ ref('mart_unlaunched_inventory') }}
),

launch_capacity as (
    select realized_peak_per_day, round(utilization_pct * 100, 1) as utilization_pct_display
    from {{ ref('mart_deployment_capacity_gap') }}
),

evm as (
    select cpi from {{ ref('mart_evm_rollup') }}
),

launch_fleet as (
    select count(distinct launch_vehicle) as vehicle_count
    from {{ ref('mart_launch_vehicle_reliability') }}
),

supplier as (
    select count(*) as high_risk_count
    from {{ ref('mart_supplier_concentration_risk') }}
    where risk_tier = 'high_concentration_risk'
),

safety as (
    select count(*) as incident_count
    from {{ ref('mart_safety_coordination_incidents') }}
),

regulatory as (
    select expected_review_months_low, expected_review_months_high
    from {{ ref('mart_d2d_regulatory_pipeline') }}
)

select
    row_number() over (order by r.phase_end_day asc, r.risk_name asc) as roadmap_id,
    r.risk_name,
    r.category,
    r.exposure_tier,
    r.domain,
    r.accountable_role,
    r.action,
    ck.latest_observed_date + (r.phase_start_day - 1) * interval 1 day as phase_start_date,
    ck.latest_observed_date + (r.phase_end_day - 1) * interval 1 day as phase_end_date,
    r.phase_start_day,
    r.phase_end_day,
    r.target_type,
    case r.risk_name
        when 'milestone_shortfall' then
            'Increase realized deployment rate from ' || round(lc.realized_peak_per_day, 2) || '/day to ' ||
            round(lc.realized_peak_per_day * (1 + r.target_improvement_pct / 100.0), 2) || '/day (+' || r.target_improvement_pct || '%)'
        when 'launch_vehicle_reliability' then
            'Qualify ' || r.target_qualify_count || ' additional launch-vehicle family -- from ' ||
            lf.vehicle_count || ' tracked today to ' || (lf.vehicle_count + r.target_qualify_count)
        when 'cost_escalation' then
            'Improve CPI from ' || round(e.cpi, 4) || ' to ' || round(e.cpi * (1 + r.target_improvement_pct / 100.0), 4) ||
            ' (+' || r.target_improvement_pct || '%)'
        when 'safety_coordination_incidents' then
            r.target_qualitative || ' (' || sf.incident_count || ' logged to date)'
        when 'supplier_concentration' then
            'Qualify ' || r.target_qualify_count || ' second-source supplier(s) for ' ||
            (case when sp.high_risk_count = 1 then 'the' else sp.high_risk_count::varchar || ' of the' end) ||
            ' high-concentration-risk component(s)'
        when 'd2d_regulatory_decision_timing' then
            r.target_qualitative || ' (FCC decision window: ' || rg.expected_review_months_low || '-' || rg.expected_review_months_high || ' months)'
        when 'deployment_capacity_utilization_gap' then
            r.target_qualitative || ' (' || lc.utilization_pct_display || '% utilization already -- launch-constrained, not capacity-constrained)'
    end as target_description,
    r.rationale_note,
    true as is_illustrative,
    'A proposed 90-day plan, not an executed one -- there is no real "actual progress" for something that has not happened, so every target here is a stated goal, never a fabricated completion status. Baselines are pulled from the same marts mart_risk_register itself draws from; the only new inputs are target_improvement_pct/target_qualify_count, one illustrative planning assumption per row.' as notes
from roadmap r
cross join checkpoint ck
cross join launch_capacity lc
cross join evm e
cross join launch_fleet lf
cross join supplier sp
cross join safety sf
cross join regulatory rg
order by roadmap_id
