-- Canonical, typed rows: one record per account + period.
-- Staging is the only place that touches the raw seed; everything downstream refs this.

with source as (

    select * from {{ ref('raw_financials') }}

)

select
    cast(account as varchar) as account,
    cast(period  as varchar) as period,
    cast(amount  as double)  as amount
from source
