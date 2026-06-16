# LinkedIn Launch Post

> Keep it one idea per line — LinkedIn rewards scannable posts.

---

An AI that's right 95% of the time is useless in finance if you can't tell which 5% is wrong.

That problem — not "can the model write text" — is what I build around. I'm a cost accountant moving deeper into the data + AI layer, and I just published three small, *runnable* projects that show the discipline I bring to AI-assisted financial work:

**1. A Claude variance agent (Python + Anthropic SDK)**
Two periods of GL line items in → a CFO-ready variance narrative + structured exception flags out. The variance math is computed in code (deterministic); the model is used only for judgment and language. Then three guardrails run before anything ships:
— hallucination check: every account the model names must exist in the source
— coverage check: every material variance must be addressed
— schema check: the JSON validates or the run fails loudly

**2. A dbt rebuild of the same logic (dbt + DuckDB)**
The identical finance logic expressed the modern-data-stack way: sources → staging → marts, governed by *two tiers* of tests — data tests that catch bad data in production, and a dbt unit test that catches bad logic in CI before it reaches the warehouse. Clone and `dbt build` — it runs locally in under a minute, no cloud account required.

**3. The same discipline, taken into AI cost (dbt + DuckDB)**
A FinOps model that attributes shared GPU cost to tenants and computes per-tenant margin — idle capacity absorbed across tenants exactly like factory overhead. On synthetic data it flags the tenant running at a negative margin: the "which customer is unprofitable and why" question, answered by tested models.

The through-line: **compute the facts in code, use the model for judgment, verify before trust.** Swap the GL seed for cloud-billing or token-usage telemetry and the model shape doesn't change — that's how this finance rigor ports straight into AI cost attribution and FinOps.

The accountant-to-analytics-engineer path is real and well-trodden (Sam Harting, CPA → Analytics Engineer at dbt Labs). I'm building the artifacts to prove I'm already standing on the data side of it.

All three (code + READMEs + interactive case study):
→ github.com/tjaiyen/tj-finance-portfolio
→ tjaiyen.github.io/tj-finance-portfolio

#AnalyticsEngineering #dbt #FinOps #FinanceAutomation #LLM #DataEngineering
