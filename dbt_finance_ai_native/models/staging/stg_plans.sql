with source as (

    select * from {{ ref('raw_plans') }}

)

select
    cast(plan_id        as {{ dbt.type_int() }})    as plan_id,
    cast(plan_name      as {{ dbt.type_string() }}) as plan_name,
    cast(plan_tier      as {{ dbt.type_string() }}) as plan_tier,
    cast(list_price_usd as double)  as list_price_usd
from source
