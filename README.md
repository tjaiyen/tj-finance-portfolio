# Finance Data & AI Portfolio — TJ Jaiyen

[![dbt CI](https://github.com/tjaiyen/tj-finance-portfolio/actions/workflows/dbt-ci.yml/badge.svg)](https://github.com/tjaiyen/tj-finance-portfolio/actions/workflows/dbt-ci.yml)

Six small, runnable projects that show how I work: a cost accountant who builds the data, orchestration,
and AI layers behind finance reporting, with correctness and governance built in — not bolted on.

**Business context:** every month-end close asks the same question — *which accounts moved, are the moves
material, and why?* This repo answers it the way a production finance-data team would: tested dbt models
for the numbers, Airflow for the schedule and recovery, an LLM only for the judgment layer — never the math.

```
raw GL (seed) ──> dbt_finance_variance ──> fct_account_variance (tested mart)
                        ▲                             │
        Airflow + Cosmos orchestration                ▼
        (per-model tasks & retries)         Claude variance agent
                        ▲                  (narrative + exception flags, guardrailed)
GPU events (seed) ──> dbt_gpu_cost_attribution ──> gpu_cost_by_tenant

site/ ──> interactive sandbox (same variance + margin math, runs client-side)
```

## Try it in 60 seconds

```bash
git clone https://github.com/tjaiyen/tj-finance-portfolio
cd tj-finance-portfolio/dbt_finance_variance
pip install dbt-duckdb
dbt build       # 14 tests pass; fct_account_variance is your mart
```

Want the AI layer? Set `ANTHROPIC_API_KEY` and:

```bash
cd ../claude_finance_agent
python main.py  # CFO narrative + exception flags; hallucination guardrail active
```

🔗 Interactive sandbox (no install): **https://tjaiyen.github.io/tj-finance-portfolio/**

---

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

## [`dbt_gpu_cost_attribution/`](./dbt_gpu_cost_attribution) — the same discipline, applied to AI cloud cost
The cost-accounting discipline pointed at AI unit economics. A **dbt** project that attributes shared GPU cost
to tenants: idle cluster capacity is absorbed across tenants by token share — the same **overhead-absorption**
method used to spread shared factory cost in job-order costing — and per-tenant **gross margin** plus a
**margin zone** fall out. Three test tiers guard it: data tests, a **unit test** on the allocation/margin
logic, and **singular tests** (allocation ratios must sum to 1; no negative costs). On the synthetic data it
surfaces a tenant running at a negative margin — the *which customer is unprofitable, and why* question, answered
by tested models. Runs locally on **DuckDB**: `pip install dbt-duckdb` then `dbt build` → 33 tests pass.

## [`agentic_ops_skeleton/`](./agentic_ops_skeleton) — guardrailed multi-agent orchestration
The verify-before-trust discipline, applied to **agent autonomy**. A sanitized, stdlib-only skeleton of an
autonomous ops pipeline — `ingest → score → draft → human-review queue`. Scoring is **deterministic** (the
model never drives a decision); fetched content is treated as **data, not instructions** (header-only parsing
plus a URL allow-list neutralize prompt injection); and a **fail-closed human gate** stands in front of every
irreversible action. Pre-registered `unittest` probes prove the guardrails with **no API calls** — an
injection record's malicious body is ignored, off-list URLs are flagged for a human. `python3 orchestrator.py`
then `python3 -m unittest discover`. Synthetic data only; a clean-room skeleton of a larger private system.

## [`site/`](./site) — interactive case-study site (live)
A static **Vite + Tailwind** page that ties the projects together for a hiring-reviewer audience, with an
interactive **variance / margin sandbox** that runs the same math the dbt mart computes — client-side, no
backend. Auto-deploys to **GitHub Pages** via `.github/workflows/deploy.yml`.
🔗 Live: **https://tjaiyen.github.io/tj-finance-portfolio/**

## Why these six together
Six pieces, same discipline: two dbt projects for the modeled numbers, Airflow/Cosmos for reliable
scheduling and recovery, a Claude agent for the narrative layer, an agentic-ops skeleton for guardrailed
multi-agent autonomy, and site/ to tie it together for a hiring reviewer. The finance variance track and the
GPU cost track use the same method — tested models, deterministic math, orchestrated runs. The AI layers
touch only judgment and language: the variance agent's guardrail rejects any output that references an account
not in the source, and the agentic skeleton treats all fetched content as data, never instructions, with a
human gate before any irreversible action.

*Data in all projects is synthetic. No employer or confidential information is included.*

— Theerayut (TJ) Jaiyen · linkedin.com/in/jaiyentheerayut
