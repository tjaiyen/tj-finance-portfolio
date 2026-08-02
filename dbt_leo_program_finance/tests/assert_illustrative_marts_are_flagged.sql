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

union all

select 'mart_op1_op2_plan' as mart_name, count(*) as unflagged_rows
from {{ ref('mart_op1_op2_plan') }}
where is_illustrative is distinct from true
having count(*) > 0

union all

select 'mart_roi_payback_scenarios' as mart_name, count(*) as unflagged_rows
from {{ ref('mart_roi_payback_scenarios') }}
where is_illustrative is distinct from true
having count(*) > 0

union all

select 'mart_operational_kpi_framework' as mart_name, count(*) as unflagged_rows
from {{ ref('mart_operational_kpi_framework') }}
where is_illustrative is distinct from true
having count(*) > 0
