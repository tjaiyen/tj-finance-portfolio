#!/usr/bin/env node
/* ob-mobile-patch.mjs — inject the mobile override stylesheet into the 8 Operations
   Bridge dashboards.
 *
 * Those dashboards exist ONLY as base64 inside src/public/operations-bridge.html (the
 * original assembler was scratchpad-only and is gone), so they cannot be hand-edited.
 * This decodes each one, injects <style id="ob-mobile"> before </head>, and re-encodes.
 *
 * Idempotent: any previously-injected block is stripped before injecting, so re-running
 * with unchanged CSS reproduces the file byte-for-byte and writes nothing.
 *
 *   node tools/ob-mobile-patch.mjs           patch in place
 *   node tools/ob-mobile-patch.mjs --check   read-only; exit 1 if the file is stale
 *
 * Exit codes: 0 ok / up to date · 1 real failure or stale · 2 usage.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const HERE = dirname(fileURLToPath(import.meta.url));
const TARGET = join(HERE, "../src/public/operations-bridge.html");
const CSSSRC = join(HERE, "ob-mobile.css");

/* Asserted, not discovered: a 9th dashboard must be an explicit decision, never a
   silent skip that only shows up on someone's phone. */
const SLUGS = [
  "command-center", "cost-variance", "wip-inventory", "production-ops",
  "ap-procurement", "controls-compliance", "pnl-synthesis", "capital-evm",
];

const die = (msg) => { console.error("ob-mobile-patch: " + msg); process.exit(1); };
const usage = () => { console.error("usage: ob-mobile-patch.mjs [--check]"); process.exit(2); };

const argv = process.argv.slice(2);
if (argv.some((a) => a !== "--check")) usage();
const CHECK = argv.includes("--check");

const CSS = readFileSync(CSSSRC, "utf8").trim();
const VER = createHash("sha256").update(CSS).digest("hex").slice(0, 12);

const original = readFileSync(TARGET, "utf8");
const lines = original.split("\n");

/* Search for the anchor rather than trusting a line number — any edit to the shell above
   it shifts the line, and a duplicated or missing anchor must fail loudly. */
const hits = lines.map((l, i) => (/^var DASH\s*=\s*\{/.test(l) ? i : -1)).filter((i) => i >= 0);
if (hits.length !== 1) die(`expected exactly 1 \`var DASH = {\` line, found ${hits.length}`);
const idx = hits[0];

/* Keep the prefix and suffix verbatim so the only delta is the JSON body. */
const m = lines[idx].match(/^(var DASH\s*=\s*)(\{[\s\S]*\})(\s*;?\s*)$/);
if (!m) die(`line ${idx + 1} matched the DASH prefix but not the full object shape`);
const [, PRE, BODY, POST] = m;

let DASH;
try { DASH = JSON.parse(BODY); } catch (e) { die("DASH is not valid JSON: " + e.message); }

const keys = Object.keys(DASH);
if (keys.length !== SLUGS.length || !SLUGS.every((s) => keys.includes(s)))
  die(`DASH key set changed — expected [${SLUGS}], got [${keys}]. Update SLUGS deliberately.`);

const STRIP = /[ \t]*<style id="ob-mobile"[^>]*>[\s\S]*?<\/style>\r?\n?/g;

for (const k of keys) {
  const html = Buffer.from(DASH[k], "base64").toString("utf8");
  const clean = html.replace(STRIP, "");

  /* Structural invariants. These documents have no other copy, so a surprise means stop,
     not improvise. */
  if ((clean.match(/<style/g) || []).length !== 1) die(`${k}: expected exactly 1 authored <style>`);
  const hi = clean.indexOf("</head>");
  if (hi < 0) die(`${k}: no </head> anchor`);
  if (clean.indexOf("</style>") > hi) die(`${k}: authored <style> closes after </head>`);

  const out = clean.slice(0, hi)
    + `<style id="ob-mobile" data-v="${VER}">\n${CSS}\n</style>\n`
    + clean.slice(hi);

  const b64 = Buffer.from(out, "utf8").toString("base64");
  if (Buffer.from(b64, "base64").toString("utf8") !== out) die(`${k}: base64 round-trip mismatch`);
  DASH[k] = b64;
}

lines[idx] = PRE + JSON.stringify(DASH) + POST;
const next = lines.join("\n");

if (CHECK) {
  if (next !== original) die(`operations-bridge.html is stale (css v${VER}). Run: npm run patch:mobile`);
  console.log(`ob-mobile-patch: up to date (v${VER})`);
  process.exit(0);
}
if (next === original) { console.log(`ob-mobile-patch: no change (v${VER})`); process.exit(0); }
writeFileSync(TARGET, next);
console.log(`ob-mobile-patch: patched ${keys.length} dashboards (v${VER})`);
