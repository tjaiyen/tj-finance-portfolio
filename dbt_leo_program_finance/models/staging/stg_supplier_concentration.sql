-- Real bottleneck components (OISL terminals, rad-hard semiconductors) named in public
-- reporting; illustrative_supplier_count is a synthetic estimate, not a disclosed figure.
select
    cast(component_name as varchar) as component_name,
    cast(is_real_bottleneck as boolean) as is_real_bottleneck,
    cast(illustrative_supplier_count as integer) as illustrative_supplier_count,
    cast(is_illustrative as boolean) as is_illustrative,
    cast(notes as varchar) as notes,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_supplier_concentration') }}
