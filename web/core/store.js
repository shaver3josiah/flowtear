// App state + persistence — a port of App/Core/CycleStore.swift.
// One JSON blob in localStorage (native UserDefaults on iOS), with a backup copy
// kept before every write so a bad write can never destroy her history.
// Predictions are derived on demand from logs (see prediction()).

import { emptyLog, isEmptyLog, FLOW_WEIGHT, DEFAULT_SETTINGS } from "./models.js";
import { keyFromDate, dateFromKey, startOfDay } from "./dates.js";
import { predict } from "./engine.js";
import { buildSampleLogs } from "./sampleData.js";

const K = {
  state: "flowtear.state.v1",
  backup: "flowtear.state.v1.backup",
  fullPlan: "flowtear.stretch.fullplan",
  lastEdit: "flowtear.lastEdit",
  insightsSeen: "flowtear.insightsSeen",
  seeded: "flowtear.sample.seeded",
};

export class CycleStore {
  constructor() {
    this.logs = {}; // dateKey -> DayLog
    this.settings = { ...DEFAULT_SETTINGS };
    this._subs = new Set();
    this._load();
  }

  // ---- subscription (drives React re-renders) ----
  subscribe(fn) { this._subs.add(fn); return () => this._subs.delete(fn); }
  _notify() { this._subs.forEach((f) => f()); }

  // ---- keys / reads ----
  key(date) { return keyFromDate(date); }
  logFor(date) { return this.logs[this.key(date)] ?? null; }
  get logsSnapshot() { return Object.values(this.logs); }
  get hasAnyLogs() { return Object.keys(this.logs).length > 0; }

  // ---- mutations ----
  upsert(log) {
    if (isEmptyLog(log)) delete this.logs[log.dateKey];
    else this.logs[log.dateKey] = log;
    this._save();
    this._noteEdited();
    this._notify();
  }

  _mutateDay(date, fn) {
    const k = this.key(date);
    const l = this.logs[k] ? { ...this.logs[k] } : emptyLog(k);
    fn(l);
    this.upsert(l);
  }

  toggleFlow(flow, date) {
    this._mutateDay(date, (l) => { l.flow = l.flow === flow ? null : flow; });
  }

  setTemperatureC(celsius, date) {
    this._mutateDay(date, (l) => { l.temperatureC = celsius; });
  }

  recentTemperatures(limit = 14) {
    return this.logsSnapshot
      .filter((l) => l.temperatureC != null)
      .map((l) => ({ date: dateFromKey(l.dateKey), celsius: l.temperatureC }))
      .sort((a, b) => a.date - b.date)
      .slice(-limit);
  }

  stretchDone(date) { return this.logFor(date)?.stretchDone ?? false; }
  setStretchDone(done, date) {
    this._mutateDay(date, (l) => { l.stretchDone = done ? true : null; });
  }

  stretchMovesDone(date) { return this.logFor(date)?.stretchMovesDone ?? []; }

  // Toggle one move; when every move is checked the whole day auto-completes.
  // Returns true when this toggle finished the day. Mirrors CycleStore.swift:73.
  toggleStretchMove(index, date, totalMoves) {
    const k = this.key(date);
    const l = this.logs[k] ? { ...this.logs[k] } : emptyLog(k);
    const done = new Set(l.stretchMovesDone ?? []);
    if (done.has(index)) done.delete(index); else done.add(index);
    l.stretchMovesDone = done.size ? [...done].sort((a, b) => a - b) : null;
    const dayComplete = done.size >= totalMoves && totalMoves > 0;
    l.stretchDone = dayComplete ? true : (l.stretchDone === true && done.size === 0 ? null : l.stretchDone);
    this.upsert(l);
    return dayComplete;
  }

  get fullStretchPlan() { return readBool(K.fullPlan); }
  set fullStretchPlan(v) { localStorage.setItem(K.fullPlan, JSON.stringify(!!v)); this._notify(); }

  updateSettings(patch) { this.settings = { ...this.settings, ...patch }; this._save(); this._notify(); }

  // ---- new-insights signal (drives the Insights tab shimmer) ----
  _noteEdited() { localStorage.setItem(K.lastEdit, String(Date.now())); }
  markInsightsSeen() { localStorage.setItem(K.insightsSeen, String(Date.now())); this._notify(); }
  get hasNewInsights() {
    return readNum(K.lastEdit) > readNum(K.insightsSeen) && this.hasAnyLogs;
  }

  // ---- derived ----
  // Real bleeding days that feed cycle math — light/medium/heavy only. Spotting
  // (weight 1) must NOT open a period start (CycleStore.swift:120-128).
  get periodDays() {
    return this.logsSnapshot
      .filter((l) => (l.flow ? FLOW_WEIGHT[l.flow] : 0) >= 2)
      .map((l) => dateFromKey(l.dateKey));
  }

  prediction(today = new Date()) {
    return predict(this.periodDays, today, this.settings);
  }

  // ---- persistence ----
  _save() {
    const snap = JSON.stringify({ logs: this.logsSnapshot, settings: this.settings });
    const prev = localStorage.getItem(K.state);
    if (prev != null) localStorage.setItem(K.backup, prev);
    localStorage.setItem(K.state, snap);
  }

  _load() {
    for (const key of [K.state, K.backup]) {
      const data = localStorage.getItem(key);
      if (!data) continue;
      try {
        const snap = JSON.parse(data);
        this.logs = Object.fromEntries((snap.logs ?? []).map((l) => [l.dateKey, l]));
        this.settings = { ...DEFAULT_SETTINGS, ...(snap.settings ?? {}) };
        return;
      } catch { /* try the backup next */ }
    }
  }

  // ---- sample data (first-launch demo) ----
  get sampleActive() { return readBool(K.seeded) && this.hasAnyLogs; }

  seedSampleIfFirstLaunch() {
    if (this.hasAnyLogs || readBool(K.seeded)) return;
    this.logs = buildSampleLogs();
    this._save();
    localStorage.setItem(K.seeded, "true");
    this._notify();
  }

  clearSampleData() {
    this.logs = {};
    this._save();
    localStorage.setItem(K.seeded, "false");
    this._notify();
  }
}

function readBool(k) { return localStorage.getItem(k) === "true" || localStorage.getItem(k) === '"true"' || localStorage.getItem(k) === "1"; }
function readNum(k) { const v = Number(localStorage.getItem(k)); return Number.isFinite(v) ? v : 0; }
