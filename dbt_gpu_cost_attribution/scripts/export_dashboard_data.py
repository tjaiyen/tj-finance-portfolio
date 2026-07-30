#!/usr/bin/env python3
"""Export the built gpu_cost_attribution.duckdb into a static JSON for the
command-center dashboard (site/src/public/gpu_cost_dashboard_data.json).

Read-only pass over already-tested dbt columns. The only arithmetic done here
is aggregation (sum/count/ratio) for the dashboard's KPI tiles -- no cost or
margin logic is computed outside dbt.

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
DB_PATH = HERE.parent / "gpu_cost_attribution.duckdb"
OUT_PATH = HERE.parent.parent / "site" / "src" / "public" / "gpu_cost_dashboard_data.json"

VARS_PATH = HERE.parent / "dbt_project.yml"


def read_thresholds():
    """Pull margin_warning_below / margin_best_above from dbt_project.yml's vars
    block without adding a yaml dependency -- these two lines are simple enough
    to parse directly."""
    warning, best = 0.40, 0.65
    found_warning, found_best = False, False
    for line in VARS_PATH.read_text().splitlines():
        s = line.strip()
        if s.startswith("margin_warning_below:"):
            warning = float(s.split(":", 1)[1].split("#")[0].strip())
            found_warning = True
        elif s.startswith("margin_best_above:"):
            best = float(s.split(":", 1)[1].split("#")[0].strip())
            found_best = True
    if not (found_warning and found_best):
        missing = [n for n, f in (("margin_warning_below", found_warning), ("margin_best_above", found_best)) if not f]
        print(f"warning: {VARS_PATH} did not match expected format for {missing} -- "
              f"falling back to hardcoded default(s) {warning}/{best}, which may silently diverge "
              f"from the real dbt_project.yml vars", file=sys.stderr)
    return warning, best


def rows_as_dicts(cursor):
    cols = [d[0] for d in cursor.description]
    return [dict(zip(cols, row)) for row in cursor.fetchall()]


def main():
    if not DB_PATH.exists():
        sys.exit(f"error: {DB_PATH} not found -- run `dbt build` first")

    con = duckdb.connect(str(DB_PATH), read_only=True)

    tenant_costs = rows_as_dicts(con.execute("""
        select usage_date, customer_id, tenant_tokens, allocation_ratio, revenue,
               direct_cost, allocated_idle_cost, total_cost, gross_margin_pct, margin_zone
        from main.fct_daily_tenant_costs
        order by usage_date, customer_id
    """))

    cluster_costs = rows_as_dicts(con.execute("""
        select usage_date, active_cost, idle_cost
        from main.int_daily_cluster_cost
        order by usage_date
    """))

    totals = rows_as_dicts(con.execute("""
        select
            min(usage_date) as start_date,
            max(usage_date) as end_date,
            round(sum(total_cost), 2) as total_spend,
            round(sum(allocated_idle_cost), 2) as total_idle_cost,
            round(sum(revenue), 2) as total_revenue,
            round((sum(revenue) - sum(total_cost)) / nullif(sum(revenue), 0), 4) as blended_gross_margin_pct,
            round(sum(allocated_idle_cost) / nullif(sum(total_cost), 0), 4) as idle_cost_pct_of_spend
        from main.fct_daily_tenant_costs
    """))[0]

    tenants_in_warning = rows_as_dicts(con.execute("""
        with latest as (
            select customer_id, margin_zone, usage_date,
                   row_number() over (partition by customer_id order by usage_date desc) as rn
            from main.fct_daily_tenant_costs
        )
        select customer_id, margin_zone from latest where rn = 1 and margin_zone = 'warning'
        order by customer_id
    """))

    lowest_margin_tenant = rows_as_dicts(con.execute("""
        select customer_id, round(avg(gross_margin_pct), 4) as avg_margin_pct
        from main.fct_daily_tenant_costs
        group by customer_id
        order by avg_margin_pct asc
        limit 1
    """))[0]

    warning_below, best_above = read_thresholds()

    payload = {
        "project": "dbt_gpu_cost_attribution",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "thresholds": {
            "margin_warning_below": warning_below,
            "margin_best_above": best_above,
        },
        "tenant_costs": tenant_costs,
        "cluster_costs": cluster_costs,
        "summary": {
            "date_range": {"start": str(totals["start_date"]), "end": str(totals["end_date"])},
            "n_days": len(cluster_costs),
            "tenants": sorted({r["customer_id"] for r in tenant_costs}),
            "total_spend": totals["total_spend"],
            "total_idle_cost": totals["total_idle_cost"],
            "total_revenue": totals["total_revenue"],
            "blended_gross_margin_pct": totals["blended_gross_margin_pct"],
            "idle_cost_pct_of_spend": totals["idle_cost_pct_of_spend"],
            "tenants_in_warning": [r["customer_id"] for r in tenants_in_warning],
            "lowest_margin_tenant": lowest_margin_tenant["customer_id"],
            "lowest_margin_tenant_avg_pct": lowest_margin_tenant["avg_margin_pct"],
        },
    }

    def default(o):
        # duckdb returns datetime.date for DATE columns; json needs a str.
        return str(o)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(payload, indent=2, default=default) + "\n")
    print(f"wrote {OUT_PATH} ({len(tenant_costs)} tenant-cost rows, {len(cluster_costs)} cluster-day rows)")


if __name__ == "__main__":
    main()
