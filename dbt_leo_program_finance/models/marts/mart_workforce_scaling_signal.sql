-- A single open-positions snapshot, passed through with no embellishment. One data point
-- is not a trend -- this mart deliberately does not claim a hiring trajectory it can't support.
select
    as_of_date,
    open_positions_redmond,
    signal,
    source,
    source_url
from {{ ref('stg_workforce_signal') }}
