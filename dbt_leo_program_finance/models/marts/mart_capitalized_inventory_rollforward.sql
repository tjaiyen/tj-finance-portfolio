-- Capitalized-inventory roll-forward: translates mart_operational_efficiency_trend's
-- already-modeled backlog range into a modeled dollar value at each real checkpoint,
-- using mart_implied_scale_cost's own published unit-cost range -- then rolls it
-- forward checkpoint-to-checkpoint (beginning -> + net change -> ending), the same
-- shape a real capitalized-WIP-inventory schedule would show for satellites built but
-- not yet launched. Answers the "unlaunched inventory has a real capitalization/
-- obsolescence angle" gap flagged in this dashboard's own Chapter 4 recommendation.
-- No new seed data: reuses the backlog range and unit-cost range wholesale. Low value =
-- low backlog x low unit cost (the narrowest build-out at the cheapest published cost);
-- high value = high backlog x high unit cost -- the mathematically correct pairing for
-- an extreme-to-extreme dollar range when both factors are independently uncertain.
with unit_cost as (
    select unit_cost_low_usd, unit_cost_high_usd
    from {{ ref('mart_implied_scale_cost') }}
),

valued as (
    select
        e.as_of_date,
        e.modeled_backlog_lower,
        e.modeled_backlog_upper,
        round(e.modeled_backlog_lower * uc.unit_cost_low_usd, 0) as modeled_capitalized_value_low_usd,
        round(e.modeled_backlog_upper * uc.unit_cost_high_usd, 0) as modeled_capitalized_value_high_usd
    from {{ ref('mart_operational_efficiency_trend') }} e
    cross join unit_cost uc
)

select
    as_of_date,
    modeled_backlog_lower,
    modeled_backlog_upper,
    modeled_capitalized_value_low_usd,
    modeled_capitalized_value_high_usd,
    lag(modeled_capitalized_value_low_usd) over (order by as_of_date) as modeled_beginning_value_low_usd,
    lag(modeled_capitalized_value_high_usd) over (order by as_of_date) as modeled_beginning_value_high_usd,
    modeled_capitalized_value_low_usd - lag(modeled_capitalized_value_low_usd) over (order by as_of_date) as modeled_net_change_low_usd,
    modeled_capitalized_value_high_usd - lag(modeled_capitalized_value_high_usd) over (order by as_of_date) as modeled_net_change_high_usd,
    'Modeled dollar value of unlaunched (built but not yet deployed) satellite inventory at each real checkpoint -- backlog range from mart_operational_efficiency_trend x unit-cost range from mart_implied_scale_cost, low-with-low and high-with-high. The first checkpoint has no prior period, so its beginning value and net change are null by construction, not missing data.' as calculation_note
from valued
order by as_of_date
