select
    plan_id,
    plan_name,
    plan_tier,
    list_price_usd
from {{ ref('stg_plans') }}
