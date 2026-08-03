-- Two distinct metric types, kept strictly separate: cumulative_total_program shows the
-- real escalation trend over time; yoy_incremental is the latest officially-disclosed
-- year-over-year cost headwind (Q1 2026 earnings call) -- NOT additive to the cumulative
-- totals above it, and never blended into one number.
with cumulative as (
    select
        as_of_date,
        metric_type,
        low_estimate_usd,
        high_estimate_usd,
        source_type,
        source,
        source_url,
        lag(high_estimate_usd) over (order by as_of_date) as prior_high_estimate_usd
    from {{ ref('stg_program_cost_estimates') }}
    where metric_type = 'cumulative_total_program'
),

cumulative_with_change as (
    select
        as_of_date,
        metric_type,
        low_estimate_usd,
        high_estimate_usd,
        source_type,
        source,
        source_url,
        case
            when prior_high_estimate_usd is not null
                then round((high_estimate_usd - prior_high_estimate_usd) / prior_high_estimate_usd::double, 4)
            else null
        end as pct_change_from_prior
    from cumulative
),

incremental as (
    select
        as_of_date,
        metric_type,
        low_estimate_usd,
        high_estimate_usd,
        source_type,
        source,
        source_url,
        cast(null as double) as pct_change_from_prior
    from {{ ref('stg_program_cost_estimates') }}
    where metric_type = 'yoy_incremental'
)

select * from cumulative_with_change
union all
select * from incremental
order by as_of_date
