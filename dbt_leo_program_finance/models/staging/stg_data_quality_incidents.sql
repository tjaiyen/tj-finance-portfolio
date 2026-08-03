-- Real, dated history of this project's own data-quality incidents -- self-referential
-- citations (this repo's own git commits), fully checkable, no external source needed.
select
    cast(incident_date as date) as incident_date,
    cast(category as varchar) as category,
    cast(title as varchar) as title,
    cast(root_cause as varchar) as root_cause,
    cast(detection_method as varchar) as detection_method,
    cast(regression_safeguard as varchar) as regression_safeguard,
    cast(commit_sha as varchar) as commit_sha,
    cast(commit_url as varchar) as commit_url
from {{ ref('raw_data_quality_incidents') }}
