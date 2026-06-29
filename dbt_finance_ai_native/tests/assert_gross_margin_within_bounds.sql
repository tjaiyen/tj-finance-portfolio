-- Singular data test: gross margin must be a sensible ratio in (-1, 1].
-- Any row outside that band signals a revenue/cost defect. Expect zero rows.

select
    economics_sk,
    gross_margin_pct
from {{ ref('fct_plan_monthly_economics') }}
where gross_margin_pct <= -1
   or gross_margin_pct > 1
