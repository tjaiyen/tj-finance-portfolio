-- Typed, cleaned API usage telemetry — one row per usage_date / customer / model.
select
    cast(usage_date as date)        as usage_date,
    cast(customer_id as varchar)    as customer_id,
    cast(model_id as varchar)       as model_id,
    cast(input_tokens as bigint)    as input_tokens,
    cast(output_tokens as bigint)   as output_tokens,
    cast(query_count as integer)    as query_count
from {{ ref('raw_api_usage') }}
