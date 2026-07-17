// Cross-platform drift detector — "is a platform an outdated version?"
// Run: npm run check:parity
//
// It reports three things:
//   1. VERSION STAMPS — does each platform's ContractsVersion match the manifest?
//      Flags whichever of iOS / web has fallen behind (or run ahead).
//   2. ALGORITHM — does the web engine still reproduce contracts/cycle-vectors.json?
//   3. TOKENS/MODELS — presence + basic mirror sanity of the shared files.
// Exits non-zero on real drift so it can gate a commit or CI.
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { predict } from "../web/core/engine.js";
import { dateFromKey, keyFromDate } from "../web/core/dates.js";
import { CONTRACTS_VERSION as WEB_VERSION } from "../web/core/version.js";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (p) => readFileSync(join(root, p), "utf8");
let problems = 0;
const log = (s) => console.log(s);
const warn = (s) => { console.log("  ⚠️  " + s); };
const fail = (s) => { console.log("  ❌ " + s); problems++; };
const ok = (s) => console.log("  ✅ " + s);

log("\nUncorked · cross-platform parity check\n" + "─".repeat(42));

// ── 1. Version stamps ──────────────────────────────────────────────
const manifest = JSON.parse(read("contracts/manifest.json"));
const contractV = manifest.contractsVersion;
log(`\ncontracts version: ${contractV}`);

const iosSwift = existsSync(join(root, "App/Core/ContractsVersion.swift"))
  ? read("App/Core/ContractsVersion.swift") : "";
const iosV = (iosSwift.match(/static let version\s*=\s*"([^"]+)"/) || [])[1] || null;

for (const [name, v] of [["iOS (App/)", iosV], ["web (web/)", WEB_VERSION]]) {
  if (v == null) { warn(`${name}: no version stamp found`); continue; }
  if (v === contractV) ok(`${name} is in sync (v${v})`);
  else if (cmp(v, contractV) < 0) fail(`${name} is BEHIND — built against v${v}, contracts at v${contractV}. This platform is an outdated version.`);
  else fail(`${name} is AHEAD — stamped v${v} but contracts say v${contractV}. Bump contractsVersion.`);
}

// ── 2. Algorithm vs golden vectors ─────────────────────────────────
log("\nalgorithm (web engine vs golden vectors):");
if (!existsSync(join(root, "contracts/cycle-vectors.json"))) {
  warn("contracts/cycle-vectors.json missing — run `npm run gen:vectors`.");
} else {
  const gv = JSON.parse(read("contracts/cycle-vectors.json"));
  let mism = 0;
  for (const [name, vec] of Object.entries(gv.vectors)) {
    const p = predict(vec.input.periodKeys.map(dateFromKey), dateFromKey(vec.input.today), vec.input.settings);
    const got = {
      averageCycleLength: p.averageCycleLength, averagePeriodLength: p.averagePeriodLength,
      lastPeriodStart: iso(p.lastPeriodStart), nextPeriodStart: iso(p.nextPeriodStart),
      ovulationDate: iso(p.ovulationDate), fertileStart: iso(p.fertileStart), fertileEnd: iso(p.fertileEnd),
      cycleDay: p.cycleDay, phase: p.phase, daysUntilNextPeriod: p.daysUntilNextPeriod, hasHistory: p.hasHistory,
    };
    if (JSON.stringify(got) !== JSON.stringify(vec.expect)) { fail(`vector "${name}" no longer matches — web engine drifted from the golden spec.`); mism++; }
  }
  if (mism === 0) ok(`all ${Object.keys(gv.vectors).length} vectors reproduce`);
}

// ── 3. Shared files present + basic model mirror ───────────────────
log("\nshared files:");
checkExists("contracts/tokens.json", true);
checkExists("web/styles/tokens.css", false);
checkModelsMirror();

log("\n" + "─".repeat(42));
if (problems === 0) log("✅ In sync. No drift detected.\n");
else log(`❌ ${problems} drift problem(s). See above.\n`);
process.exit(problems === 0 ? 0 : 1);

// ── helpers ────────────────────────────────────────────────────────
function iso(d) { return d ? keyFromDate(d) : null; }
function cmp(a, b) {
  const pa = a.split(".").map(Number), pb = b.split(".").map(Number);
  for (let i = 0; i < 3; i++) { if ((pa[i] || 0) !== (pb[i] || 0)) return (pa[i] || 0) - (pb[i] || 0); }
  return 0;
}
function checkExists(p, hard) {
  if (existsSync(join(root, p))) ok(`${p} present`);
  else if (hard) fail(`${p} missing`); else warn(`${p} missing (build the web app to create it)`);
}
// The web enums and the Swift enums must list the SAME cases.
//
// This EXTRACTS both sides and compares them as sets, in both directions. An
// earlier version hardcoded the expected case list and only asserted those
// existed in both files — which silently missed an ADDED case (Swift grew
// Flow.superHeavy and this check still said "match"). Never assert against a
// list you wrote down; read both sources.
function swiftEnumCases(src, name) {
  // Bound the enum to its OWN body by brace-matching (a fixed window bleeds
  // into the next enum), then take only `case a, b, c` DECLARATIONS — a
  // switch's `case .superHeavy:` has a leading dot and a colon, and must not
  // be mistaken for one.
  const head = new RegExp(`enum\\s+${name}\\s*:[^{]*\\{`).exec(src);
  if (!head) return null;
  let i = head.index + head[0].length, depth = 1;
  while (i < src.length && depth > 0) {
    if (src[i] === "{") depth++;
    else if (src[i] === "}") depth--;
    i++;
  }
  const body = src.slice(head.index, i);
  const out = [];
  for (const m of body.matchAll(/^[ \t]*case[ \t]+([A-Za-z_][A-Za-z0-9_,\s]*)$/gm)) {
    for (const part of m[1].split(",")) {
      const id = part.trim();
      if (id) out.push(id);
    }
  }
  return out.length ? out : null;
}
function jsArrayLiteral(src, name) {
  const m = src.match(new RegExp(`export const ${name}\\s*=\\s*\\[([^\\]]*)\\]`));
  if (!m) return null;
  return [...m[1].matchAll(/"([^"]+)"/g)].map((x) => x[1]);
}
function checkModelsMirror() {
  const jsPath = "web/core/models.js", swPath = "App/Core/CycleModels.swift";
  if (!existsSync(join(root, jsPath)) || !existsSync(join(root, swPath))) { warn("model files missing"); return; }
  const js = read(jsPath), sw = read(swPath);
  // Swift enum name -> the web's exported array of the same vocabulary.
  for (const [enumName, jsName] of [["Flow", "FLOW"], ["Mood", "MOODS"], ["Symptom", "SYMPTOMS"], ["Discharge", "DISCHARGE"]]) {
    const a = swiftEnumCases(sw, enumName);
    const b = jsArrayLiteral(js, jsName);
    if (!a || !b) { warn(`${enumName}: couldn't read cases from ${!a ? swPath : jsPath}`); continue; }
    const onlyIOS = a.filter((c) => !b.includes(c));
    const onlyWeb = b.filter((c) => !a.includes(c));
    if (onlyIOS.length || onlyWeb.length) {
      const bits = [];
      if (onlyIOS.length) bits.push(`iOS-only: ${onlyIOS.join(", ")}`);
      if (onlyWeb.length) bits.push(`web-only: ${onlyWeb.join(", ")}`);
      fail(`${enumName} cases differ — ${bits.join(" · ")}`);
    } else ok(`${enumName} cases match (${a.length})`);
  }
}
