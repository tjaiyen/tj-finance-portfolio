# Architectural FAQ

Questions a sharp interviewer will ask about the three projects, with defensible answers. The first five are
answerable directly from the shipped code; Q6 is forward-looking ("how I'd extend this") and is flagged as
such — never claim a hypothetical extension as something you already ran.

---

**Q1: Why compute the variances in code instead of just asking the model to do the math?**

Because in finance the number is the deliverable, and an LLM that's wrong even occasionally on arithmetic is
disqualifying when a CFO signs off on the output. So I split responsibilities: deterministic code owns every
figure (variance abs and %, the materiality flag); the model owns only what it's genuinely good at —
root-cause hypotheses, materiality judgment, and plain-English narrative. The model literally cannot produce
a number that lands in a total. That's not a limitation I worked around; it's the design.

**Q2: What's the difference between your dbt data tests and the unit test — why have both?**

Data tests validate the *data* on every run: not_null, unique, accepted_values on the materiality flag, and a
relationship test so a mart row can't reference an account that isn't in the source. The unit test validates
the *logic*: it runs the mart against mocked staging rows and asserts the exact variance math and the
materiality boundary — a +2.5% line must stay non-material, a +10% line must flip. Data tests catch bad data
in production; the unit test catches a bad code change in CI before it ever touches the warehouse. Most
portfolio dbt projects only do the first tier.

**Q3: Why DuckDB instead of Snowflake or BigQuery?**

Two reasons. First, runnable beats impressive: anyone can clone the repo and `dbt build` in under a minute
with no cloud account, so the work is *verifiable* rather than a screenshot. Second, dbt's adapter layer means
the model SQL is portable — pointing it at Snowflake or BigQuery is a profile change, not a rewrite. I chose
the option that lets a reviewer confirm it actually works; scaling the warehouse is the easy part.

**Q4: How do you stop an LLM hallucination from reaching a financial report?**

Three guardrails that run before anything ships, each failing the run loudly rather than warning: a
hallucination check (every account the model names must exist in the source data), a coverage check (every
material variance must be addressed — the model can't silently drop one), and a schema check (the structured
JSON validates or the run aborts). It's the same contract as a CI gate: trust is earned by verification, not
assumed from a good-looking draft.

**Q5: You took this from finance variance into AI / GPU cost attribution — how?**

I built it as a third runnable project (`dbt_gpu_cost_attribution`, dbt + DuckDB, synthetic data). The model
shape barely changed. The GL seed became cloud-billing and token-usage telemetry; the materiality threshold
became a margin-zone threshold; overhead absorption across shared cost pools became allocating shared
GPU-cluster idle capacity across tenants by token volume — the same overhead-absorption math from job-order
costing, with the allocation ratio as the absorption key. It's governed by three test tiers (data, unit, and
singular tests that prove the allocation ratios sum to 1 and no cost goes negative), and on the synthetic data
it surfaces a tenant running at a negative margin — the "which customer is unprofitable and why" question a
FinOps team actually needs answered.

To extend it further: for slowly-changing attributes like customer tier or contract terms I'd add a dbt
snapshot (SCD Type 2), which compiles to a warehouse MERGE natively and tracks valid-from/valid-to without
hand-written merge logic. I'd keep the marts in a Kimball star schema over Data Vault — for a single-source, BI-facing
project, star schema optimizes for query simplicity and readability, and Data Vault's extra modeling layers
buy nothing at this scale.

**Q6 (context): Why does separating inference cost from training cost matter for AI-company FinOps?**

Traditional SaaS runs 70–85% gross margin; AI-native companies average lower (~50% range, per recent industry
snapshots — figures move fast, so I treat them as point-in-time) because *inference* compute is COGS, not just
hosting. *Training* compute is generally treated as R&D and excluded from gross margin. That distinction is a
cost-accounting call before it's a data-modeling one — and it's exactly the kind of judgment a finance
background brings to a FinOps team: knowing not just how to attribute a cost, but which bucket it belongs in.
