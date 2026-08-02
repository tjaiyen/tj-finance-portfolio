-- Governance check: any mart carrying illustrative/synthetic data must have every row
-- explicitly flagged is_illustrative = true -- this is what makes the grounded-vs-illustrative
-- separation a first-class, testable property of the project, not just a README claim.
-- Returns offending rows; an empty result = pass.
select 'mart_makevsbuy_scenario' as mart_name, count(*) as unflagged_rows
from {{ ref('mart_makevsbuy_scenario') }}
where is_illustrative is distinct from true
having count(*) > 0

union all

select 'mart_variance_methodology_demo' as mart_name, count(*) as unflagged_rows
from {{ ref('mart_variance_methodology_demo') }}
where is_illustrative is distinct from true
having count(*) > 0
