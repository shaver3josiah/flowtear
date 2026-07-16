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
// Sanity: the web enums and the Swift enums should list the same cases.
function checkModelsMirror() {
  const jsPath = "web/core/models.js", swPath = "App/Core/CycleModels.swift";
  if (!existsSync(join(root, jsPath)) || !existsSync(join(root, swPath))) { warn("model files missing"); return; }
  const js = read(jsPath), sw = read(swPath);
  const checks = [
    ["Flow", ["spotting", "light", "medium", "heavy"]],
    ["Discharge", ["dry", "sticky", "creamy", "watery", "eggWhite"]],
  ];
  for (const [enumName, cases] of checks) {
    const missing = cases.filter((c) => !js.includes(`"${c}"`) || !sw.includes(c));
    if (missing.length) fail(`${enumName} cases differ between platforms: ${missing.join(", ")}`);
    else ok(`${enumName} cases match (${cases.length})`);
  }
}
