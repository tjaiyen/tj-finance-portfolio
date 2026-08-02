-- The direct-to-device FCC filing (5,105 satellites) and its related Globalstar spectrum
-- transaction -- a second, larger regulatory front distinct from the core Leo constellation.
select
    cast(milestone_name as varchar) as milestone_name,
    cast(filing_date as date) as filing_date,
    cast(satellites_requested as bigint) as satellites_requested,
    cast(review_framework as varchar) as review_framework,
    cast(expected_review_months_low as integer) as expected_review_months_low,
    cast(expected_review_months_high as integer) as expected_review_months_high,
    cast(related_transaction as varchar) as related_transaction,
    cast(related_transaction_close_year as integer) as related_transaction_close_year,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_d2d_regulatory_pipeline') }}
