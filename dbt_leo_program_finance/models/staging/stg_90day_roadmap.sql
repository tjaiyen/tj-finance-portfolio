-- Fully synthetic 90-day accountability plan, keyed to mart_risk_register's own risk_name --
-- generic role titles only, never a real named individual (see project-level discipline).
select
    cast(risk_name as varchar) as risk_name,
    cast(domain as varchar) as domain,
    cast(accountable_role as varchar) as accountable_role,
    cast(action as varchar) as action,
    cast(phase_start_day as integer) as phase_start_day,
    cast(phase_end_day as integer) as phase_end_day,
    cast(target_type as varchar) as target_type,
    cast(target_improvement_pct as double) as target_improvement_pct,
    cast(target_qualify_count as integer) as target_qualify_count,
    cast(target_qualitative as varchar) as target_qualitative,
    cast(rationale_note as varchar) as rationale_note
from {{ ref('raw_90day_roadmap') }}
