-- Per-tenant daily token volume, the allocation key, and derived revenue.
--   allocation_ratio = tenant_tokens / daily_total_tokens
-- This ratio is the absorption key — the exact analogue of an overhead absorption
-- rate distributing shared factory cost across jobs, here distributing shared GPU
-- cost across tenants.
with usage as (
    select * from {{ ref('stg_api_usage') }}
),

contracts as (
    select * from {{ ref('stg_contracts') }}
),

per_tenant as (
    select
        usage_date,
        customer_id,
        sum(input_tokens)                  as input_tokens,
        sum(output_tokens)                 as output_tokens,
        sum(input_tokens + output_tokens)  as tenant_tokens
    from usage
    group by usage_date, customer_id
),

daily as (
    select
        usage_date,
        sum(tenant_tokens) as daily_total_tokens
    from per_tenant
    group by usage_date
)

select
    t.usage_date,
    t.customer_id,
    t.input_tokens,
    t.output_tokens,
    t.tenant_tokens,
    round(t.tenant_tokens / nullif(d.daily_total_tokens, 0), 6)                       as allocation_ratio,
    round(t.input_tokens * c.input_token_rate
          + t.output_tokens * c.output_token_rate, 4)                                 as revenue
from per_tenant t
join daily d      on t.usage_date = d.usage_date
join contracts c  on t.customer_id = c.customer_id
