# Agentic Ops Skeleton

A small, runnable skeleton of a **guardrailed multi-agent operations pipeline** —
`ingest → score → draft → human-review queue` — that shows how I take LLM agents past a
demo into something safe to run unattended: a deterministic core the model can't silently
override, an untrusted-input boundary that treats fetched content as *data, not instructions*,
and a human gate in front of every irreversible action.

> **Sanitized, synthetic-only.** This is a clean-room skeleton of the *architecture* of a larger
> private system I run on a daily schedule. The real workflow, data, and integrations are not here —
> just the engineering pattern, on fake "records." No dependencies, no API keys, no network calls.

Built by a cost accountant, not a hobbyist. The point isn't "agents are cool." It's the discipline
around them — the same instinct as financial controls: *which output do I not trust, and where do I
put the check?*

## Why this exists

An autonomous agent that's right 95% of the time is dangerous if the other 5% can take an
irreversible action. So the architecture answers that up front:

1. **Compute the facts in code.** Scoring/ranking is deterministic (`orchestrator.py: score`) — the
   model never produces a number that drives a decision.
2. **Use the model only for judgment/language.** The `draft` stage is where an LLM plugs in; it's
   stubbed here so the skeleton runs free and offline.
3. **Treat the outside world as hostile-by-default.** Scraped/fetched content is parsed header-only;
   the free-text body can't inject a field, and a URL is only actionable if it's on an allow-list.
4. **Gate every outward action on a human.** `human_gate()` is fail-closed — nothing dispatches
   without explicit approval.

## What's here

| File | Role |
|---|---|
| `orchestrator.py` | The pipeline: ingest fixtures → deterministic score → draft stub → ranked human-review queue |
| `guardrails.py` | `parse_record` (header-only, injection-safe), `vet_url` (scheme + host allow-list), `human_gate` (fail-closed) |
| `fixtures/` | Synthetic records, including an **injection** record and a **bad-URL** record |
| `tests/test_guardrails.py` | Pre-registered probes proving the guardrails — no API, runs free in CI |

## Run it

```bash
python3 orchestrator.py          # runs the pipeline on the synthetic fixtures
python3 -m unittest discover     # runs the guardrail probes (all green, no network)
```

You'll see the injection record's malicious body **ignored** (its `priority: high` /
`url: http://evil…` never override the header), the bad-URL record **flagged** for human
verification, and the human gate **block** the top item because nothing is auto-approved.

## Tested — the guardrails are proven, not just claimed

`tests/test_guardrails.py` states each expected outcome *before* asserting it (the
pre-registration discipline that caught real bugs in the parent system before they reached a live
run):

- **Body can't inject fields** — a record whose untrusted body says "IGNORE PREVIOUS INSTRUCTIONS"
  and re-declares `priority`/`url` is parsed header-only; the body is data, ignored.
- **Allow-listed URL passes; off-list host + non-http schemes (e.g. `javascript:`) are blocked.**

The same engineering instinct as the finance projects in this portfolio — *find the failure mode
that actually matters and put a deterministic check in front of it* — applied to autonomy.
