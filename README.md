# Finance Data & AI Portfolio — TJ Jaiyen

[![dbt CI](https://github.com/tjaiyen/tj-finance-portfolio/actions/workflows/dbt-ci.yml/badge.svg)](https://github.com/tjaiyen/tj-finance-portfolio/actions/workflows/dbt-ci.yml)

Three small, runnable layers that show how I work: a cost accountant who builds the data, orchestration,
and AI layers behind finance reporting, with correctness and governance built in — not bolted on.

**Business context:** every month-end close asks the same question — *which accounts moved, are the moves
material, and why?* This repo answers it the way a production finance-data team would: tested dbt models
for the numbers, Airflow for the schedule and recovery, an LLM only for the judgment layer — never the math.

```
raw GL (seed) ──> dbt: staging ──> fct_account_variance (tested mart)
                        ▲                    │
        Airflow + Cosmos orchestration       ▼
        (per-model tasks & retries)   Claude variance agent
                                      (narrative + exception flags, guardrailed)
```

## [`dbt_finance_variance/`](./dbt_finance_variance) — modern-data-stack variance modeling
A real **dbt** project: raw GL seed → typed **staging** model → a tested **`fct_account_variance`** mart
(prior-vs-current variance, % change, materiality flag). Includes schema tests plus a **relationship test**
so the mart can never reference an account that isn't in the source — data governance enforced in CI.
Runs locally on **DuckDB** (no warehouse): `pip install dbt-duckdb` then `dbt build` → 14 tests pass.

## [`airflow_orchestration/`](./airflow_orchestration) — Airflow + Astronomer Cosmos
The dbt project rendered into **native Airflow tasks via Cosmos**: every seed, model, and test is its own
task with isolated retries and model-level observability — not one opaque `dbt build`. A downstream task
hands the fresh mart to the Claude agent (and degrades gracefully when no API key is present). CI runs a
**DagBag import test** on every push, so a broken DAG can't land on `main`.

## [`claude_finance_agent/`](./claude_finance_agent) — AI variance commentary, with guardrails
A Python tool on the **Anthropic SDK** that turns two periods of financials into a CFO-ready narrative plus
structured exception flags. Variances are computed deterministically in code; the model is used only for
judgment and language; and a **hallucination guardrail** rejects any output that references an account not in
the source. The point isn't "AI writes text" — it's knowing where AI earns trust in a close and where a human
must verify.

## Why these three together
Same finance logic, three layers: dbt for the trustworthy modeled data, Airflow/Cosmos for reliable
scheduling and recovery, an AI layer on top for narrative and triage. Deterministic numbers, tested models,
orchestrated runs, AI for judgment — with guardrails at every step.

*Data in both projects is synthetic. No employer or confidential information is included.*

— Theerayut (TJ) Jaiyen · linkedin.com/in/jaiyentheerayut
