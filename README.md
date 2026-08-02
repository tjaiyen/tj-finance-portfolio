# Finance Data & AI Portfolio — TJ Jaiyen

[![dbt CI](https://github.com/tjaiyen/tj-finance-portfolio/actions/workflows/dbt-ci.yml/badge.svg)](https://github.com/tjaiyen/tj-finance-portfolio/actions/workflows/dbt-ci.yml)

Eight small, runnable projects that show how I work: a cost accountant who builds the data, orchestration,
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
python variance_agent.py sample_data/financials_q1_q2.csv --threshold 0.05  # CFO narrative + exception flags; hallucination guardrail active
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

## [`dbt_leo_program_finance/`](./dbt_leo_program_finance) — cross-functional capital-program visibility, applied to a public case
The same cost-accounting discipline pointed at a large hardware/capital program's full operational picture —
milestone-gated spend tracking, cost-escalation analysis, launch-vehicle reliability, supply-chain
concentration risk, safety/coordination incidents, a second regulatory front, and a make-vs-buy/TCO framework
— case-study framing: Amazon's Amazon Leo satellite broadband program. **Not affiliated with, endorsed by, or
built using any internal Amazon data** — every figure describing the real program is sourced to public
reporting (Amazon's own 10-K/earnings disclosures and FCC filings, third-party market analysis, cited inline
per row with an evidence-tier badge); every figure describing an internal decision (make-vs-buy, variance
drivers, supplier counts) is fully synthetic and flagged `is_illustrative`. Twenty-two **dbt** marts — including a
multi-year OP1/OP2 OpEx/CapEx/headcount roadmap, an ROI/payback framework, a 54-KPI operational scorecard,
a 3-level direct/indirect cash-flow tracker (Plan/Forecast/Actual, forecast computed from the elapsed-period
run-rate) with per-subcategory **Earned Value Management** (EV/CPI/SPI) rolling up to a program-level
**EAC/VAC/TCPI** — including the honest edge case where actual cost already exceeds budget, making
TCPI-to-original-budget mathematically negative rather than smoothed into a fake number — plus a derived P&L
bridge and cost-driver Pareto, a rule-based **Program Delivery Risk Index** weighting 5 signals — most drawn
from this project's own real marts — into a tier, never a fabricated failure-probability, and a
manufacturing-to-launch **efficiency trend** that extends the milestone-risk and unlaunched-inventory
methodology across every real checkpoint instead of just the latest, using zero new data — the same disclosed
rates, computed at more points. Closes the JD's own "financial models...across multi-year program roadmaps"
and "ROI frameworks" lines — plus a milestone-risk projection shown alongside Amazon's *own* stated projection
for the same date, the actual disclosed waiver mechanics (priority-status loss, not license revocation), and a
real, dated safety incident (the Feb 2026 SpaceX collision-risk dispute). 214 tests pass; a singular test
enforces that every illustrative mart's rows are explicitly
flagged, making the grounded-vs-illustrative separation a
tested property of the project, not just a README claim.
🔗 Live: **https://tjaiyen.github.io/tj-finance-portfolio/leo-program-finance.html**

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

## [`site/public/operations-bridge.html`](./site/public/operations-bridge.html) — Operations Bridge, a finance automation engine (live)
A single-glance command center rolling up 8 dashboards — Cost & Variance, WIP & Inventory, Production &
Ops, AP & Procurement, Controls & Compliance, P&L & Synthesis, and Capital Projects (EVM) — with a
plain-language narrator that explains what each value means from the number and its threshold, computed
by rule, never by a live model. Materiality-band and EVM-variance sliders re-flag findings live; a command
palette, guided tour, and light/dark theme round it out. Synthetic, illustrative food-manufacturing data.
🔗 Live: **https://tjaiyen.github.io/tj-finance-portfolio/operations-bridge.html**

## Why these eight together
Eight pieces, same discipline: three dbt projects for the modeled numbers (finance variance, GPU cost
attribution, and Leo program finance), Airflow/Cosmos for reliable scheduling and recovery, a Claude agent
for the narrative layer, an agentic-ops skeleton for guardrailed multi-agent autonomy, site/ to tie it
together for a hiring reviewer, and Operations Bridge to show the same rigor at dashboard scale —
deterministic thresholds and rule-based narration, never a generated claim about a number. All three dbt
tracks use the same method — tested models, deterministic math, orchestrated runs — with Leo program finance
adding a third discipline: sourcing every real-world figure to a citation, and testing that illustrative data
is never presented as real. The AI layers touch only judgment and language: the variance agent's guardrail
rejects any output that references an account not in the source, and the agentic skeleton treats all fetched
content as data, never instructions, with a human gate before any irreversible action.

*Data in the finance-variance, GPU-cost, orchestration, agent, and agentic-ops projects is synthetic — no
employer or confidential information is included anywhere. The Leo program finance project is the one
exception with real data: figures describing the public program are sourced to public reporting (cited
inline); figures describing an internal decision are synthetic and flagged as such — see that project's
README for the full sourcing discipline.*

— Theerayut (TJ) Jaiyen · linkedin.com/in/jaiyentheerayut
