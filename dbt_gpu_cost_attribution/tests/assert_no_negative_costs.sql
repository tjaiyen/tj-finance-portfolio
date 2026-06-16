-- Cost components can never be negative (a negative absorbed cost would mean the
-- allocation math inverted). Returns offending rows; an empty result = pass.
-- Note: gross margin CAN be negative (an unprofitable tenant) — that's a finding, not a bug.
select
    cost_sk,
    direct_cost,
    allocated_idle_cost,
    total_cost
from {{ ref('fct_daily_tenant_costs') }}
where direct_cost < 0
   or allocated_idle_cost < 0
   or total_cost < 0
