-- Dated cumulative-satellite-count checkpoints from public reporting. Not a complete
-- launch manifest -- see project README for that limitation. checkpoint_type distinguishes
-- real observations from Amazon's own forward-looking projection and the elapsed-time
-- reference marker -- never blend these when picking "the latest observed" figure.
select
    cast(as_of_date as date) as as_of_date,
    cast(cumulative_satellites as bigint) as cumulative_satellites,
    cast(checkpoint_type as varchar) as checkpoint_type,
    cast(note as varchar) as note,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_deployment_checkpoints') }}
