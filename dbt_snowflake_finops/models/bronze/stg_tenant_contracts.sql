-- Typed per-tenant contract terms: committed-use discount off list price (the tenant's cost
-- basis) and chargeback markup (the internal billback rate — the "revenue" side of the margin
-- calc, same shape as the token-rate contracts in dbt_gpu_cost_attribution).
select
    cast(tenant_id as varchar)              as tenant_id,
    cast(contract_type as varchar)          as contract_type,
    cast(committed_use_discount as double)  as committed_use_discount,
    cast(chargeback_markup as double)       as chargeback_markup
from {{ ref('raw_tenant_contracts') }}
