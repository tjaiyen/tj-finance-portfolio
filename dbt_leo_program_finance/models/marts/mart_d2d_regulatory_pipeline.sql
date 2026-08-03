-- The direct-to-device FCC filing (5,105 satellites). No expected-decision-window columns
-- here: no public source discloses an FCC review timeline for this specific filing --
-- carrying a fabricated range would be exactly the kind of hallucination this project's own
-- discipline exists to prevent.
select
    milestone_name,
    filing_date,
    satellites_requested,
    review_framework,
    related_transaction,
    related_transaction_close_year,
    related_transaction_source,
    related_transaction_source_url,
    source,
    source_url
from {{ ref('stg_d2d_regulatory_pipeline') }}
