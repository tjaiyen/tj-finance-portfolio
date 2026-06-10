"""
Finance Variance Pipeline -- Airflow + Astronomer Cosmos orchestration
----------------------------------------------------------------------
Renders the `dbt_finance_variance` project into native Airflow tasks via
Astronomer Cosmos: every dbt model, seed, and test becomes its own task with
isolated retries and model-level observability in the Airflow UI -- instead of
one opaque `dbt build` bash task.

Why Cosmos over a BashOperator:
  * Model-level lineage and logs in the Airflow UI (not one monolithic log)
  * A failed model retries in isolation -- no full-project rerun
  * dbt tests surface as first-class task failures
Trade-off: DAG parse does a dbt project load; for this project size that cost
is negligible. (At multi-domain scale you would split DAGs by dbt tag and
bridge them with sensors -- see README.)

Downstream of the transform group, a hand-off task reads the freshly built
`fct_account_variance` mart and triggers the Claude variance agent
(claude_finance_agent/) when an API key is configured -- mirroring the
prod pattern: deterministic numbers first, AI judgment second, never the
other way around.
"""

import os
from datetime import datetime, timedelta
from pathlib import Path

from airflow.decorators import task
from airflow.models.dag import DAG

from cosmos import DbtTaskGroup, ProfileConfig, ProjectConfig

# dags/ -> airflow_orchestration/ -> repo root
REPO_ROOT = Path(__file__).resolve().parents[2]
DBT_PROJECT_DIR = REPO_ROOT / "dbt_finance_variance"
DUCKDB_PATH = DBT_PROJECT_DIR / "finance_variance.duckdb"

profile_config = ProfileConfig(
    profile_name="finance_variance",
    target_name="dev",
    # DuckDB profile ships with the repo -- no warehouse, no secrets.
    profiles_yml_filepath=DBT_PROJECT_DIR / "profiles.example.yml",
)

default_args = {
    "owner": "tj",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="finance_variance_pipeline",
    description="dbt variance models (via Cosmos) -> Claude narrative hand-off",
    schedule="0 6 * * 1-5",  # weekday mornings, before the close review
    start_date=datetime(2026, 6, 1),
    catchup=False,
    default_args=default_args,
    tags=["finance", "dbt", "cosmos", "duckdb"],
) as dag:

    # Seed -> staging -> mart -> tests, each as its own retryable Airflow task.
    transform = DbtTaskGroup(
        group_id="dbt_finance_variance",
        # dbt_project_path lives ONLY here -- Cosmos rejects it if duplicated
        # in ExecutionConfig/RenderConfig (mutually exclusive by design).
        project_config=ProjectConfig(dbt_project_path=DBT_PROJECT_DIR),
        profile_config=profile_config,
        operator_args={
            "install_deps": False,  # no packages.yml -- skip dbt deps
        },
    )

    @task
    def draft_variance_narrative() -> dict:
        """Hand off the fresh mart to the AI layer.

        Deterministic part (always runs): read fct_account_variance from DuckDB
        and log the material variances -- numbers come from the tested mart,
        never from a model.

        AI part (only when ANTHROPIC_API_KEY is set): invoke the Claude variance
        agent to draft the CFO narrative + exception flags. Without a key the
        task still succeeds -- the pipeline's correctness never depends on the
        LLM being available.
        """
        import duckdb

        con = duckdb.connect(str(DUCKDB_PATH), read_only=True)
        rows = con.execute(
            """
            select account, variance_abs, variance_pct, is_material
            from fct_account_variance
            order by abs(variance_abs) desc
            """
        ).fetchall()
        con.close()

        material = [r for r in rows if r[3]]
        print(f"fct_account_variance: {len(rows)} accounts, {len(material)} material")
        for account, var_abs, var_pct, _ in material:
            pct = f"{var_pct:+.1%}" if var_pct is not None else "n/a"
            print(f"  MATERIAL  {account:<30} {var_abs:>12,.2f}  ({pct})")

        if os.environ.get("ANTHROPIC_API_KEY"):
            import subprocess

            agent = REPO_ROOT / "claude_finance_agent" / "variance_agent.py"
            sample = REPO_ROOT / "claude_finance_agent" / "sample_data" / "financials_q1_q2.csv"
            subprocess.run(
                ["python", str(agent), str(sample), "--threshold", "0.05"],
                check=True,
            )
        else:
            print("ANTHROPIC_API_KEY not set -- skipping narrative draft (by design).")

        return {"accounts": len(rows), "material": len(material)}

    transform >> draft_variance_narrative()
