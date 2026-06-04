# Finance Data & AI Portfolio — TJ Jaiyen

Two small, runnable projects that show how I work: a cost accountant who builds the data and AI layer
behind finance reporting, with correctness and governance built in — not bolted on.

## [`dbt_finance_variance/`](./dbt_finance_variance) — modern-data-stack variance modeling
A real **dbt** project: raw GL seed → typed **staging** model → a tested **`fct_account_variance`** mart
(prior-vs-current variance, % change, materiality flag). Includes schema tests plus a **relationship test**
so the mart can never reference an account that isn't in the source — data governance enforced in CI.
Runs locally on **DuckDB** (no warehouse): `pip install dbt-duckdb` then `dbt build` → 13 tests pass.

## [`claude_finance_agent/`](./claude_finance_agent) — AI variance commentary, with guardrails
A Python tool on the **Anthropic SDK** that turns two periods of financials into a CFO-ready narrative plus
structured exception flags. Variances are computed deterministically in code; the model is used only for
judgment and language; and a **hallucination guardrail** rejects any output that references an account not in
the source. The point isn't "AI writes text" — it's knowing where AI earns trust in a close and where a human
must verify.

## Why these two together
Same finance logic, two layers: dbt for the trustworthy modeled data, an AI layer on top for narrative and
triage. Deterministic numbers, tested models, AI for judgment — with guardrails at every step.

*Data in both projects is synthetic. No employer or confidential information is included.*

— Theerayut (TJ) Jaiyen · linkedin.com/in/jaiyentheerayut
