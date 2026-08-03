# dbt Leo Program Finance

A small, runnable **dbt + DuckDB** project modeling the finance disciplines a Finance Manager would apply to
a large hardware/capital program (case-study framing: Amazon's Amazon Leo satellite broadband program) --
milestone-gated capital governance, cost-escalation tracking, capacity-vs-realized variance, launch-vehicle
reliability, supply-chain concentration risk, safety/coordination incidents, a second regulatory front, and
a make-vs-buy/TCO framework.

**⚠ Not affiliated with, endorsed by, or built using any internal Amazon data.** Every figure describing the
real program is sourced to public reporting (cited inline, per row, with a `source_type`: `company_stated` /
`official_disclosure` / `third_party_estimate`); every figure describing an Amazon internal decision
(make-vs-buy, variance drivers, supplier counts) is fully synthetic and flagged `is_illustrative`. This is an
independent illustrative project applying my own cost-accounting/FP&A methodology to a public case, not a
claim of insider knowledge.

## The idea in one line
Public satellite-deployment, cost, launch-vehicle, and regulatory reporting on Amazon Leo is rich enough to
demonstrate real cross-functional operational-visibility analysis -- without ever needing to invent a real
number.

## What it does
- **seeds** -- dated checkpoints and estimates, each carrying its own `source` / `source_url`
- **staging** -- typed, 1:1 cleaned rows
- **marts**
  - `mart_milestone_risk` -- projects whether Amazon's FCC-mandated satellite-count deadlines
    (1,616 by 2026-07-30; 3,232 by 2029-07-30, per FCC DA 26-553) are reachable from the latest known **observed**
    deployment checkpoint, using the best realized deployment rate as the projection basis --
    shown alongside Amazon's **own** 700-satellite projection for the same date (a separate,
    explicitly labeled company estimate, never conflated with an observation), plus the actual
    disclosed waiver mechanics (a granted conditional waiver means **loss of priority status**,
    not license revocation -- precision on the real consequence matters)
  - `mart_deployment_capacity_gap` -- Kirkland factory's theoretical 5-satellites/day capacity vs.
    the highest realized rate actually achieved (April 2026) -- a real utilization gap even in the
    best month on record, root-caused publicly to launch-vehicle availability, not manufacturing
  - `mart_cost_escalation` -- Amazon's own stated $10B (2019) vs. Quilty Space's $16.5-20B estimate
    (2024) -- a confirmed ~100% cost increase -- kept strictly separate from the $1B YoY headwind
    Amazon's CFO disclosed on the Q1 2026 earnings call (a different metric type, never blended)
  - `mart_implied_scale_cost` -- a fully transparent derived calculation (published per-unit cost x
    Amazon's own stated constellation target), formula shown alongside the output
  - `mart_launch_vehicle_reliability` -- failure/delay/success event counts by rocket family (Atlas V,
    Ariane 6, New Glenn) -- the real bottleneck behind the milestone shortfall is
    launch supply, not manufacturing, per Amazon's own FCC filing language
  - `mart_unlaunched_inventory` -- a **modeled range** of the built-vs-deployed gap: an upper-bound
    scenario (constant production at the disclosed sustained rate) and a lower-bound scenario
    (production throttled to track the realized deployment pace), both built from rates already in
    the seed data -- no public "cumulative produced" figure exists, so this is presented as a range,
    not a single number claiming false precision
  - `mart_supplier_concentration_risk` -- real, publicly-named bottleneck components (OISL terminals,
    rad-hardened semiconductors) with an illustrative supplier-concentration risk tier
  - `mart_safety_coordination_incidents` -- a real, dated, sourced incident log (the Feb 2026 SpaceX
    collision-risk dispute over an Amazon Leo deployment)
  - `mart_d2d_regulatory_pipeline` -- the 5,105-satellite direct-to-device FCC filing and its
    related Globalstar acquisition (~$11.6B, expected to close 2027 -- an M&A timeline, not the
    FCC's own decision date, which is not publicly disclosed for this filing and is not fabricated
    here)
  - `mart_workforce_scaling_signal` -- a single open-positions snapshot, deliberately reported as one
    data point rather than a trend the data can't support
  - `mart_makevsbuy_scenario` / `mart_variance_methodology_demo` -- fully synthetic methodology
    demonstrations of the make-vs-buy/TCO and price-volume-scope-timing variance-decomposition
    frameworks named in the JD, using generic category labels
  - `mart_op1_op2_plan` -- fully synthetic multi-year OpEx/CapEx/headcount roadmap with a computed
    YoY CapEx delta, illustrating the JD's "financial models...across multi-year program roadmaps"
  - `mart_roi_payback_scenarios` -- fully synthetic capital-investment scenarios with computed
    `payback_years` and `roi_pct`, illustrating the JD's "ROI frameworks"
  - `mart_operational_kpi_framework` -- a generic, industry-typical operational-KPI scorecard (54
    KPIs across 9 domains: Finance, Accounting, Spacecraft Production, Launch Operations,
    Logistics & Supply Chain, Systems Engineering, Commercialization & Sales, Vendor Management,
    Inventory & Quality Control) applied to this case; target benchmarks are illustrative, not
    Amazon-disclosed figures -- two of them are cross-checked live on the dashboard against this
    project's own real deployment-rate and milestone-risk marts
  - `mart_cashflow_breakdown` / `mart_cashflow_trend` -- fully synthetic direct/indirect cash-flow
    tracker: a 3-level breakdown (cost type -> 7 categories -> 22 subcategories) for the latest
    period, plus a Plan/Forecast/Actual trend where the forecast for future periods is *computed*
    from the elapsed-period run-rate (the same checkpoint-plus-remaining-times-rate shape as
    `mart_milestone_risk`), never hardcoded. `mart_cashflow_breakdown` also carries per-subcategory
    EVM (EV = plan x `percent_complete`, the one new illustrative input; CV/SV/CPI/SPI follow directly)
  - `mart_evm_rollup` -- program-level Earned Value Management over the same 22 subcategories:
    BAC/AC/EV/CV/SV/CPI/SPI, 3 EAC methods (typical, CPI-based, composite), VAC, and TCPI-to-EAC.
    Deliberately *not* anchored to the real disclosed program-cost figures elsewhere on this page
    (the implied hardware-only bill and the whole-program cost cover different cost scope -- mixing
    them as BAC/AC would compare apples to oranges). In this scenario AC already exceeds BAC, which
    makes TCPI-to-BAC mathematically negative/degenerate -- surfaced as the finding itself, not
    smoothed over; TCPI-to-EAC is the metric that's actually interpretable here
  - `mart_pnl_waterfall` -- illustrative Revenue - Direct COGS - Indirect OpEx = Margin bridge,
    derived from `mart_cashflow_breakdown`'s own totals, not a second disconnected model
  - `mart_program_risk_index` -- a **rule-based** Program Delivery Risk Index over 5 weighted
    signals (milestone shortfall, launch reliability, cost escalation, supplier concentration,
    safety incidents) -- most computed from this project's own real marts above, output as a tier
    (low/watch/elevated/critical), never a bare decimal or a fabricated failure-probability.
    Deliberately does *not* score capacity-utilization-gap as a separate input, since it and launch
    reliability both derive from the same `realized_peak_per_day` number and would double-count
    one root cause
  - `mart_operational_efficiency_trend` -- extends `mart_unlaunched_inventory`'s exact upper/lower
    methodology across every real observed checkpoint (not just the latest), plus the REAL
    interval-to-interval launch rate and utilization % between each pair of checkpoints (pure
    arithmetic on real dates/counts, not modeled at all). Zero new seed data -- reuses the existing
    checkpoint and rate seeds entirely. Only 3 real observed checkpoints exist, so this is a thin
    trend (3 points), said explicitly rather than implied away
  - `mart_launch_disruption_timeline` -- real, dated per-event disruption log (distinct from
    `mart_launch_vehicle_reliability`'s aggregated-by-vehicle rollup), used to overlay actual
    failures/delays onto the efficiency trend; 2 of 3 logged disruptions have no disclosed exact
    date and are surfaced separately in narrative rather than assigned a fabricated interval
  - `mart_risk_register` -- a PMO-style risk register consolidating 7 risk factors into
    probability x impact -> exposure tiers: the 5 signals already scored in
    `mart_program_risk_index` (reused directly -- zero new data, impact tiers reuse that mart's
    own 30/25/20/15/10 weights) plus 2 real risk factors this project tracks but deliberately
    does not fold into the composite (capacity utilization gap, D2D regulatory decision-timing
    uncertainty) -- surfaced as monitored-only rather than force-fit into an impact judgment
    the index itself never made
  - `mart_launch_reliability_trend` -- cumulative failure/delay/success counts and adverse-event
    rate recomputed after each real, dated launch event (sourced from
    `stg_launch_vehicle_events` directly, not `mart_launch_disruption_timeline`, since that mart
    deliberately excludes plain `success` events). Only 1 of the 3 real logged events has a
    disclosed exact date -- the 2 real adverse events (New Glenn failure, Atlas V delay) are
    exactly the ones without one -- so the dashboard deliberately shows a plain statement
    instead of a single-point "trend" chart, rather than dressing up one fact as a line
  - `mart_capitalized_inventory_rollforward` -- translates mart_operational_efficiency_trend's
    backlog range into a modeled dollar value at each real checkpoint (x
    mart_implied_scale_cost's unit-cost range) and rolls it forward beginning -> net change
    -> ending, the capitalization/obsolescence angle this dashboard's own closing
    recommendation already flags as open. Zero new seed data.
  - `mart_eac_sensitivity` -- single-variable sensitivity on mart_evm_rollup's
    eac_composite: CPI and SPI each swept +/-10%/20% independently, the other held at its
    actual value. CPI-swing and SPI-swing produce numerically identical results at every
    swing level -- eac_composite depends only on the product cpi x spi, not on which factor
    moved -- surfaced as one curve on the dashboard, not two overlapping ones. Base case
    (swing_pct = 0) reproduces mart_evm_rollup.eac_composite exactly by construction.
  - `mart_90day_roadmap` -- a proposed 90-day accountability plan, keyed to
    mart_risk_register's own risk_name (a real join, tested for referential integrity and
    completeness below) -- one row per risk, including an honest "no action needed" row for
    the capacity-utilization-gap signal, since capacity was never the actual bottleneck.
    Generic role titles only ("VP, Launch Operations") -- never a real named individual,
    since attributing a fabricated commitment to a real person who never agreed to it is a
    materially different act than citing a real person's public statement (already done
    correctly elsewhere on this page). Not an executed plan: every target is a stated goal,
    never a fabricated completion status -- there is no real "actual progress" for something
    that has not happened. Phase dates anchor to the real latest observed checkpoint
    (2026-07-02, computed dynamically -- not hardcoded, since the underlying checkpoint
    data has already changed once since this mart was first built), well before the
    near-term FCC deadline -- honestly framed as targeting the 2029 trajectory, not a fix
    for an outcome that's already effectively decided.
  - `mart_data_quality_routing` -- a fully synthetic anomaly-category -> role routing
    table (5 categories). Generic role titles only, same convention as the 90-day
    roadmap -- not a claim about Amazon's real org chart. 4 of 5 categories are this
    project's own pipeline concerns (a new "VP Data Governance" role); only
    source_fact_discrepancy is about the Leo business content itself, and that one reuses
    the domain ownership already established in mart_90day_roadmap rather than inventing
    a parallel structure.
  - `mart_data_quality_incidents` -- a real, dated history of this project's own
    data-quality incidents (2 rows), cited to this repo's own git commits -- a
    self-referential source that's fully checkable, same discipline as every external
    citation elsewhere in this project. No is_illustrative column (100% real, nothing
    modeled). Not a live monitoring system: the actual record of a nondeterminism bug and
    a full source-hallucination audit this project's own tests and verification process
    already found and fixed, each with the specific regression safeguard now in place.
- **tests**
  - data tests -- not_null/unique, `accepted_values` on every categorical/status column,
    a `relationships` test tying mart_90day_roadmap's risk_name back to mart_risk_register
  - singular tests -- variance drivers must reconcile exactly to the total (nothing lost or
    double-counted); every illustrative mart's rows must be explicitly flagged `is_illustrative`;
    every risk in mart_risk_register must have a corresponding mart_90day_roadmap action
    (catches a future risk-register addition nobody remembered to assign an owner)

## Run it (~60 seconds, local, no cloud)
```bash
pip install dbt-duckdb
export DBT_PROFILES_DIR=.        # or: cp profiles.example.yml ~/.dbt/profiles.yml
dbt build
```
If you're rebuilding after changing seed column shapes, delete the local `.duckdb` file first --
it's a rebuildable cache, and dbt won't reconcile a changed seed schema against an existing table on its own.

This project runs in CI on every push (`.github/workflows/dbt-ci.yml`, `dbt-build-leo` job) --
the 249-test claim above is an enforced gate, not just a number run locally before committing.
A full column-level lineage graph (`dbt docs generate --static`) is published alongside the
dashboard: [leo-dbt-docs/](../site/src/public/leo-dbt-docs/index.html).

## Structure
```
dbt_leo_program_finance/
  dbt_project.yml
  profiles.example.yml
  seeds/   raw_deployment_checkpoints.csv, raw_deployment_rate.csv, raw_fcc_milestones.csv,
           raw_program_cost_estimates.csv, raw_unit_cost.csv, raw_makevsbuy_scenario.csv,
           raw_variance_demo.csv, raw_launch_vehicle_events.csv, raw_supplier_concentration.csv,
           raw_safety_incidents.csv, raw_d2d_regulatory_pipeline.csv, raw_workforce_signal.csv,
           raw_op1_op2_plan.csv, raw_roi_payback_scenarios.csv, raw_operational_kpi_framework.csv,
           raw_cashflow_breakdown.csv, raw_cashflow_trend.csv, raw_pnl_assumptions.csv,
           raw_90day_roadmap.csv, raw_data_quality_routing.csv, raw_data_quality_incidents.csv
  models/
    staging/   21 typed staging models + staging.yml
    marts/     29 marts + marts.yml
  tests/   assert_variance_drivers_reconcile.sql, assert_illustrative_marts_are_flagged.sql,
           assert_unlaunched_inventory_range_ordered.sql, assert_every_risk_has_a_roadmap_action.sql
  scripts/ export_dashboard_data.py -- exports all marts to the site dashboard's JSON
```

## Notes / limitations
- Deployment checkpoints are dated aggregate snapshots from public reporting, **not a complete
  launch manifest** -- a full mission-by-mission list exists publicly (Wikipedia's "List of Amazon
  Leo launches") and could extend this later.
- `mart_milestone_risk` is a **modeled projection using the best publicly realized rate**, not an
  Amazon-disclosed forecast -- shown with the projection method visible, and alongside Amazon's own
  stated projection where one exists, not as a black-box status.
- `mart_unlaunched_inventory` gives a **range**, not a point estimate: the upper bound assumes
  constant production at the disclosed target/design capacity (5/day at Kirkland) for the entire
  elapsed period; the lower bound assumes production throttled down to track the best real
  deployment interval instead (`realized_peak` is a deployment rate -- the fastest real 15-day
  interval between two well-sourced checkpoints -- used here only as a proxy for "production kept
  pace with the best real shipping stretch," not a claim about manufacturing capability). A
  singular test (`assert_unlaunched_inventory_range_ordered`) proves the lower bound never exceeds
  the upper bound.
- Two launch-vehicle events (the New Glenn failure, the Atlas V delay) don't have a disclosed
  exact date in public reporting -- `date_confidence = 'approximate'` flags this rather than inventing
  a precise date.
- Make-vs-buy, variance-driver, and supplier-count figures are **fully synthetic**, generic-category
  illustrations of the analytical method -- not claims about any real Amazon decision or supplier.
- `mart_program_risk_index` is a **rule-based composite, not a statistical failure-probability
  model** -- there's no real training data for "did a program like this fail," so a fabricated
  probability would be dishonest. The weighted formula (30/25/20/15/10) and every signal's
  real-vs-illustrative provenance are shown directly on the dashboard, not hidden behind a score.
