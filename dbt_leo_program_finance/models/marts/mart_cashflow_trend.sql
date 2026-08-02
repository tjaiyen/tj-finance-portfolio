-- Plan / Forecast / Actual cash-flow trend. Forecast is computed, never hardcoded:
-- for elapsed periods forecast = actual; for future periods forecast = plan x the
-- average actual/plan run-rate observed across the elapsed periods -- the same
-- "checkpoint + remaining x realized rate" shape already used for the milestone
-- projection and the Q4 variance projection elsewhere in this project.
with elapsed as (
    select
        actual_amount_usd / plan_amount_usd::double as run_rate
    from {{ ref('stg_cashflow_trend') }}
    where actual_amount_usd is not null
),
avg_run_rate as (
    select avg(run_rate) as rate from elapsed
)
select
    t.period,
    t.plan_amount_usd,
    t.actual_amount_usd,
    case
        when t.actual_amount_usd is not null then t.actual_amount_usd
        else round(t.plan_amount_usd * (select rate from avg_run_rate))
    end as forecast_amount_usd,
    (t.actual_amount_usd is null) as is_forecast,
    t.is_illustrative,
    t.notes
from {{ ref('stg_cashflow_trend') }} t
order by t.period
