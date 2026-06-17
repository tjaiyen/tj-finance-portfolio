"""
Claude Finance Variance Agent
-----------------------------
Turns two periods of financial line items into a CFO-ready narrative plus a
structured exception report -- with guardrails that catch the failure mode that
actually matters in finance: a hallucinated account or an unaddressed material variance.

Design principle: numbers are computed in code; the model is used only for judgment
(materiality, root-cause hypothesis) and language (the narrative). Nothing the model
"says" becomes a number in a total, and every account it references is verified to exist.

Usage:
    pip install -r requirements.txt
    cp .env.example .env   # add ANTHROPIC_API_KEY
    python variance_agent.py sample_data/financials_q1_q2.csv --threshold 0.05
"""

import argparse
import csv
import json
import os
import sys
from pathlib import Path

# Set to a model available on your account. Adjust as Anthropic releases new versions.
DEFAULT_MODEL = "claude-sonnet-4-5"


def load_financials(path):
    """Read account, period_prior, period_current from CSV. Numbers parsed here, in code."""
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            rows.append(
                {
                    "account": r["account"].strip(),
                    "prior": float(r["period_prior"]),
                    "current": float(r["period_current"]),
                }
            )
    if not rows:
        sys.exit("No rows found in input CSV.")
    return rows


def compute_variances(rows, threshold):
    """Deterministic variance math. The model never produces these numbers."""
    out = []
    for r in rows:
        var_abs = round(r["current"] - r["prior"], 2)
        var_pct = (var_abs / r["prior"]) if r["prior"] else None
        material = var_pct is not None and abs(var_pct) >= threshold
        out.append(
            {
                "account": r["account"],
                "prior": r["prior"],
                "current": r["current"],
                "variance_abs": var_abs,
                "variance_pct": round(var_pct, 4) if var_pct is not None else None,
                "material": material,
            }
        )
    return out


def build_prompt(variances, threshold):
    """Ask the model ONLY for judgment + language. Facts are already computed."""
    facts = [
        {
            "account": v["account"],
            "variance_abs": v["variance_abs"],
            "variance_pct": v["variance_pct"],
            "material": v["material"],
        }
        for v in variances
    ]
    schema = {
        "narrative": "string -- 3-5 sentence CFO-ready summary of the period",
        "exceptions": [
            {
                "account": "must EXACTLY match an account from the input",
                "direction": "favorable | unfavorable | neutral",
                "root_cause_hypothesis": "string -- a plausible driver, clearly framed as a hypothesis",
                "confidence": "low | medium | high",
            }
        ],
    }
    return (
        "You are a cost accountant reviewing month-end variances. "
        "The numeric variances are already computed and are authoritative -- do not recompute or invent figures. "
        f"Materiality threshold is {threshold:.0%} of the prior period.\n\n"
        "Return ONLY valid JSON matching this schema (no prose, no code fences):\n"
        f"{json.dumps(schema, indent=2)}\n\n"
        "Rules:\n"
        "- Provide an exceptions entry for EVERY material account.\n"
        "- Use account names EXACTLY as given. Never reference an account not in the data.\n"
        "- Root causes are hypotheses, not assertions of fact.\n\n"
        f"Variance data:\n{json.dumps(facts, indent=2)}"
    )


def call_claude(prompt, model):
    import anthropic  # imported here so the pure logic + tests don't require the SDK
    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from env
    msg = client.messages.create(
        model=model,
        max_tokens=1500,
        messages=[{"role": "user", "content": prompt}],
    )
    return msg.content[0].text


def parse_json(text):
    """Tolerant parse: strip code fences if the model added them."""
    t = text.strip()
    if t.startswith("```"):
        t = t.split("```", 2)[1]
        if t.startswith("json"):
            t = t[4:]
    return json.loads(t.strip())


