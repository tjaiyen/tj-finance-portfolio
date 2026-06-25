"""Minimal multi-stage agent pipeline — sanitized skeleton.

    ingest -> score (deterministic) -> draft (model-judgment stub) -> human-review queue

The shape mirrors a larger private system: independent stages, a deterministic core the
model's output can't silently override, untrusted-input guardrails at the boundary, and a
human gate before any irreversible / outward action. There is NO real LLM/API call here —
the ``draft`` step is a stub marking exactly where a model plugs in. Synthetic fixtures only.

Run:  python3 orchestrator.py        Test:  python3 -m unittest discover
"""
from __future__ import annotations

import sys
from pathlib import Path

from guardrails import human_gate, parse_record, vet_url

HERE = Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"

# Deterministic scoring rubric — the FACTS are computed in code, never by a model.
PRIORITY_WEIGHT = {"high": 30, "medium": 20, "low": 10}


def ingest(folder: Path) -> list[dict]:
    """Stage 1 — ingest untrusted records, parsing only their trusted headers."""
    records = []
    for f in sorted(folder.glob("*.md")):
        rec = parse_record(f.read_text(encoding="utf-8"))
        rec["_id"] = f.stem
        rec["url_ok"] = vet_url(rec.get("url", ""))
        records.append(rec)
    return records


def score(rec: dict) -> int:
    """Stage 2 — deterministic score from header fields. No model involved."""
    return PRIORITY_WEIGHT.get(rec.get("priority", "").lower(), 0) + (
        10 if rec.get("category", "").lower() == "finance" else 0
    )


def draft(rec: dict) -> str:
    """Stage 3 — where the LLM does judgment/language. Stubbed (no API call).

    In the real system this returns model-generated prose; the deterministic score
    above is never produced by the model.
    """
    return f"[draft summary for {rec['_id']} - model judgment plugs in here]"


def run() -> int:
    if not FIXTURES.exists():
        print(f"no fixtures at {FIXTURES}", file=sys.stderr)
        return 1
    records = ingest(FIXTURES)
    for r in records:
        r["score"] = score(r)
        r["summary"] = draft(r)
    records.sort(key=lambda r: -r["score"])

    print(f"Ingested {len(records)} record(s). Human-review queue (by deterministic score):\n")
    for r in records:
        flag = "" if r["url_ok"] else "   <-- URL not on allow-list: needs human verification"
        print(f"  [{r['score']:>3}] {r['_id']}: {r.get('title', '(no title)')}{flag}")

    print("\nHuman gate on the top item (default = NOT approved -> fail-closed):")
    top = records[0]
    human_gate(f"dispatch '{top['_id']}'", approved=False)  # nothing acts autonomously
    return 0


if __name__ == "__main__":
    sys.exit(run())
