with source as (

    select * from {{ ref('raw_service_costs') }}

)

select
    cast(month             as date)                   as month,
    cast(plan_id           as {{ dbt.type_int() }})   as plan_id,
    cast(region            as {{ dbt.type_string() }}) as region,
    cast(cost_to_serve_usd as double) as cost_to_serve_usd
from source
