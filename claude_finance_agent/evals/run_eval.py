"""
Behavioral eval harness for the Claude finance variance agent.

Runs the agent over a golden, partly-adversarial dataset and scores its behavior
against DETERMINISTIC ground truth derived from the input (no hand-labeling needed
for the core metrics — the variance math is the answer key). This is the layer that
turns "the guardrails fire" into measured numbers you can put in a README.

Metrics (all computed from the input CSV + the model's output):
  - schema_validity_rate     : output is valid JSON with valid enums + a narrative
  - hallucination_attempt_%  : model referenced an account not in the source
  - coverage_recall          : material accounts the model addressed / total material
  - guardrail_catch_rate     : of runs where the model erred, did run_guardrails catch it? (target 100%)
  - direction_accuracy       : favorable/unfavorable vs ground truth (optional; needs evals/labels.json)

Run:
  python evals/run_eval.py            # real: calls Claude (needs ANTHROPIC_API_KEY); costs tokens
  python evals/run_eval.py --mock     # offline: deterministic stub model, proves the scorer end-to-end
  python evals/run_eval.py --runs 3   # repeat each case N times for stability
"""
import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
AGENT_DIR = HERE.parent
sys.path.insert(0, str(AGENT_DIR))
from variance_agent import (  # noqa: E402
    load_financials,
    compute_variances,
    build_prompt,
    parse_json,
    run_guardrails,
)

CASES_DIR = HERE / "cases"
LABELS_PATH = HERE / "labels.json"
VALID_DIR = {"favorable", "unfavorable", "neutral"}
VALID_CONF = {"low", "medium", "high"}


# ---------------------------------------------------------------- model backends

def mock_model(variances):
    """Deterministic stand-in for Claude — lets the scorer run offline.
    Intentionally imperfect so an eval run is meaningful:
      - addresses every material account (good coverage)
      - naively calls any increase 'unfavorable' (wrong for revenue → tests direction scoring)
      - 'cleans' awkward account names by trimming at ' — ' or ' (' (simulates the real
        hallucination risk → tests the hallucination metric on the rename-temptation case)
    """
    exceptions = []
    for v in variances:
        if not v["material"]:
            continue
        acct = v["account"]
        for sep in (" — ", " ("):
            if sep in acct:
                acct = acct.split(sep)[0]  # the failure mode: a plausible-but-wrong shortened name
                break
        exceptions.append({
            "account": acct,
            "direction": "unfavorable" if (v["variance_abs"] or 0) > 0 else "favorable",
            "root_cause_hypothesis": "Auto-generated mock hypothesis.",
            "confidence": "medium",
        })
    return {"narrative": "Mock period summary covering all material movements.", "exceptions": exceptions}


def real_model(variances, threshold, model):
    from variance_agent import call_claude
    return parse_json(call_claude(build_prompt(variances, threshold), model))


# ---------------------------------------------------------------- scoring

def expected_direction(acct_type, variance_abs):
    """Ground-truth direction from an account-type label (evals/labels.json)."""
    if acct_type not in {"revenue", "cost"} or variance_abs is None:
        return None
    up = variance_abs > 0
    if acct_type == "revenue":
        return "favorable" if up else "unfavorable"
    return "unfavorable" if up else "favorable"   # cost


def score_case(variances, result, case_labels):
    valid_accounts = {v["account"] for v in variances}
    material_accounts = {v["account"] for v in variances if v["material"]}
    by_acct = {v["account"]: v for v in variances}

    exceptions = result.get("exceptions")
    schema_valid = (
        isinstance(result.get("narrative"), str) and result["narrative"].strip() != ""
        and isinstance(exceptions, list)
        and all(
            e.get("account") and e.get("direction") in VALID_DIR and e.get("confidence") in VALID_CONF
            for e in exceptions
        )
    )

    referenced = {e.get("account", "") for e in exceptions} if isinstance(exceptions, list) else set()
    hallucinated = sorted(referenced - valid_accounts)
    addressed = material_accounts & referenced
    coverage_recall = (len(addressed) / len(material_accounts)) if material_accounts else 1.0

    # direction accuracy over labeled accounts
    dir_total = dir_correct = 0
    if isinstance(exceptions, list):
        for e in exceptions:
            exp = expected_direction(case_labels.get(e.get("account", "")), by_acct.get(e.get("account", ""), {}).get("variance_abs"))
            if exp is not None:
                dir_total += 1
                if e.get("direction") == exp:
                    dir_correct += 1

    guardrail_errors = run_guardrails(result, variances, 0.05)
    model_erred = bool(hallucinated) or bool(material_accounts - referenced) or not schema_valid

    return {
        "schema_valid": schema_valid,
        "hallucinated": hallucinated,
        "coverage_recall": round(coverage_recall, 3),
        "material_count": len(material_accounts),
        "guardrail_errors": guardrail_errors,
        "model_erred": model_erred,
        "guardrail_caught": bool(guardrail_errors),
        "dir_total": dir_total,
        "dir_correct": dir_correct,
    }


