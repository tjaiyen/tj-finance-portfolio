# Claude Finance Variance Agent

A small, production-minded tool that uses the **Anthropic SDK** to turn two periods of financial line items into (1) a CFO-ready variance narrative and (2) structured, machine-readable exception flags — with an **accuracy guardrail** that rejects any output referencing an account that isn't in the source data.

Built by a cost accountant, not a hobbyist. The point isn't "Claude can write text." The point is the discipline around it: deterministic variance math done in code, the LLM used only for judgment and language, and a verification layer that catches the one failure mode that actually matters in finance — a confidently wrong number or a hallucinated GL account reaching a report.

## Why this exists

In real finance work, an AI that's right 95% of the time is not usable if you can't tell which 5% is wrong. This tool encodes the answer I use in practice:

1. **Compute the facts in code.** Variances (absolute and %) are calculated deterministically from the source — never by the model.
2. **Use the model for what it's good at.** Root-cause hypotheses, materiality judgment, and plain-English narrative for a CFO.
3. **Verify before trust.** A guardrail checks that every account the model references exists in the input, that every material variance is addressed, and that the structured output validates against a schema. If it fails, the run fails loudly — it does not silently ship.

## What it does

- Reads two periods of financials (`account, period_prior, period_current`) from CSV
- Computes variance (abs + %) and flags material items against a threshold
- Calls Claude to produce:
  - a structured JSON exception report (per-account: direction, materiality, root-cause hypothesis, confidence)
  - a CFO-ready narrative summarizing the close
- Runs guardrails:
  - **Hallucination check** — every account named by the model must exist in the source
  - **Coverage check** — every material variance must be addressed
  - **Schema check** — JSON validates or the run aborts
- Writes `output/exception_report.json` and prints the narrative

## Run it

```bash
pip install -r requirements.txt
cp .env.example .env        # add your ANTHROPIC_API_KEY
python variance_agent.py sample_data/financials_q1_q2.csv --threshold 0.05
```

## Notes

- Sample data is **synthetic** — no employer or confidential data is included.
- Variance math is in code; the model never produces a number that ends up in a total.
- This mirrors a pattern I built in a real close cycle: AI for narrative and triage, humans and code for the numbers and the final sign-off.

## Files

```
claude_finance_agent/
  README.md
  variance_agent.py
  requirements.txt
  .env.example
  sample_data/financials_q1_q2.csv
```
