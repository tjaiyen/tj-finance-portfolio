-- Factory capacity ceiling vs. realized peak deployment rate (satellites/day).
select
    cast(metric_type as varchar) as metric_type,
    cast(as_of_date as varchar) as as_of_date,
    cast(satellites_per_day as double) as satellites_per_day,
    cast(note as varchar) as note,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_deployment_rate') }}
