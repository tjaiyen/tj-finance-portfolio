#!/usr/bin/env python3
"""Export the built leo_program_finance.duckdb into a static JSON for the
site dashboard (site/src/public/leo_finance_dashboard_data.json).

Read-only pass over already-tested dbt marts. No cost/risk logic is computed
here -- every number in the payload comes straight from a dbt mart column.

Run after `dbt build`:
    DBT_PROFILES_DIR=. dbt build
    python3 scripts/export_dashboard_data.py
"""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import duckdb

HERE = Path(__file__).resolve().parent
DB_PATH = HERE.parent / "leo_program_finance.duckdb"
OUT_PATH = HERE.parent.parent / "site" / "src" / "public" / "leo_finance_dashboard_data.json"


def rows_as_dicts(cursor):
    cols = [d[0] for d in cursor.description]
    return [dict(zip(cols, row)) for row in cursor.fetchall()]


def main():
    if not DB_PATH.exists():
        sys.exit(f"error: {DB_PATH} not found -- run `dbt build` first")

    con = duckdb.connect(str(DB_PATH), read_only=True)

    milestone_risk = rows_as_dicts(con.execute("""
        select milestone_date, satellites_required, regulatory_basis, regulatory_consequence,
               waiver_requested, waiver_requested_date, waiver_requested_extension_months,
               checkpoint_date, checkpoint_count, days_remaining_at_checkpoint,
               modeled_projected_count, modeled_projected_shortfall,
               company_projected_count, company_projected_shortfall, status
        from main.mart_milestone_risk
        order by milestone_date
    """))

    launch_vehicle_reliability = rows_as_dicts(con.execute("""
        select launch_vehicle, total_events, failure_events, delay_events, success_events,
               success_with_incident_events
        from main.mart_launch_vehicle_reliability
        order by launch_vehicle
    """))

    unlaunched_inventory = rows_as_dicts(con.execute("""
        select production_start_date, latest_observed_date, deployed_count,
               assumed_sustained_rate, assumed_throttled_rate, elapsed_days,
               modeled_cumulative_produced_upper, modeled_unlaunched_inventory_upper,
               modeled_cumulative_produced_lower, modeled_unlaunched_inventory_lower,
               calculation_note
        from main.mart_unlaunched_inventory
    """))[0]

    supplier_concentration = rows_as_dicts(con.execute("""
        select component_name, is_real_bottleneck, illustrative_supplier_count, risk_tier,
               is_illustrative, notes, source, source_url
        from main.mart_supplier_concentration_risk
        order by illustrative_supplier_count
    """))

    safety_incidents = rows_as_dicts(con.execute("""
        select incident_date, description, disputing_party, source, source_url
        from main.mart_safety_coordination_incidents
        order by incident_date
    """))

    d2d_pipeline = rows_as_dicts(con.execute("""
        select milestone_name, filing_date, satellites_requested, review_framework,
               expected_review_months_low, expected_review_months_high,
               earliest_expected_decision, latest_expected_decision, related_transaction,
               related_transaction_close_year, source, source_url
        from main.mart_d2d_regulatory_pipeline
    """))[0]

    workforce_signal = rows_as_dicts(con.execute("""
        select as_of_date, open_positions_redmond, signal, source, source_url
        from main.mart_workforce_scaling_signal
    """))[0]

    capacity_gap = rows_as_dicts(con.execute("""
        select capacity_ceiling_per_day, realized_peak_per_day, capacity_gap_per_day,
               utilization_pct, constraint_root_cause, realized_peak_note, source, source_url
        from main.mart_deployment_capacity_gap
    """))[0]

    cost_escalation = rows_as_dicts(con.execute("""
        select as_of_date, metric_type, low_estimate_usd, high_estimate_usd, source_type,
               source, source_url, pct_change_from_prior
        from main.mart_cost_escalation
        order by as_of_date
    """))

    implied_scale_cost = rows_as_dicts(con.execute("""
        select as_of_date, unit_cost_low_usd, unit_cost_high_usd, constellation_target,
               implied_scale_cost_low_usd, implied_scale_cost_high_usd, calculation_note,
               source, source_url
        from main.mart_implied_scale_cost
    """))[0]

    makevsbuy = rows_as_dicts(con.execute("""
        select scenario_id, category_label, option_label, unit_cost_usd, annual_volume,
               annual_tco_usd, tco_delta_vs_cheaper_option_usd, is_illustrative, notes
        from main.mart_makevsbuy_scenario
        order by scenario_id, annual_tco_usd
    """))

    variance_demo = rows_as_dicts(con.execute("""
        select cost_center, period, budget_amount, actual_amount, total_variance,
               price_driver, volume_driver, scope_driver, timing_driver, sum_of_drivers,
               is_illustrative
        from main.mart_variance_methodology_demo
    """))

    deployment_checkpoints = rows_as_dicts(con.execute("""
        select as_of_date, cumulative_satellites, checkpoint_type, note, source, source_url
        from main.stg_deployment_checkpoints
        order by as_of_date
    """))

    op1_op2_plan = rows_as_dicts(con.execute("""
        select fiscal_year, opex_usd, capex_usd, headcount, capex_yoy_change_usd, is_illustrative, notes
        from main.mart_op1_op2_plan
        order by fiscal_year
    """))

    roi_payback_scenarios = rows_as_dicts(con.execute("""
        select scenario_name, capex_usd, annual_benefit_usd, payback_years, roi_pct, is_illustrative, notes
        from main.mart_roi_payback_scenarios
        order by payback_years
    """))

    operational_kpi_framework = rows_as_dicts(con.execute("""
        select domain_order, domain, kpi_name, definition, target_benchmark, frequency,
               strategic_objective, actual_signal, status, is_illustrative, notes
        from main.mart_operational_kpi_framework
        order by domain_order, kpi_name
    """))

    cashflow_breakdown = rows_as_dicts(con.execute("""
        select period, cost_type, cost_type_order, category, category_order, subcategory,
               plan_amount_usd, actual_amount_usd, variance_usd, variance_pct,
               percent_complete, ev_usd, cv_usd, sv_usd, cpi, spi,
               is_illustrative, notes
        from main.mart_cashflow_breakdown
        order by cost_type_order, category_order, subcategory
    """))

    evm_rollup = rows_as_dicts(con.execute("""
        select bac, ac, ev, cv, sv, cpi, spi, eac_typical, eac_cpi, eac_composite,
               vac, ac_exceeds_bac, tcpi_to_bac, tcpi_to_eac, is_illustrative, notes
        from main.mart_evm_rollup
    """))[0]

    cashflow_trend = rows_as_dicts(con.execute("""
        select period, plan_amount_usd, actual_amount_usd, forecast_amount_usd,
               is_forecast, is_illustrative, notes
        from main.mart_cashflow_trend
        order by period
    """))

    pnl_waterfall = rows_as_dicts(con.execute("""
        select period, revenue_usd, direct_cogs_usd, indirect_opex_usd,
               gross_margin_usd, operating_margin_usd, is_illustrative, notes
        from main.mart_pnl_waterfall
    """))[0]

    program_risk_index = rows_as_dicts(con.execute("""
        select composite_score_pct, risk_tier, milestone_signal_pct, launch_signal_pct,
               cost_signal_pct, supplier_signal_pct, safety_signal_pct,
               milestone_attribution_pct, launch_attribution_pct, cost_attribution_pct,
               supplier_attribution_pct, safety_attribution_pct, is_illustrative, notes
        from main.mart_program_risk_index
    """))[0]

    operational_efficiency_trend = rows_as_dicts(con.execute("""
        select as_of_date, actual_cumulative_deployed, elapsed_days_since_start,
               modeled_cumulative_built_upper, modeled_cumulative_built_lower,
               modeled_backlog_upper, modeled_backlog_lower, interval_start_date,
               interval_days, interval_satellites, interval_realized_rate_per_day,
               interval_utilization_pct, capacity_ceiling_per_day, calculation_note
        from main.mart_operational_efficiency_trend
        order by as_of_date
    """))

    launch_disruption_timeline = rows_as_dicts(con.execute("""
        select event_date, launch_vehicle, event_type, date_confidence, has_exact_date,
               description, source, source_url
        from main.mart_launch_disruption_timeline
        order by event_date
    """))

    risk_register = rows_as_dicts(con.execute("""
        select risk_id, risk_name, category, description, probability_pct, probability_tier,
               impact_tier, exposure_tier, in_composite_index, status, source_mart,
               is_illustrative, notes
        from main.mart_risk_register
        order by risk_id
    """))

    launch_reliability_trend = rows_as_dicts(con.execute("""
        select event_date, launch_vehicle, event_type, description, source, source_url,
               running_failure_events, running_delay_events, running_success_events,
               running_total_events, running_adverse_event_rate_pct, calculation_note
        from main.mart_launch_reliability_trend
        order by event_date
    """))

    capitalized_inventory_rollforward = rows_as_dicts(con.execute("""
        select as_of_date, modeled_backlog_lower, modeled_backlog_upper,
               modeled_capitalized_value_low_usd, modeled_capitalized_value_high_usd,
               modeled_beginning_value_low_usd, modeled_beginning_value_high_usd,
               modeled_net_change_low_usd, modeled_net_change_high_usd, calculation_note
        from main.mart_capitalized_inventory_rollforward
        order by as_of_date
    """))

    eac_sensitivity = rows_as_dicts(con.execute("""
        select driver, swing_pct, swung_value, eac_composite_usd, eac_composite_base_usd,
               delta_from_base_usd, is_illustrative, notes
        from main.mart_eac_sensitivity
        order by driver, swing_pct
    """))

    payload = {
        "project": "dbt_leo_program_finance",
        "disclaimer": (
            "Independent illustrative project. Not affiliated with, endorsed by, or built "
            "using any internal Amazon data. Figures describing the real program are sourced "
            "to public reporting (see source/source_url per row); figures describing an "
            "Amazon internal decision (make-vs-buy, variance drivers) are fully synthetic "
            "and flagged is_illustrative."
        ),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "deployment_checkpoints": deployment_checkpoints,
        "milestone_risk": milestone_risk,
        "capacity_gap": capacity_gap,
        "cost_escalation": cost_escalation,
        "implied_scale_cost": implied_scale_cost,
        "makevsbuy": makevsbuy,
        "variance_demo": variance_demo,
        "launch_vehicle_reliability": launch_vehicle_reliability,
        "unlaunched_inventory": unlaunched_inventory,
        "supplier_concentration": supplier_concentration,
        "safety_incidents": safety_incidents,
        "d2d_pipeline": d2d_pipeline,
        "workforce_signal": workforce_signal,
        "op1_op2_plan": op1_op2_plan,
        "roi_payback_scenarios": roi_payback_scenarios,
        "operational_kpi_framework": operational_kpi_framework,
        "cashflow_breakdown": cashflow_breakdown,
        "cashflow_trend": cashflow_trend,
        "pnl_waterfall": pnl_waterfall,
        "program_risk_index": program_risk_index,
        "operational_efficiency_trend": operational_efficiency_trend,
        "launch_disruption_timeline": launch_disruption_timeline,
        "evm_rollup": evm_rollup,
        "risk_register": risk_register,
        "launch_reliability_trend": launch_reliability_trend,
        "capitalized_inventory_rollforward": capitalized_inventory_rollforward,
        "eac_sensitivity": eac_sensitivity,
    }

    def default(o):
        # duckdb returns datetime.date for DATE columns; json needs a str.
        return str(o)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(payload, indent=2, default=default) + "\n")
    print(f"wrote {OUT_PATH} ({len(milestone_risk)} milestone rows, {len(cost_escalation)} cost-escalation rows)")


if __name__ == "__main__":
    main()
