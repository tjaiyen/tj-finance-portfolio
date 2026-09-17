-- One row per tenant per day: list cost rolled up across all services, then adjusted by the
-- tenant's committed-use discount (their real cost) and chargeback markup (what they're
-- actually billed internally) -- the two inputs the gold-layer margin calc needs.
with daily_list_cost as (
    select
        usage_date,
        tenant_id,
        sum(list_cost) as total_list_cost
    from {{ ref('silver_usage_priced') }}
    group by usage_date, tenant_id
)

select
    d.usage_date,
    d.tenant_id,
    d.total_list_cost,
    c.contract_type,
    c.committed_use_discount,
    c.chargeback_markup,
    d.total_list_cost * (1 - c.committed_use_discount) as actual_cost,
    d.total_list_cost * (1 - c.committed_use_discount) * c.chargeback_markup as chargeback_revenue
from daily_list_cost d
inner join {{ ref('stg_tenant_contracts') }} c
    on d.tenant_id = c.tenant_id
