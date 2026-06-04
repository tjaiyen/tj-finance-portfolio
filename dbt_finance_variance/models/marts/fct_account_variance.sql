-- Account-level variance: prior vs. current period.
-- Variances are computed here in SQL (deterministic); a downstream report/AI never invents a number.

with financials as (

    select * from {{ ref('stg_financials') }}

),

prior as (
    select
        account,
        amount as prior_amount
    from financials
    where period = '{{ var("prior_period") }}'
),

current_period as (
    select
        account,
        amount as current_amount
    from financials
    where period = '{{ var("current_period") }}'
),

joined as (
    select
        c.account,
        p.prior_amount,
        c.current_amount,
        c.current_amount - p.prior_amount as variance_abs,
        round(
            (c.current_amount - p.prior_amount) / nullif(p.prior_amount, 0)
        , 4) as variance_pct
    from current_period c
    left join prior p on c.account = p.account
)

select
    account,
    prior_amount,
    current_amount,
    variance_abs,
    variance_pct,
    case
        when abs(variance_pct) >= {{ var('materiality_threshold') }} then true
        else false
    end as is_material
from joined
