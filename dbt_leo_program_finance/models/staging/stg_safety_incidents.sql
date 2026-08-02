-- Real, dated, sourced safety/coordination incidents. A single row today (the Feb 2026
-- SpaceX collision-risk dispute), structured to extend if more are documented.
select
    cast(incident_date as date) as incident_date,
    cast(description as varchar) as description,
    cast(disputing_party as varchar) as disputing_party,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_safety_incidents') }}
