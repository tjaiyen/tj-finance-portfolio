-- Typed cloud usage rows. tags_json is ingested as Snowflake's semi-structured VARIANT type,
-- then unpacked below into the specific tag keys the silver layer actually needs — the same
-- pattern a real cloud billing export (AWS CUR, Azure Cost Management) requires, since tag
-- schemas vary per resource and can't be flattened into a fixed CSV column set upstream.
select
    cast(usage_date as date)      as usage_date,
    cast(tenant_id as varchar)    as tenant_id,
    cast(service as varchar)      as service,
    cast(resource_type as varchar) as resource_type,
    cast(region as varchar)       as region,
    cast(quantity as double)      as quantity,
    cast(unit as varchar)         as unit,
    parse_json(tags_json)         as tags,
    parse_json(tags_json):env::varchar          as tag_env,
    parse_json(tags_json):team::varchar         as tag_team,
    parse_json(tags_json):cost_center::varchar  as tag_cost_center
from {{ ref('raw_cloud_usage') }}
