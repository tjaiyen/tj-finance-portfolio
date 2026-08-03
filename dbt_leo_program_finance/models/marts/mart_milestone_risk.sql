-- Projects whether each FCC satellite-count milestone is reachable from the latest known
-- OBSERVED deployment checkpoint (checkpoint_type = 'observed' -- Amazon's own forward
-- projection for the same date is a separate, explicitly labeled comparison column, never
-- allowed to be picked up as if it were an observation), using the realized_peak deployment
-- rate as the projection basis. A modeled projection, not an Amazon-disclosed forecast --
-- shown side by side with Amazon's own stated projection where one exists for the same date.
with latest_observed as (
    select as_of_date, cumulative_satellites
    from {{ ref('stg_deployment_checkpoints') }}
    where checkpoint_type = 'observed'
    order by as_of_date desc
    limit 1
),

company_projection as (
    select as_of_date, cumulative_satellites
    from {{ ref('stg_deployment_checkpoints') }}
    where checkpoint_type = 'company_projected'
),

realized_rate as (
    select satellites_per_day
    from {{ ref('stg_deployment_rate') }}
    where metric_type = 'realized_peak'
    limit 1
),

milestones as (
    select
        milestone_date, satellites_required, regulatory_basis, regulatory_consequence,
        waiver_requested, waiver_requested_date, waiver_requested_extension_months
    from {{ ref('stg_fcc_milestones') }}
)

select
    m.milestone_date,
    m.satellites_required,
    m.regulatory_basis,
    m.regulatory_consequence,
    m.waiver_requested,
    m.waiver_requested_date,
    m.waiver_requested_extension_months,
    lo.as_of_date as checkpoint_date,
    lo.cumulative_satellites as checkpoint_count,
    date_diff('day', lo.as_of_date, m.milestone_date) as days_remaining_at_checkpoint,
    round(lo.cumulative_satellites + date_diff('day', lo.as_of_date, m.milestone_date) * rr.satellites_per_day, 0)
        as modeled_projected_count,
    m.satellites_required
        - round(lo.cumulative_satellites + date_diff('day', lo.as_of_date, m.milestone_date) * rr.satellites_per_day, 0)
        as modeled_projected_shortfall,
    cp.cumulative_satellites as company_projected_count,
    case when cp.cumulative_satellites is not null
        then m.satellites_required - cp.cumulative_satellites
        else null
    end as company_projected_shortfall,
    case
        when lo.cumulative_satellites + date_diff('day', lo.as_of_date, m.milestone_date) * rr.satellites_per_day
            >= m.satellites_required
            then 'on_track'
        else 'at_risk'
    end as status
from milestones m
cross join latest_observed lo
cross join realized_rate rr
left join company_projection cp on cp.as_of_date = m.milestone_date
