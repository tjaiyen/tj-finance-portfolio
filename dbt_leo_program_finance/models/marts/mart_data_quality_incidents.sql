-- Real, dated history of this project's own data-quality incidents -- no is_illustrative
-- column (same precedent as mart_launch_disruption_timeline / mart_launch_reliability_trend:
-- pure real facts, nothing modeled). Cited to this repo's own git commits, a
-- self-referential source that's fully checkable, same discipline as every external
-- citation elsewhere on this page. Not a live system: this is the actual history of two
-- real incidents this project's own tests and a source audit already found and fixed.
select
    incident_date,
    category,
    title,
    root_cause,
    detection_method,
    regression_safeguard,
    commit_sha,
    commit_url
from {{ ref('stg_data_quality_incidents') }}
order by incident_date
