-- FCC license-condition satellite-count deadlines, plus the actual disclosed waiver
-- mechanics (regulatory_consequence is precise about what's really at stake -- priority-
-- status loss, not license revocation -- and waiver_requested/_date/_extension_months
-- capture Amazon's own 24-month extension filing separately from the nominal deadline).
select
    cast(milestone_date as date) as milestone_date,
    cast(satellites_required as bigint) as satellites_required,
    cast(regulatory_basis as varchar) as regulatory_basis,
    cast(regulatory_consequence as varchar) as regulatory_consequence,
    cast(waiver_requested as boolean) as waiver_requested,
    cast(waiver_requested_date as date) as waiver_requested_date,
    cast(waiver_requested_extension_months as integer) as waiver_requested_extension_months,
    cast(source as varchar) as source,
    cast(source_url as varchar) as source_url
from {{ ref('raw_fcc_milestones') }}
