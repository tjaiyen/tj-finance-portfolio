-- Per-tenant, per-day fully-loaded cost, chargeback revenue, gross margin, and a margin zone.
--   actual_cost         = total_list_cost x (1 - committed_use_discount)
--   chargeback_revenue  = actual_cost x chargeback_markup
--   gross_margin_pct    = (chargeback_revenue - actual_cost) / chargeback_revenue
-- Every figure is computed here in SQL -- deterministic, testable, no model in the loop.
select
    md5(tenant_id || '|' || cast(usage_date as varchar)) as cost_sk,
    usage_date,
    tenant_id,
    contract_type,
    total_list_cost,
    actual_cost,
    chargeback_revenue,
    round((chargeback_revenue - actual_cost) / nullif(chargeback_revenue, 0), 4) as gross_margin_pct,
    case
        when chargeback_revenue = 0 then 'warning'
        when (chargeback_revenue - actual_cost) / chargeback_revenue < {{ var('margin_warning_below') }} then 'warning'
        when (chargeback_revenue - actual_cost) / chargeback_revenue > {{ var('margin_best_above') }} then 'best_in_class'
        else 'standard'
    end as margin_zone
from {{ ref('silver_daily_tenant_cost') }}
