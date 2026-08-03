-- Real, dated, sourced safety/coordination incident log. Pass-through with no modeling --
-- this is a documented public dispute, not an estimate.
select
    incident_date,
    description,
    disputing_party,
    source,
    source_url
from {{ ref('stg_safety_incidents') }}
