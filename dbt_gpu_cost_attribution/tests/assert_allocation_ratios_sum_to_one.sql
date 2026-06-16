-- Governance check: per day, the tenant allocation ratios must sum to 1 (every dollar
-- of shared cost is absorbed by exactly one tenant — nothing lost, nothing double-counted).
-- Returns offending days; an empty result = pass.
select
    usage_date,
    round(sum(allocation_ratio), 6) as total_ratio
from {{ ref('int_tenant_allocation') }}
group by usage_date
having abs(sum(allocation_ratio) - 1) > 0.0001
