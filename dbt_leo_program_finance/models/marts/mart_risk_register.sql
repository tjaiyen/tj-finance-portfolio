-- Risk Register: consolidates the risk signals already computed elsewhere in this
-- project into one PMO-style register (probability tier x impact tier -> exposure
-- tier) instead of leaving them scattered across 7 different sections. Zero new
-- data: the 5 rows already scored in mart_program_risk_index reuse its own
-- signal_pct columns and its own documented 30/25/20/15/10 weights (mapped to an
-- impact tier below); the other 2 rows are real risk factors this project tracks
-- but deliberately does NOT fold into that composite (see mart_program_risk_index's
-- own comments on why) -- surfaced here as monitored, not force-fit into a
-- comparative impact judgment the index itself never made.
--
-- Exposure tier is a standard probability x impact matrix (impact weighted
-- slightly ahead of probability, a common risk-register convention):
--   high/high -> critical; high/medium or medium/high -> high;
--   high/low, medium/medium, or low/high -> medium; everything else -> low.
with scored as (
    select
        'milestone_shortfall' as risk_name, 'schedule' as category,
        'FCC-mandated satellite-count deadline projected to be missed from the latest observed deployment checkpoint' as description,
        milestone_signal_pct as probability_pct, 'high' as impact_tier,
        true as in_composite_index, 'mart_milestone_risk / mart_program_risk_index' as source_mart
    from {{ ref('mart_program_risk_index') }}

    union all

    select
        'launch_vehicle_reliability', 'technical',
        'Failure/delay rate across the tracked launch-vehicle fleet',
        launch_signal_pct, 'high',
        true, 'mart_launch_vehicle_reliability / mart_program_risk_index'
    from {{ ref('mart_program_risk_index') }}

    union all

    select
        'cost_escalation', 'cost',
        'Program cost growth vs. the prior public estimate',
        cost_signal_pct, 'medium',
        true, 'mart_cost_escalation / mart_program_risk_index'
    from {{ ref('mart_program_risk_index') }}

    union all

    select
        'supplier_concentration', 'supply_chain',
        'Share of tracked bottleneck components in the high-concentration-risk tier',
        supplier_signal_pct, 'medium',
        true, 'mart_supplier_concentration_risk / mart_program_risk_index'
    from {{ ref('mart_program_risk_index') }}

    union all

    select
        'safety_coordination_incidents', 'safety',
        'Real, dated safety/coordination incident(s) logged against the program',
        safety_signal_pct, 'low',
        true, 'mart_safety_coordination_incidents / mart_program_risk_index'
    from {{ ref('mart_program_risk_index') }}
),

monitored as (
    select
        'deployment_capacity_utilization_gap' as risk_name, 'technical' as category,
        'Kirkland factory capacity ceiling vs. the highest realized deployment rate -- deliberately excluded from the composite index above (same root cause as launch reliability, would double-count)' as description,
        round((1 - utilization_pct) * 100, 1) as probability_pct,
        'not_assessed' as impact_tier,
        false as in_composite_index,
        'mart_deployment_capacity_gap' as source_mart
    from {{ ref('mart_deployment_capacity_gap') }}

    union all

    select
        'd2d_regulatory_decision_timing', 'regulatory',
        'Uncertainty span in the FCC''s disclosed review-timeline estimate for the 5,105-satellite direct-to-device filing',
        round((expected_review_months_high - expected_review_months_low) / expected_review_months_high::double * 100, 1),
        'not_assessed',
        false,
        'mart_d2d_regulatory_pipeline'
    from {{ ref('mart_d2d_regulatory_pipeline') }}
),

combined as (
    select *,
        case
            when probability_pct >= 66.7 then 'high'
            when probability_pct >= 33.3 then 'medium'
            else 'low'
        end as probability_tier
    from scored

    union all

    select *,
        case
            when probability_pct >= 66.7 then 'high'
            when probability_pct >= 33.3 then 'medium'
            else 'low'
        end as probability_tier
    from monitored
)

select
    row_number() over (order by in_composite_index desc, probability_pct desc) as risk_id,
    risk_name, category, description,
    probability_pct, probability_tier, impact_tier,
    case
        when impact_tier = 'not_assessed' then 'monitoring_only'
        when probability_tier = 'high' and impact_tier = 'high' then 'critical'
        when (probability_tier = 'high' and impact_tier = 'medium') or (probability_tier = 'medium' and impact_tier = 'high') then 'high'
        when (probability_tier = 'high' and impact_tier = 'low') or (probability_tier = 'medium' and impact_tier = 'medium') or (probability_tier = 'low' and impact_tier = 'high') then 'medium'
        else 'low'
    end as exposure_tier,
    in_composite_index,
    case when in_composite_index then 'scored_in_composite' else 'monitored_not_scored' end as status,
    source_mart,
    true as is_illustrative,
    'Probability tiers reuse each signal''s own already-computed percentage; impact tiers for composite-scored risks reuse the Program Delivery Risk Index''s own documented weights (>=25 -> high, 15-20 -> medium, 10 -> low). Exposure = standard probability x impact matrix. Monitored-only rows show a probability proxy but are not force-fit into the composite''s impact weighting, since the index itself deliberately excludes them.' as notes
from combined
