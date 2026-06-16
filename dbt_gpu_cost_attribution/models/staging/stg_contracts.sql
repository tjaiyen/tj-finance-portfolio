-- Per-customer usage-based pricing. Revenue is derived from these rates, never invented downstream.
select
    cast(customer_id as varchar)       as customer_id,
    cast(input_token_rate as double)   as input_token_rate,
    cast(output_token_rate as double)  as output_token_rate
from {{ ref('raw_contracts') }}
