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

## [`dbt_gpu_cost_attribution/`](./dbt_gpu_cost_attribution) — the same discipline, applied to AI cloud cost
<!-- DRAFT (agent-written documentation per TJ's go-ahead) — polish into your voice. -->
The cost-accounting discipline pointed at AI unit economics. A **dbt** project that attributes shared GPU cost
to tenants: idle cluster capacity is absorbed across tenants by token share — the same **overhead-absorption**
method used to spread shared factory cost in job-order costing — and per-tenant **gross margin** plus a
**margin zone** fall out. Three test tiers guard it: data tests, a **unit test** on the allocation/margin
logic, and **singular tests** (allocation ratios must sum to 1; no negative costs). On the synthetic data it
surfaces a tenant running at a negative margin — the *which customer is unprofitable, and why* question, answered
by tested models. Runs locally on **DuckDB**: `pip install dbt-duckdb` then `dbt build` → 33 tests pass.

## [`site/`](./site) — interactive case-study site (live)
<!-- DRAFT (agent-written documentation per TJ's go-ahead) — polish into your voice. -->
A static **Vite + Tailwind** page that ties the projects together for a hiring-reviewer audience, with an
interactive **variance / margin sandbox** that runs the same math the dbt mart computes — client-side, no
backend. Auto-deploys to **GitHub Pages** via `.github/workflows/deploy.yml`.
🔗 Live: **https://tjaiyen.github.io/tj-finance-portfolio/**

## Why these three together
<!-- TODO TJ: this framing + the ASCII diagram above describe THREE layers, but the repo now also includes
     dbt_gpu_cost_attribution/ and site/ (five top-level pieces). The "both projects" synthetic-data line below
     is also stale. Update the framing / diagram / count in your own voice. -->
Same finance logic, three layers: dbt for the trustworthy modeled data, Airflow/Cosmos for reliable
scheduling and recovery, an AI layer on top for narrative and triage. Deterministic numbers, tested models,
orchestrated runs, AI for judgment — with guardrails at every step.

*Data in both projects is synthetic. No employer or confidential information is included.*

— Theerayut (TJ) Jaiyen · linkedin.com/in/jaiyentheerayut
