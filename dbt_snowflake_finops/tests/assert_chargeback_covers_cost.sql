-- Governance invariant: chargeback_revenue must always be >= actual_cost (the markup is defined
-- as > 1 on every contract), so no tenant should ever be billed less than they cost to serve.
-- Returns offending rows; an empty result = pass.
select
    cost_sk,
    tenant_id,
    actual_cost,
    chargeback_revenue
from {{ ref('fct_daily_tenant_margin') }}
where chargeback_revenue < actual_cost
