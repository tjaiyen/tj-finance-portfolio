-- Completeness check: every risk in mart_risk_register must have a corresponding
-- mart_90day_roadmap row (even if that row's action is "no corrective action needed" --
-- see deployment_capacity_utilization_gap). Catches a future risk-register addition that
-- nobody remembered to give an accountable owner. Returns offending risk names; an empty
-- result = pass.
select reg.risk_name
from {{ ref('mart_risk_register') }} reg
left join {{ ref('mart_90day_roadmap') }} rm on reg.risk_name = rm.risk_name
where rm.risk_name is null
