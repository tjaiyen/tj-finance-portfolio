-- A single open-positions snapshot -- one data point, not a trend. Framed honestly as a
-- scaling signal (active hiring), since no layoff evidence was found in public reporting.
select
    cast(as_of_date as date) as as_of_date,
    cast(open_positions_redmond as bigint) as open_positions_redmond,
    cast(signal as varchar) as signal,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_workforce_signal') }}
