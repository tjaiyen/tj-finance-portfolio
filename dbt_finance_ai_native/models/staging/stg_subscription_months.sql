with source as (

    select * from {{ ref('raw_subscription_months') }}

)

select
    cast(month                as date)                  as month,
    cast(plan_id              as {{ dbt.type_int() }})  as plan_id,
    cast(region               as {{ dbt.type_string() }}) as region,
    cast(active_subscriptions as {{ dbt.type_int() }})  as active_subscriptions,
    cast(mrr_usd              as double) as mrr_usd
from source
