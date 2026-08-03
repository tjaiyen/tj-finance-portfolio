-- Anomaly-category -> role routing table. Generic role titles only, same convention as
-- the 90-day roadmap -- not a claim about Amazon's real org chart. 4 of 5 categories are
-- this project's own pipeline/engineering concerns (owned by one new illustrative role);
-- only source_fact_discrepancy is about the Leo business content itself, and that one
-- reuses the domain ownership already established in the 90-day roadmap rather than
-- inventing a parallel structure.
select
    category,
    description,
    routes_to,
    authority_note,
    true as is_illustrative,
    'Generic role assignments, same convention as mart_90day_roadmap -- not a claim about a real Amazon org chart.' as notes
from {{ ref('stg_data_quality_routing') }}