def run_guardrails(result, variances, threshold):
    """The verification layer. Fails loudly rather than shipping a wrong report."""
    errors = []
    valid_accounts = {v["account"] for v in variances}
    material_accounts = {v["account"] for v in variances if v["material"]}

    if not isinstance(result.get("narrative"), str) or not result["narrative"].strip():
        errors.append("Schema: missing narrative.")
    if not isinstance(result.get("exceptions"), list):
        errors.append("Schema: exceptions is not a list.")
        return errors

    referenced = set()
    for i, e in enumerate(result["exceptions"]):
        acct = e.get("account", "")
        referenced.add(acct)
        # HALLUCINATION GUARDRAIL: every referenced account must exist in the source
        if acct not in valid_accounts:
            errors.append(f"Hallucination: exception[{i}] references unknown account '{acct}'.")
        if e.get("direction") not in {"favorable", "unfavorable", "neutral"}:
            errors.append(f"Schema: exception[{i}] has invalid direction '{e.get('direction')}'.")
        if e.get("confidence") not in {"low", "medium", "high"}:
            errors.append(f"Schema: exception[{i}] has invalid confidence '{e.get('confidence')}'.")

    # COVERAGE GUARDRAIL: every material variance must be addressed
    missed = material_accounts - referenced
    if missed:
        errors.append(f"Coverage: material variances not addressed: {sorted(missed)}.")

    return errors


def merge_report(result, variances):
    """Attach the model's judgment to the code-computed facts (facts win)."""
    by_acct = {v["account"]: v for v in variances}
    merged = []
    for e in result["exceptions"]:
        fact = by_acct.get(e["account"], {})
        merged.append(
            {
                "account": e["account"],
                "prior": fact.get("prior"),
                "current": fact.get("current"),
                "variance_abs": fact.get("variance_abs"),      # from code
                "variance_pct": fact.get("variance_pct"),      # from code
                "material": fact.get("material"),              # from code
                "direction": e.get("direction"),              # from model
                "root_cause_hypothesis": e.get("root_cause_hypothesis"),  # from model
                "confidence": e.get("confidence"),            # from model
            }
        )
    return {"narrative": result["narrative"], "exceptions": merged}


def main():
    ap = argparse.ArgumentParser(description="Claude finance variance agent with guardrails.")
    ap.add_argument("csv", help="CSV with columns: account, period_prior, period_current")
    ap.add_argument("--threshold", type=float, default=0.05, help="Materiality as fraction of prior (default 0.05)")
    ap.add_argument("--model", default=DEFAULT_MODEL)
    args = ap.parse_args()

    # Load .env (simple, dependency-free) if present.
    env_path = Path(".env")
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())

    if not os.getenv("ANTHROPIC_API_KEY"):
        sys.exit("Set ANTHROPIC_API_KEY (see .env.example).")

    rows = load_financials(args.csv)
    variances = compute_variances(rows, args.threshold)

    raw = call_claude(build_prompt(variances, args.threshold), args.model)
    try:
        result = parse_json(raw)
    except json.JSONDecodeError as e:
        sys.exit(f"Model did not return valid JSON ({e}). Run aborted -- nothing shipped.")

    errors = run_guardrails(result, variances, args.threshold)
    if errors:
        print("GUARDRAILS FAILED -- report not trusted:\n - " + "\n - ".join(errors), file=sys.stderr)
        sys.exit(1)

    report = merge_report(result, variances)
    Path("output").mkdir(exist_ok=True)
    Path("output/exception_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    print("\n=== CFO NARRATIVE ===\n")
    print(report["narrative"])
    print("\n=== MATERIAL EXCEPTIONS ===\n")
    for e in report["exceptions"]:
        if e["material"]:
            pct = f"{e['variance_pct']:+.1%}" if e["variance_pct"] is not None else "n/a"
            print(f"- {e['account']}: {e['variance_abs']:+,.0f} ({pct}) [{e['direction']}, {e['confidence']}]")
            print(f"    hypothesis: {e['root_cause_hypothesis']}")
    print("\nFull report written to output/exception_report.json")
    print("Guardrails passed: no hallucinated accounts, all material variances addressed.")


if __name__ == "__main__":
    main()
