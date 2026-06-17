"""
Deterministic eval/test harness for the Claude finance variance agent.

Proves the guardrails actually catch the failure modes they claim to — with NO API
calls, so it runs free and fast in CI on every commit. This is the verification layer
that turns "I built a guardrail" into "here is the test that proves it fires."

Covers: compute_variances (the deterministic math the model never touches),
run_guardrails (hallucination / coverage / schema), parse_json (tolerant parsing),
and merge_report (code-computed facts win over model output).

Run:  pip install pytest && pytest -v
"""
import sys
from pathlib import Path

# Import the agent's pure functions without needing the Anthropic SDK or an API key.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from variance_agent import (  # noqa: E402
    compute_variances,
    run_guardrails,
    parse_json,
    merge_report,
)

THRESHOLD = 0.05

# Two prior/current rows: one clearly material (+25%), one immaterial (+1%).
ROWS = [
    {"account": "Direct Labor", "prior": 100_000.0, "current": 125_000.0},   # +25% -> material
    {"account": "Office Supplies", "prior": 10_000.0, "current": 10_100.0},  # +1%  -> not material
]


def _variances():
    return compute_variances(ROWS, THRESHOLD)


def _clean_result():
    """A well-formed model result that should pass every guardrail."""
    return {
        "narrative": "Direct Labor rose materially this period; supplies were flat.",
        "exceptions": [
            {
                "account": "Direct Labor",
                "direction": "unfavorable",
                "root_cause_hypothesis": "Overtime to meet a production push.",
                "confidence": "medium",
            }
        ],
    }


# ---------------------------------------------------------------- compute_variances

def test_compute_variances_math():
    v = {x["account"]: x for x in _variances()}
    dl = v["Direct Labor"]
    assert dl["variance_abs"] == 25_000.0
    assert dl["variance_pct"] == 0.25
    assert dl["material"] is True
    os = v["Office Supplies"]
    assert os["variance_abs"] == 100.0
    assert os["variance_pct"] == 0.01
    assert os["material"] is False


def test_compute_variances_zero_prior_no_divide_by_zero():
    out = compute_variances([{"account": "New Account", "prior": 0.0, "current": 5_000.0}], THRESHOLD)
    assert out[0]["variance_pct"] is None     # no division by zero
    assert out[0]["material"] is False         # can't be material without a pct
    assert out[0]["variance_abs"] == 5_000.0


# ---------------------------------------------------------------- run_guardrails (pass)

def test_guardrails_pass_on_clean_result():
    assert run_guardrails(_clean_result(), _variances(), THRESHOLD) == []


# ---------------------------------------------------------------- run_guardrails (fail)

def test_guardrails_catch_hallucinated_account():
    bad = _clean_result()
    bad["exceptions"].append({
        "account": "Phantom Reserve",  # does not exist in the source data
        "direction": "favorable",
        "root_cause_hypothesis": "made up",
        "confidence": "high",
    })
    errors = run_guardrails(bad, _variances(), THRESHOLD)
    assert any("Hallucination" in e and "Phantom Reserve" in e for e in errors)


def test_guardrails_catch_missed_material_variance():
    # Material account "Direct Labor" exists but the model addressed nothing.
    empty = {"narrative": "All quiet.", "exceptions": []}
    errors = run_guardrails(empty, _variances(), THRESHOLD)
    assert any("Coverage" in e and "Direct Labor" in e for e in errors)


def test_guardrails_catch_bad_enums():
    bad = _clean_result()
    bad["exceptions"][0]["direction"] = "sideways"     # invalid
    bad["exceptions"][0]["confidence"] = "certain"      # invalid
    errors = run_guardrails(bad, _variances(), THRESHOLD)
    assert any("invalid direction" in e for e in errors)
    assert any("invalid confidence" in e for e in errors)


def test_guardrails_catch_missing_narrative():
    bad = _clean_result()
    bad["narrative"] = "   "
    errors = run_guardrails(bad, _variances(), THRESHOLD)
    assert any("missing narrative" in e for e in errors)


def test_guardrails_catch_exceptions_not_a_list():
    bad = {"narrative": "ok", "exceptions": "oops not a list"}
    errors = run_guardrails(bad, _variances(), THRESHOLD)
    assert any("exceptions is not a list" in e for e in errors)


# ---------------------------------------------------------------- parse_json (tolerant)

def test_parse_json_raw():
    assert parse_json('{"a": 1}') == {"a": 1}


def test_parse_json_strips_json_fence():
    assert parse_json('```json\n{"a": 1}\n```') == {"a": 1}


def test_parse_json_strips_bare_fence():
    assert parse_json('```\n{"a": 1}\n```') == {"a": 1}


# ---------------------------------------------------------------- merge_report (facts win)

def test_merge_report_facts_win_over_model():
    merged = merge_report(_clean_result(), _variances())
    dl = merged["exceptions"][0]
    # numbers come from code, judgment from the model
    assert dl["variance_abs"] == 25_000.0      # code
    assert dl["material"] is True               # code
    assert dl["direction"] == "unfavorable"     # model
    assert dl["confidence"] == "medium"         # model
    assert merged["narrative"] == _clean_result()["narrative"]
