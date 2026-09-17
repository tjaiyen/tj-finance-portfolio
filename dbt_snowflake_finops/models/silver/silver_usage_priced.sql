-- Cleaned, conformed, deduplicated usage priced at list rate. Dedup guards against the exact
-- failure mode real billing exports have: a resource re-emitting the same usage record across
-- an export retry. qualify + row_number is the Snowflake-idiomatic dedup (no DuckDB equivalent
-- syntax the same way), keeping the highest-quantity row per natural key if a true duplicate
-- ever appears.
select
    u.usage_date,
    u.tenant_id,
    u.service,
    u.resource_type,
    u.region,
    u.quantity,
    u.unit,
    u.tag_env,
    u.tag_team,
    u.tag_cost_center,
    p.list_unit_price,
    u.quantity * p.list_unit_price as list_cost
from {{ ref('stg_cloud_usage') }} u
inner join {{ ref('stg_cloud_pricing') }} p
    on u.service = p.service
    and u.resource_type = p.resource_type
    and u.region = p.region
qualify row_number() over (
    partition by u.usage_date, u.tenant_id, u.service, u.resource_type, u.region
    order by u.quantity desc
) = 1
