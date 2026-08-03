-- Total-program cost estimates over time (cumulative_total_program) plus the latest
-- confirmed YoY cost headwind (yoy_incremental) -- two distinct metric types, never blended.
select
    cast(as_of_date as date) as as_of_date,
    cast(metric_type as varchar) as metric_type,
    cast(low_estimate_usd as bigint) as low_estimate_usd,
    cast(high_estimate_usd as bigint) as high_estimate_usd,
    cast(source_type as varchar) as source_type,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_program_cost_estimates') }}
