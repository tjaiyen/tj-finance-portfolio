"""Untrusted-input guardrails for the agentic ops pipeline.

Core principle (the whole point): content fetched from the outside world is DATA,
never instructions. Two cheap, deterministic rules neutralize the classic
prompt-injection vector, and a human gate stands in front of every irreversible action.

Synthetic / illustrative — a sanitized skeleton of a larger private system. Stdlib only.
"""
from __future__ import annotations

import re
from urllib.parse import urlparse

# Only these hosts may become an actionable URL. Everything else is surfaced for
# human verification — never auto-followed. (Synthetic example hosts.)
ALLOWED_HOSTS = {"example-source.com", "example-system.com", "records.example.org"}


def parse_record(text: str) -> dict:
    """Parse ONLY the trusted header of a record; ignore the free-text body.

    A record is markdown-ish: ``key: value`` header lines, then a ``---`` or ``## ``
    that begins the untrusted body. Anything in the body — including lines that look
    like ``priority: high`` or ``url: http://evil`` — is treated as data and never
    parsed into a field. This header-only boundary is what makes everything downstream
    safe from injection: the body cannot override a header value.
    """
    fields: dict[str, str] = {}
    for line in text.splitlines():
        s = line.strip()
        if s == "---" or s.startswith("## "):
            break  # end of trusted header; the body below is untrusted — stop parsing
        key, sep, val = line.partition(":")
        if sep and key.strip():
            k = key.strip().lower()
            if k not in fields:  # first occurrence wins; a later/body line can't clobber it
                fields[k] = val.strip()
    return fields


def vet_url(url: str) -> bool:
    """A URL is actionable only if it is http(s) AND its host is on the allow-list."""
    if not url or not re.match(r"https?://", url, re.I):
        return False
    host = (urlparse(url).hostname or "").lower()
    return host in ALLOWED_HOSTS


def human_gate(action: str, *, approved: bool) -> bool:
    """No irreversible / outward action proceeds without explicit human approval.

    In the real system this blocks on a person; here it's an explicit flag so the
    default (``approved=False``) can never act. Fail-closed by design.
    """
    if not approved:
        print(f"  [human-gate] BLOCKED: '{action}' needs human approval — not executed.")
        return False
    print(f"  [human-gate] approved by human -> executing: '{action}'")
    return True
