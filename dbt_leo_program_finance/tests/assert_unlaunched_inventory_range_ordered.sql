-- The lower-bound scenario must never exceed the upper-bound scenario -- proves the range
-- is genuinely ordered (3.46/day < 4.29/day), not an arbitrary pair of numbers.
-- Returns offending rows; an empty result = pass.
select
    modeled_unlaunched_inventory_lower,
    modeled_unlaunched_inventory_upper
from {{ ref('mart_unlaunched_inventory') }}
where modeled_unlaunched_inventory_lower > modeled_unlaunched_inventory_upper
