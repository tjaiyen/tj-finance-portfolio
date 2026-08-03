-- The direct-to-device FCC filing (5,105 satellites) and its related Globalstar acquisition --
-- a second, larger regulatory front distinct from the core Leo constellation. No numeric FCC
-- review-timeline estimate is carried here: no public source discloses one for this specific
-- filing (checked directly; a prior 12-18-month figure was found to be unsourced/fabricated
-- and removed, not replaced with a fake distribution).
select
    cast(milestone_name as varchar) as milestone_name,
    cast(filing_date as date) as filing_date,
    cast(satellites_requested as bigint) as satellites_requested,
    cast(review_framework as varchar) as review_framework,
    cast(related_transaction as varchar) as related_transaction,
    cast(related_transaction_close_year as integer) as related_transaction_close_year,
    cast(related_transaction_source as varchar) as related_transaction_source,
    cast(related_transaction_source_url as varchar) as related_transaction_source_url,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_d2d_regulatory_pipeline') }}
