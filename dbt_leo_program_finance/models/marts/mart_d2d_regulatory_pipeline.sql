-- The direct-to-device FCC filing (5,105 satellites) and its expected decision window,
-- computed from the disclosed 12-18 month review-timeline range -- the calculation is
-- shown via the two computed date columns, not hidden behind a single "expected" date.
select
    milestone_name,
    filing_date,
    satellites_requested,
    review_framework,
    expected_review_months_low,
    expected_review_months_high,
    filing_date + to_months(expected_review_months_low) as earliest_expected_decision,
    filing_date + to_months(expected_review_months_high) as latest_expected_decision,
    related_transaction,
    related_transaction_close_year,
    source,
    source_url
from {{ ref('stg_d2d_regulatory_pipeline') }}
