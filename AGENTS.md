# Agent rules for tj-finance-portfolio

## What this repo is
A hiring-reviewer-facing portfolio: dbt variance models, Airflow/Cosmos
orchestration, and a guardrailed Anthropic-SDK variance agent. Reviewers (human
and ATS-adjacent) read this to judge how the author works. Correctness beats
cleverness. CI must stay green (dbt tests + the DagBag import test) — never
merge red.

## Data rules (absolute)
- **Synthetic data only.** Never add employer-derived data, real GL numbers,
  customer/vendor names, or anything confidential.
- **Never reference B.E. Meyers** or any past-employer specifics anywhere in
  this repo — code, comments, commits, or docs.

## Voice rules
- Code, badges, CI config, formatting, refactors: agents may fix freely.
- README narrative paragraphs and any essay content (e.g. docs/where-ai-earns-trust*):
  **the author's own words.** Agents never draft, rewrite, or polish that prose.
  Structural suggestions are fine; replacement sentences are not.
- The application essays for any job (Anthropic especially) are NEVER written or
  edited by any AI agent, in this repo or anywhere else.

## Architecture conventions (the repo's thesis — protect it)
- Numbers are computed deterministically in code; the LLM is used only for
  judgment and language.
- The hallucination guardrail (rejects output referencing accounts not in the
  source) is the point of the project. Never weaken, bypass, or "temporarily
  disable" it.
- Tests accompany behavior changes; schema + relationship tests stay.

## Workflow
- Small, descriptive commits. No force-push to main. CI green before merge.

## Known issues (good first tasks)
- README CI badge points at the wrong username (`tjaiyensterling-debug/...`) —
  fix to this repo's actual path so the badge renders.
