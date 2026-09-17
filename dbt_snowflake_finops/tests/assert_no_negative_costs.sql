-- Cost and revenue components can never be negative (a negative actual_cost would mean the
-- discount math inverted). Returns offending rows; an empty result = pass.
-- Note: gross margin_pct itself can legitimately run low (a thin-margin tenant) -- that's a
-- finding for the margin_zone flag to surface, not a data-integrity bug.
select
    cost_sk,
    actual_cost,
    chargeback_revenue
from {{ ref('fct_daily_tenant_margin') }}
where actual_cost < 0
   or chargeback_revenue < 0