# ---------------------------------------------------------------- driver

def main():
    ap = argparse.ArgumentParser(description="Behavioral eval for the variance agent.")
    ap.add_argument("--mock", action="store_true", help="use a deterministic offline stub instead of Claude")
    ap.add_argument("--threshold", type=float, default=0.05)
    ap.add_argument("--model", default="claude-sonnet-4-5")
    ap.add_argument("--runs", type=int, default=1, help="repeat each case N times (stability)")
    args = ap.parse_args()

    labels = json.loads(LABELS_PATH.read_text(encoding="utf-8")) if LABELS_PATH.exists() else {}
    cases = sorted(CASES_DIR.glob("*.csv"))
    if not cases:
        sys.exit("No eval cases found in evals/cases/.")

    rows_out = []
    agg = {"runs": 0, "schema_ok": 0, "halluc_runs": 0, "coverage_sum": 0.0,
           "erred": 0, "caught": 0, "dir_total": 0, "dir_correct": 0}

    for case in cases:
        variances = compute_variances(load_financials(str(case)), args.threshold)
        case_labels = labels.get(case.name, {})
        for _ in range(args.runs):
            try:
                result = mock_model(variances) if args.mock else real_model(variances, args.threshold, args.model)
            except Exception as e:  # a hard failure is itself a (caught) error
                result = {"narrative": "", "exceptions": []}
                print(f"  [{case.name}] model/parse error: {e}", file=sys.stderr)
            s = score_case(variances, result, case_labels)
            agg["runs"] += 1
            agg["schema_ok"] += int(s["schema_valid"])
            agg["halluc_runs"] += int(bool(s["hallucinated"]))
            agg["coverage_sum"] += s["coverage_recall"]
            agg["erred"] += int(s["model_erred"])
            agg["caught"] += int(s["model_erred"] and s["guardrail_caught"])
            agg["dir_total"] += s["dir_total"]
            agg["dir_correct"] += s["dir_correct"]
            rows_out.append((case.name, s))

    n = agg["runs"]
    pct = lambda a, b: (100.0 * a / b) if b else 100.0
    summary = {
        "mode": "mock" if args.mock else f"claude:{args.model}",
        "cases": len(cases), "runs": n,
        "schema_validity_rate": round(pct(agg["schema_ok"], n), 1),
        "hallucination_attempt_rate": round(pct(agg["halluc_runs"], n), 1),
        "coverage_recall_mean": round(agg["coverage_sum"] / n, 3),
        "guardrail_catch_rate": round(pct(agg["caught"], agg["erred"]), 1),
        "direction_accuracy": round(pct(agg["dir_correct"], agg["dir_total"]), 1) if agg["dir_total"] else None,
        "runs_with_model_error": agg["erred"],
    }

    # write machine-readable + human-readable reports
    (HERE / "eval_results.json").write_text(
        json.dumps({"summary": summary,
                    "cases": [{"case": c, **{k: v for k, v in s.items()}} for c, s in rows_out]},
                   indent=2), encoding="utf-8")

    lines = [f"# Agent Eval Report — {summary['mode']}", "",
             f"Cases: {summary['cases']} · Runs: {summary['runs']}", "",
             "| Metric | Value |", "|---|---|",
             f"| Schema validity rate | {summary['schema_validity_rate']}% |",
             f"| Hallucination-attempt rate | {summary['hallucination_attempt_rate']}% |",
             f"| Coverage recall (mean) | {summary['coverage_recall_mean']} |",
             f"| **Guardrail catch rate** (errs caught) | **{summary['guardrail_catch_rate']}%** |",
             f"| Direction accuracy | {summary['direction_accuracy'] if summary['direction_accuracy'] is not None else 'n/a (no labels)'}{'%' if summary['direction_accuracy'] is not None else ''} |",
             "", "## Per-case", "", "| Case | schema | hallucinated | coverage | guardrail errs |", "|---|---|---|---|---|"]
    for c, s in rows_out:
        lines.append(f"| {c} | {'ok' if s['schema_valid'] else 'BAD'} | {', '.join(s['hallucinated']) or '-'} | {s['coverage_recall']} | {len(s['guardrail_errors'])} |")
    (HERE / "eval_report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(json.dumps(summary, indent=2))
    print(f"\nWrote evals/eval_report.md + evals/eval_results.json")


if __name__ == "__main__":
    main()
