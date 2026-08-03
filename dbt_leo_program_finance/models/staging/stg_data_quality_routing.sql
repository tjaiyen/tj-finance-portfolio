-- Fully synthetic anomaly-category -> role routing table -- generic role titles only,
-- same convention as the 90-day roadmap. Not a claim about Amazon's real org chart.
select
    cast(category as varchar) as category,
    cast(description as varchar) as description,
    cast(routes_to as varchar) as routes_to,
    cast(authority_note as varchar) as authority_note
from {{ ref('raw_data_quality_routing') }}
