# STAR Interview Answers

Behavioral answers anchored to the three real projects. Keep the Result quantified honestly — these are
synthetic-data demonstrations, so frame outcomes as *capability shown*, not production metrics.

## STAR 1 — Putting an LLM into a finance workflow without losing trust

- **Situation:** Finance teams want AI to speed up variance commentary at close, but an LLM that's wrong
  even occasionally is unusable when the output is a number a CFO signs off on.
- **Task:** Build a tool that uses an LLM for the parts it's genuinely good at (narrative, root-cause
  hypotheses, materiality judgment) without ever letting it produce or distort a figure.
- **Action:** Computed all variance math (absolute and %) deterministically in Python; restricted the model
  to language and judgment; then added three guardrails that run before any output ships — a hallucination
  check (every account the model names must exist in the source), a coverage check (every material variance
  must be addressed), and a JSON-schema check. If any fails, the run aborts loudly.
- **Result:** A pattern where the AI accelerates the narrative but cannot introduce the one failure mode that
  matters — a confidently wrong number or a hallucinated GL account reaching a report. The guardrail design
  generalizes to any production LLM feature, not just finance.

## STAR 2 — Closing the tooling gap from spreadsheets/Power BI to the modern data stack

- **Situation:** My financial-data work lived in SQL, Python, and Power BI; analytics-engineering roles
  expect that same rigor expressed in dbt with tested, governed models.
- **Task:** Prove I could deliver the identical finance logic the modern-data-stack way, end to end.
- **Action:** Rebuilt the variance logic as a dbt project on DuckDB — sources → staging → marts — and added
  two tiers of testing: data tests (not_null, unique, accepted_values, and a relationship test so a mart row
  can never reference a missing source account) plus a dbt unit test that pins the variance math and the
  materiality boundary against mocked inputs in CI.
- **Result:** A clone-and-build project (`dbt build` runs in under a minute, no warehouse) that demonstrates
  source-to-mart modeling, data governance, and the data-test-vs-unit-test distinction — the exact toolchain
  delta between a finance analyst and an analytics engineer, closed and verifiable.

## STAR 3 — Translating cost-accounting discipline into data/AI thinking

- **Situation:** Interviewers reasonably ask whether a cost accountant's skills actually transfer to a data
  or FinOps platform role.
- **Task:** Make the transfer concrete and defensible rather than a slogan.
- **Action:** Mapped each guardrail to its platform equivalent — subledger-to-GL reconciliation → dbt
  relationship test; standard-vs-actual variance → spend-anomaly detection; materiality threshold →
  cost-attribution alerting; overhead absorption across cost pools → shared-GPU idle-capacity allocation —
  and built the projects so the same model shape accepts cloud-billing telemetry in place of the GL seed.
- **Result:** A demonstrable through-line: the instinct for *which number is wrong and how to catch it* is
  the same skill whether the cost pool is a factory floor or a GPU cluster. The artifacts let me show it, not
  just claim it.
