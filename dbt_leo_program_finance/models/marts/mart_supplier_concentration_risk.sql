-- Real bottleneck components (OISL terminals, rad-hard semiconductors) with an illustrative
-- concentration-risk tier -- the component identity and bottleneck status are real and
-- sourced; the specific supplier count and resulting tier are synthetic estimates.
select
    component_name,
    is_real_bottleneck,
    illustrative_supplier_count,
    case
        when illustrative_supplier_count <= 3 then 'high_concentration_risk'
        when illustrative_supplier_count <= 6 then 'medium_concentration_risk'
        else 'low_concentration_risk'
    end as risk_tier,
    is_illustrative,
    notes,
    source,
    source_url
from {{ ref('stg_supplier_concentration') }}
