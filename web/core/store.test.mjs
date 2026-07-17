// Self-check for the store's v1.1.0 additions. Run: node web/core/store.test.mjs
// Covers the two bits with real semantics: the 3-mode stretch tier (incl. the
// legacy-boolean migration) and previewPrediction's spotting rule.
import assert from "node:assert";

// Minimal localStorage shim — must exist before store.js is imported.
const mem = new Map();
globalThis.localStorage = {
  getItem: (k) => (mem.has(k) ? mem.get(k) : null),
  setItem: (k, v) => mem.set(k, String(v)),
  removeItem: (k) => mem.delete(k),
  clear: () => mem.clear(),
};

const { CycleStore, STRETCH_TIERS } = await import("./store.js");
const { keyFromDate, dateFromKey, addDays } = await import("./dates.js");
const { emptyLog } = await import("./models.js");

const fresh = () => { mem.clear(); return new CycleStore(); };

// ---- stretch tier ----
assert.deepEqual(STRETCH_TIERS, ["trio", "starter", "full"]);

// Default when nothing is stored.
assert.equal(fresh().stretchTier, "starter", "default tier");

// Legacy boolean migrates: fullplan=true -> "full", false -> "starter".
mem.clear(); mem.set("flowtear.stretch.fullplan", "true");
assert.equal(new CycleStore().stretchTier, "full", "legacy true -> full");
mem.clear(); mem.set("flowtear.stretch.fullplan", "false");
assert.equal(new CycleStore().stretchTier, "starter", "legacy false -> starter");

// An explicit tier wins over the legacy boolean, and persists.
mem.clear(); mem.set("flowtear.stretch.fullplan", "true");
const s = new CycleStore();
s.stretchTier = "trio";
assert.equal(s.stretchTier, "trio", "explicit tier set");
assert.equal(mem.get("flowtear.stretch.tier"), "trio", "tier persisted under the new key");
assert.equal(new CycleStore().stretchTier, "trio", "explicit tier beats legacy on reload");

// Junk is ignored rather than persisted.
s.stretchTier = "nonsense";
assert.equal(s.stretchTier, "trio", "invalid tier rejected");

// ---- previewPrediction ----
const today = dateFromKey("2026-06-10");

// No logs at all -> nothing to preview.
assert.equal(fresh().previewPrediction(today).hasHistory, false, "empty store previews nothing");

// A spotting-only day: excluded from real cycle math (weight 1 < 2) but IS a
// valid preview anchor — this is the whole point of previewPrediction.
const sp = fresh();
sp.upsert({ ...emptyLog("2026-06-01"), flow: "spotting" });
assert.equal(sp.prediction(today).hasHistory, false, "spotting must not drive a real prediction");
const prev = sp.previewPrediction(today);
assert.equal(prev.hasHistory, true, "spotting anchors a preview");
assert.equal(keyFromDate(prev.lastPeriodStart), "2026-06-01", "preview anchors on the bleeding day");

// Once a real period exists, preview === the real prediction.
const real = fresh();
for (const k of ["2026-05-01", "2026-05-02", "2026-05-03"]) {
  real.upsert({ ...emptyLog(k), flow: "medium" });
}
assert.equal(real.previewPrediction(today).hasHistory, true);
assert.deepEqual(
  keyFromDate(real.previewPrediction(today).nextPeriodStart),
  keyFromDate(real.prediction(today).nextPeriodStart),
  "preview defers to the real prediction once history exists",
);

// A log with no flow at all still anchors a preview (falls back to first log).
const noFlow = fresh();
noFlow.upsert({ ...emptyLog("2026-06-02"), note: "just a note" });
assert.equal(noFlow.previewPrediction(today).hasHistory, true, "any log anchors a preview");

// ---- backup & restore (v1.2.0) ----
const src = fresh();
src.upsert({ ...emptyLog("2026-05-01"), flow: "medium", note: "héllo — utf8 ✓" });
src.updateSettings({ defaultCycleLength: 31, lockCycleLength: true });
const blob = src.backupData();
assert.equal(CycleStore.isValidBackup(blob), true, "own backup validates");
assert.equal(CycleStore.isValidBackup("{nope"), false, "garbage rejected");
assert.equal(CycleStore.isValidBackup('{"a":1}'), false, "wrong shape rejected");

const dst = fresh();
mem.set("flowtear.sample.seeded", "true"); // restoring real data retires the sample
assert.equal(dst.restore("{corrupt"), false, "corrupt restore refuses");
assert.equal(dst.hasAnyLogs, false, "refused restore changed nothing");
assert.equal(dst.restore(blob), true, "valid restore succeeds");
assert.equal(dst.logFor(dateFromKey("2026-05-01")).note, "héllo — utf8 ✓", "logs survive round-trip");
assert.equal(dst.settings.lockCycleLength, true, "settings survive round-trip");
assert.equal(mem.get("flowtear.sample.seeded"), "false", "sample banner retired on restore");

// ---- symptom history + streak (v1.4.0) ----
const h = fresh();
h.upsert({ ...emptyLog("2026-05-02"), symptoms: ["cramps"] });
h.upsert({ ...emptyLog("2026-05-20"), symptoms: ["cramps", "bloating"] });
h.upsert({ ...emptyLog("2026-06-05"), symptoms: ["cramps"] });
assert.deepEqual(h.daysFelt("cramps").map(keyFromDate), ["2026-05-02", "2026-05-20", "2026-06-05"], "daysFelt sorted oldest->newest");
assert.deepEqual(h.daysFelt("bloating").map(keyFromDate), ["2026-05-20"]);
assert.equal(h.daysFelt("acne").length, 0, "never-felt symptom is empty");
// lastFelt is strictly BEFORE the cutoff (never the day itself).
assert.equal(keyFromDate(h.lastFelt("cramps", dateFromKey("2026-06-05"))), "2026-05-20", "lastFelt excludes the day itself");
assert.equal(h.lastFelt("cramps", dateFromKey("2026-05-02")), null, "nothing before the first time");

// phaseSnapshot judges a past date only from the history that existed by then.
const snap = fresh();
for (const k of ["2026-04-01", "2026-04-02", "2026-04-03", "2026-04-29", "2026-04-30", "2026-05-01"]) {
  snap.upsert({ ...emptyLog(k), flow: "medium" });
}
assert.equal(snap.phaseSnapshot(dateFromKey("2026-04-02")).phase, "menstrual", "day 2 of a period reads menstrual");
assert.equal(snap.phaseSnapshot(dateFromKey("2026-04-02")).day, 2, "cycle day at that date");

// stretchStreak: an unfinished today never breaks a run she's still on.
const st = fresh();
const kd = (n) => keyFromDate(addDays(new Date(), n));
st.upsert({ ...emptyLog(kd(-1)), stretchDone: true });
st.upsert({ ...emptyLog(kd(-2)), stretchDone: true });
assert.equal(st.stretchStreak(new Date()), 2, "yesterday+2 days ago count while today is unfinished");
st.upsert({ ...emptyLog(kd(0)), stretchDone: true });
assert.equal(st.stretchStreak(new Date()), 3, "finishing today extends the run");
assert.equal(fresh().stretchStreak(new Date()), 0, "no stretches, no streak");

console.log("store.test.mjs: all assertions passed");
