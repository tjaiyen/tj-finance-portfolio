-- The framework's targets are fixed, illustrative inputs -- but every KPI is checked against
-- this project's own already-computed marts wherever a comparable real number exists, rather
-- than shipping a scorecard of targets with no reported actuals. Amazon does not disclose
-- Kuiper-specific figures for most of these 54 KPIs (EBITDA margin, ARPU, defect PPM, OEE,
-- etc.), so those honestly resolve to 'no_data' -- inventing a plausible-looking number would
-- be worse than admitting the gap.
with kpis as (
    select * from {{ ref('stg_operational_kpi_framework') }}
),

cap as (
    select realized_peak_per_day from {{ ref('mart_deployment_capacity_gap') }}
),

near_milestone as (
    select modeled_projected_shortfall, status
    from {{ ref('mart_milestone_risk') }}
    order by milestone_date
    limit 1
)

select
    k.domain_order,
    k.domain,
    k.kpi_name,
    k.definition,
    k.target_benchmark,
    k.frequency,
    k.strategic_objective,
    k.is_illustrative,
    k.notes,
    case
        when k.kpi_name = 'Daily Spacecraft Build Velocity'
            then cap.realized_peak_per_day || '/day realized peak (best month on record)'
        when k.kpi_name = 'FCC Milestone Compliance Margin'
            then case
                when nm.status = 'on_track' then 'positive buffer (near-term milestone on track)'
                else '-' || cast(nm.modeled_projected_shortfall as bigint) || ' satellites (near-term milestone shortfall)'
            end
        else null
    end as actual_signal,
    case
        when k.kpi_name = 'Daily Spacecraft Build Velocity'
            then case when cap.realized_peak_per_day >= 4 then 'meets' else 'below' end
        when k.kpi_name = 'FCC Milestone Compliance Margin'
            then case when nm.status = 'on_track' then 'meets' else 'below' end
        else 'no_data'
    end as status
from kpis k
cross join cap
cross join near_milestone nm
order by k.domain_order, k.kpi_name
