-- Daily inference-cluster cost, split into two pools:
--   active_cost = compute actually used to serve traffic   (direct variable cost)
--   idle_cost   = provisioned-but-unused capacity          (the overhead pool to absorb)
-- Training compute is excluded — it's R&D, not COGS.
with billing as (
    select *
    from {{ ref('stg_gpu_billing') }}
    where fleet_type = '{{ var("inference_fleet") }}'
)

select
    usage_date,
    round(sum(hours_used * hourly_rate), 4)                          as active_cost,
    round(sum((hours_provisioned - hours_used) * hourly_rate), 4)    as idle_cost
from billing
group by usage_date
