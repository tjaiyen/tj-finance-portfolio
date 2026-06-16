# Resume Bullet Points

Grounded in the three runnable portfolio projects. Pick 2–4 depending on space. Each leads with the
engineering, with the cost-accounting origin as the differentiator — not the other way around.

## Portfolio / Projects section

- **Built an LLM finance-variance agent (Python, Anthropic SDK) with a verification layer** that computes
  all variance math deterministically in code and uses the model only for narrative and root-cause
  judgment — enforcing hallucination, coverage, and JSON-schema guardrails that fail the run loudly rather
  than let a wrong number or invented GL account reach a report.

- **Rebuilt the same finance logic as a tested dbt + DuckDB project** (sources → staging → marts) with
  two-tier testing: dbt *data tests* (not_null, unique, accepted_values, referential integrity) validating
  data in production, and a dbt *unit test* validating the variance/materiality SQL logic against mocked
  inputs in CI — the data-vs-logic testing distinction most portfolio projects miss.

- **Built a third dbt project that ports the discipline into AI/cloud cost attribution** — allocating shared
  GPU idle capacity across tenants by token volume (overhead absorption), computing per-tenant gross margin,
  and flagging an unprofitable tenant — governed by data, unit, and singular tests. Demonstrates FinOps-for-AI
  thinking: the materiality threshold becomes a margin-zone threshold; subledger-to-GL reconciliation becomes
  a dbt relationship test.

- **Kept every artifact clone-and-build** (DuckDB, no warehouse to provision; `dbt build` in under a minute)
  so reviewers can verify the work rather than take a screenshot on faith.

## One-line résumé summary (optional header)

> Cost accountant building the trustworthy data + AI layer beneath financial reporting — deterministic logic
> for the numbers, LLMs for judgment, automated tests as the sign-off gate. Python · SQL · dbt · Anthropic SDK.
