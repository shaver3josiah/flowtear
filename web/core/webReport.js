// CycleWebReport — a port of App/Core/CycleWebReport.swift: builds a single
// self-contained HTML string (inline CSS + vanilla JS, no network) presenting
// the last 35 days the way the app would look: her exact theme colors, a live
// countdown ring to the next period, temperature and flow charts with
// hover/touch tooltips, a phase-colored month strip, anything worth
// mentioning, and what's next. Notes are deliberately left on her phone; this
// file is made to be handed to someone she trusts.
//
// Theme colors: read live from getComputedStyle(document.documentElement) —
// the same CSS custom properties web/styles/tokens.css defines, already
// resolved for whatever preset + Theme Editor overrides are active (see
// web/screens/themeEditor.js's currentColor(), same pattern). Pass
// options.tokens (same key shape as TOKEN_VARS below) to skip the DOM read,
// e.g. from a Node test or to render a theme other than the live one.
//
// Pure module: store is passed in, never imported as a singleton. Nothing
// touches `document` at import time — only inside buildWebReport(), and only
// when no options.tokens was supplied.

import { startOfDay, addDays, keyFromDate } from "./dates.js";
import { label, isEmptyLog, FLOW_WEIGHT } from "./models.js";
import { monthShort } from "./format.js";
import { flags as reportFlags } from "./report.js";
import { report as phaseReport } from "./phaseResearch.js";

export function webReportFilename() {
  return "uncorked-cycle-report.html"; // matches CycleWebReport.htmlFile's temp filename
}

// ---- theme tokens ----------------------------------------------------------

// key -> the app's CSS custom property (web/styles/tokens.css).
const TOKEN_VARS = {
  bg: "--bg", surface: "--surface", surfaceSoft: "--surface-soft",
  text: "--text", muted: "--muted", deep: "--deep",
  primary: "--primary", primaryStrong: "--primary-strong",
  line: "--line", good: "--good", flowerCenter: "--flower-center",
  phaseMenstrual: "--phase-menstrual", phaseFollicular: "--phase-follicular",
  phaseFertile: "--phase-fertile", phaseOvulation: "--phase-ovulation", phaseLuteal: "--phase-luteal",
  phaseMenstrualSoft: "--phase-menstrual-soft", phaseFollicularSoft: "--phase-follicular-soft",
  phaseFertileSoft: "--phase-fertile-soft", phaseOvulationSoft: "--phase-ovulation-soft",
  phaseLutealSoft: "--phase-luteal-soft",
  flowSpotting: "--flow-spotting", flowLight: "--flow-light", flowMedium: "--flow-medium",
  flowHeavy: "--flow-heavy", flowSuperHeavy: "--flow-super-heavy",
};

// Cherry preset (web/styles/tokens.css :root) — used only when there's no live
// document to read (e.g. a Node test) and no options.tokens override.
// ponytail: one static fallback swatch, not a full preset table; the live
// getComputedStyle path is what real callers (in-app) hit.
const FALLBACK_TOKENS = {
  bg: "#FDF2F7", surface: "#FFFFFF", surfaceSoft: "#FBE4EE",
  text: "#421527", muted: "#885B6D", deep: "#B01B58",
  primary: "#F06FA7", primaryStrong: "#D23070",
  line: "#F2CEDF", good: "#17703B", flowerCenter: "#FFC966",
  phaseMenstrual: "#E14B7A", phaseFollicular: "#F7A8C6", phaseFertile: "#F6BE6A",
  phaseOvulation: "#EC9A32", phaseLuteal: "#C98BC7",
  phaseMenstrualSoft: "#FBDCE6", phaseFollicularSoft: "#FCE7F0", phaseFertileSoft: "#FDEDD4",
  phaseOvulationSoft: "#FBE4C6", phaseLutealSoft: "#F3E1F1",
  flowSpotting: "#F7C6D9", flowLight: "#F492B7", flowMedium: "#E85C90",
  flowHeavy: "#BE2C60", flowSuperHeavy: "#96164A",
};

function readLiveTokens() {
  if (typeof document === "undefined") return FALLBACK_TOKENS;
  const cs = getComputedStyle(document.documentElement);
  const out = {};
  for (const k in TOKEN_VARS) {
    const v = cs.getPropertyValue(TOKEN_VARS[k]).trim();
    out[k] = v || FALLBACK_TOKENS[k];
  }
  return out;
}

// CycleRing.tint / .softTint — phase -> token key.
const PHASE_TINT_KEY = {
  menstrual: "phaseMenstrual", follicular: "phaseFollicular", fertile: "phaseFertile",
  ovulation: "phaseOvulation", luteal: "phaseLuteal",
};
const PHASE_SOFT_KEY = {
  menstrual: "phaseMenstrualSoft", follicular: "phaseFollicularSoft", fertile: "phaseFertileSoft",
  ovulation: "phaseOvulationSoft", luteal: "phaseLutealSoft",
};
const FLOW_KEY = {
  spotting: "flowSpotting", light: "flowLight", medium: "flowMedium",
  heavy: "flowHeavy", superHeavy: "flowSuperHeavy",
};

// ---- small text/number helpers (mirror CycleWebReport's esc/fmt) ----------

const esc = (s) => String(s)
  .replaceAll("&", "&amp;").replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;").replaceAll('"', "&quot;");

const fmt1 = (v) => v.toFixed(1); // String(format: "%.1f", v)
const mmmD = (d) => `${monthShort(d.getMonth())} ${d.getDate()}`; // DateFormatter "MMM d"
const weekdayD = (d) => `${["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getDay()]} ${d.getDate()}`; // "EEE d"
const longDateStr = (d) => // DateFormatter dateStyle .long, e.g. "July 17, 2026"
  `${["January", "February", "March", "April", "May", "June", "July", "August",
      "September", "October", "November", "December"][d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;

/**
 * Builds the self-contained report HTML. `store` needs logFor(date),
 * phaseSnapshot(date), prediction(today), periodDays and logsSnapshot (the
 * same reads CycleStore.swift's report code uses).
 * options: { recipient?: string, today?: Date, tokens?: object }
 */
export function buildWebReport(store, options = {}) {
  const today = startOfDay(options.today ?? new Date());
  const tokens = options.tokens ?? readLiveTokens();

  // Last 35 days, oldest first (CycleWebReport.swift:31).
  const days = [];
  for (let back = 34; back >= 0; back--) {
    const d = addDays(today, -back);
    days.push({ date: d, log: store.logFor(d), phase: store.phaseSnapshot(d).phase });
  }

  const p = store.prediction(today);
  const flagsList = reportFlags(store, today);
  const expect = p.phase ? phaseReport(p.phase, p.cycleDay ?? 1, Math.max(p.averageCycleLength, 1)) : null;
  const isoNext = p.nextPeriodStart ? `${keyFromDate(p.nextPeriodStart)}T00:00:00` : null;
  const recipient = options.recipient;
  const title = recipient ? `A cycle update for ${esc(recipient)}` : "Cycle report";

  const phaseTint = p.phase ? tokens[PHASE_TINT_KEY[p.phase]] : tokens.primaryStrong;
  const frac = Math.min((p.cycleDay ?? 0) / Math.max(p.averageCycleLength, 1), 1);
  const dash = 2 * Math.PI * 70;
  const dashOffset = dash * (1 - frac);
  const pillBg = p.phase ? tokens[PHASE_SOFT_KEY[p.phase]] : tokens.surfaceSoft;
  const pillInk = tokens.deep; // phasePillInk always returns .deep regardless of phase

  const countdownScript = isoNext ? `
const next = new Date('${isoNext}');
function tick() {
  const ms = next - Date.now();
  const t = document.getElementById('tick');
  if (ms <= 0) {
    const late = Math.floor(-ms / 86400000);
    t.textContent = late === 0 ? 'Expected today.' : 'Running ' + late + (late === 1 ? ' day' : ' days') + ' past the estimate.';
    return;
  }
  const d = Math.floor(ms / 86400000), h = Math.floor(ms % 86400000 / 3600000), m = Math.floor(ms % 3600000 / 60000);
  t.textContent = d + 'd ' + h + 'h ' + m + 'm from now';
}
tick(); setInterval(tick, 30000);
` : "";

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Uncorked, ${title}</title>
<style>
  :root{
    --bg:${tokens.bg}; --surface:${tokens.surface}; --soft:${tokens.surfaceSoft};
    --text:${tokens.text}; --muted:${tokens.muted}; --deep:${tokens.deep};
    --primary:${tokens.primary}; --strong:${tokens.primaryStrong}; --line:${tokens.line};
    --good:${tokens.good}; --gold:${tokens.flowerCenter};
    --menstrual:${tokens.phaseMenstrual}; --follicular:${tokens.phaseFollicular};
    --fertile:${tokens.phaseFertile}; --ovulation:${tokens.phaseOvulation};
    --luteal:${tokens.phaseLuteal};
    --menstrualSoft:${tokens.phaseMenstrualSoft}; --follicularSoft:${tokens.phaseFollicularSoft};
    --fertileSoft:${tokens.phaseFertileSoft}; --ovulationSoft:${tokens.phaseOvulationSoft};
    --lutealSoft:${tokens.phaseLutealSoft};
    --serif:'Playfair Display',Georgia,'Times New Roman',serif;
    --sans:'Quicksand','Avenir Next','Segoe UI',system-ui,sans-serif;
    --script:'Great Vibes','Snell Roundhand','Brush Script MT',cursive;
  }
  *{box-sizing:border-box;margin:0;padding:0}
  html{scroll-behavior:smooth}
  body{background:var(--bg);color:var(--text);font-family:var(--sans);line-height:1.6;
       padding:28px 18px 64px;-webkit-font-smoothing:antialiased}
  .page{max-width:680px;margin:0 auto;display:grid;gap:22px}
  .wordmark{font-family:var(--script);font-size:2rem;color:var(--deep);text-align:center}
  h1{font-family:var(--serif);font-size:clamp(1.7rem,5vw,2.4rem);color:var(--deep);
     text-align:center;text-wrap:balance;line-height:1.2}
  .sub{color:var(--muted);text-align:center;font-size:.92rem}
  .card{background:var(--surface);border:1px solid var(--line);border-radius:20px;padding:22px}
  h2{font-family:var(--serif);font-size:1.25rem;color:var(--deep);margin-bottom:10px}
  .quiet{color:var(--muted);font-size:.88rem}

  /* countdown hero */
  .count{display:flex;flex-wrap:wrap;align-items:center;gap:22px;justify-content:center}
  .ringwrap{position:relative;width:170px;height:170px;flex:0 0 auto}
  .ringwrap svg{width:100%;height:100%}
  .ringcenter{position:absolute;inset:0;display:grid;place-content:center;text-align:center}
  .bignum{font-family:var(--serif);font-size:3rem;font-weight:600;color:var(--deep);line-height:1}
  .bignum small{display:block;font-family:var(--sans);font-size:.72rem;color:var(--muted);
                letter-spacing:.04em;margin-top:6px}
  .countcopy{max-width:300px}
  .countcopy p{margin-top:6px}
  .tick{font-family:var(--serif);color:var(--strong);font-size:1.05rem}
  .pill{display:inline-block;padding:5px 14px;border-radius:999px;font-weight:700;
        font-size:.8rem;background:${pillBg};color:${pillInk}}

  /* month strip */
  .strip{display:grid;grid-template-columns:repeat(7,1fr);gap:6px;margin-top:8px}
  .cell{position:relative;aspect-ratio:1;border-radius:9px;border:1px solid var(--line);
        cursor:default;transition:transform .15s ease-out}
  .cell:hover{transform:scale(1.12)}
  .cell.today{outline:2px solid var(--strong);outline-offset:1px}
  .cell .drop{position:absolute;inset:auto 3px 3px auto;width:8px;height:8px;border-radius:50%}
  .cell .dnum{position:absolute;top:2px;left:5px;font-size:.6rem;color:var(--muted)}
  .legend{display:flex;flex-wrap:wrap;gap:12px;margin-top:12px;font-size:.78rem;color:var(--muted)}
  .legend span{display:inline-flex;align-items:center;gap:5px}
  .legend i{width:11px;height:11px;border-radius:50%;display:inline-block}

  /* charts */
  .chart{width:100%;height:auto;display:block;margin-top:6px;touch-action:pan-y}
  .axis{font-size:11px;fill:var(--muted);font-family:var(--sans)}
  .dot{cursor:pointer;transition:r .12s ease-out}
  .dot:hover{r:7}
  #tip{position:fixed;pointer-events:none;background:var(--deep);color:var(--bg);
       padding:7px 12px;border-radius:11px;font-size:.8rem;opacity:0;transition:opacity .15s;
       z-index:10;max-width:230px;line-height:1.4}

  /* week table */
  .week{display:grid;gap:8px;margin-top:6px}
  .wrow{display:grid;grid-template-columns:74px 1fr;gap:10px;align-items:baseline;
        padding:10px 12px;border-radius:13px;background:var(--soft)}
  .wday{font-family:var(--serif);font-weight:600;color:var(--deep)}
  .chips{display:flex;flex-wrap:wrap;gap:5px}
  .chip{font-size:.72rem;font-weight:700;padding:2px 9px;border-radius:999px;
        background:var(--surface);border:1px solid var(--line);color:var(--text)}
  .chip.flow{border:none;color:#fff}

  /* notes + expect */
  .flag{display:flex;gap:10px;align-items:flex-start;margin-top:9px}
  .flag i{flex:0 0 auto;width:9px;height:9px;border-radius:50%;background:var(--strong);margin-top:8px}
  ul.tips{margin:10px 0 0 1.1em}
  ul.tips li{margin-top:6px}
  .evidence{margin-top:12px;font-size:.78rem;color:var(--muted)}
  footer{text-align:center;color:var(--muted);font-size:.8rem;line-height:1.7}
  footer .wordmark{font-size:1.5rem}

  /* gentle entrance, only when motion is welcome; content visible by default */
  @media (prefers-reduced-motion:no-preference){
    .js .card{opacity:0;transform:translateY(14px);transition:opacity .55s ease-out,transform .55s cubic-bezier(.16,1,.3,1)}
    .js .card.in{opacity:1;transform:none}
  }
  @media print{.card{break-inside:avoid}}
</style>
</head>
<body>
<div class="page">
  <div class="wordmark">Uncorked</div>
  <h1>${title}</h1>
  <p class="sub">Prepared ${esc(longDateStr(today))} from daily logs. Estimates to talk over, never a diagnosis.</p>

  <section class="card">
    <div class="count">
      <div class="ringwrap" role="img" aria-label="Cycle progress ring">
        <svg viewBox="0 0 160 160">
          <circle cx="80" cy="80" r="70" fill="none" stroke="var(--line)" stroke-width="11"/>
          <circle cx="80" cy="80" r="70" fill="none" stroke="${phaseTint}" stroke-width="11"
                  stroke-linecap="round" stroke-dasharray="${fmt1(dash)}"
                  stroke-dashoffset="${fmt1(dashOffset)}" transform="rotate(-90 80 80)"/>
        </svg>
        <div class="ringcenter"><div class="bignum">${countdownNumber(p)}<small>${countdownLabel(p)}</small></div></div>
      </div>
      <div class="countcopy">
        <span class="pill">${p.phase ? `${esc(label(p.phase))} phase` : "Learning her rhythm"}</span>
        <p>${countdownSentence(p)}</p>
        <p class="tick" id="tick" aria-live="off"></p>
      </div>
    </div>
  </section>

  <section class="card">
    <h2>The month, day by day</h2>
    <p class="quiet">${esc(mmmD(days[0].date))} to ${esc(mmmD(today))}. Hover or tap a day.</p>
    <div class="strip">${stripCellsHtml(days, tokens, today)}</div>
    <div class="legend">
      <span><i style="background:var(--menstrual)"></i>Period</span>
      <span><i style="background:var(--follicular)"></i>Follicular</span>
      <span><i style="background:var(--fertile)"></i>Fertile</span>
      <span><i style="background:var(--ovulation)"></i>Ovulation</span>
      <span><i style="background:var(--luteal)"></i>Luteal</span>
      <span><i style="background:${tokens.flowSuperHeavy}"></i>Flow dot, darker is heavier</span>
    </div>
  </section>

  ${temperatureCardHtml(days, tokens)}
  ${flowCardHtml(days, tokens)}

  <section class="card">
    <h2>The past week</h2>
    <div class="week">${weekRowsHtml(days.slice(-7), tokens)}</div>
  </section>

  <section class="card">
    <h2>Worth mentioning</h2>
    ${flagsHtml(flagsList)}
  </section>

  ${expectHtml(expect)}

  <footer>
    <div class="wordmark">Uncorked</div>
    <p>Averages: ${p.averageCycleLength}-day cycle, ${p.averagePeriodLength}-day period.
       Personal notes never leave her phone.<br>
       Made with love, and a flower garden.</p>
  </footer>
</div>

<div id="tip" role="tooltip"></div>
<script>
document.body.classList.add('js');

// Gentle reveal; sections are fully visible if JS or motion is off.
if (matchMedia('(prefers-reduced-motion: no-preference)').matches && 'IntersectionObserver' in window) {
  const io = new IntersectionObserver(es => es.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  }), {threshold: 0.12});
  document.querySelectorAll('.card').forEach(c => io.observe(c));
} else {
  document.querySelectorAll('.card').forEach(c => c.classList.add('in'));
}

// One shared tooltip for day cells and chart dots.
const tip = document.getElementById('tip');
function showTip(el, x, y) {
  tip.textContent = el.dataset.tip;
  tip.style.opacity = 1;
  tip.style.left = Math.min(x + 14, innerWidth - 240) + 'px';
  tip.style.top = (y + 16) + 'px';
}
function hideTip() { tip.style.opacity = 0; }
document.querySelectorAll('[data-tip]').forEach(el => {
  el.addEventListener('mousemove', e => showTip(el, e.clientX, e.clientY));
  el.addEventListener('mouseleave', hideTip);
  el.addEventListener('click', e => { showTip(el, e.clientX, e.clientY); e.stopPropagation(); });
});
document.addEventListener('click', hideTip);

// Live countdown to the predicted next period.
${countdownScript}
</script>
</body>
</html>`;
}

// ---- section builders -------------------------------------------------------

function stripCellsHtml(days, tokens, today) {
  const todayKey = keyFromDate(today);
  return days.map((day) => {
    const soft = day.phase ? tokens[PHASE_SOFT_KEY[day.phase]] : tokens.surfaceSoft;
    const isToday = keyFromDate(day.date) === todayKey;
    const parts = [mmmD(day.date)];
    if (day.phase) parts.push(`${label(day.phase)} phase`);
    if (day.log?.flow) parts.push(`${label(day.log.flow)} flow`);
    const syms = day.log?.symptoms ?? [];
    if (syms.length) parts.push([...syms].map(label).sort().join(", "));
    if (!day.log || isEmptyLog(day.log)) parts.push("nothing logged");
    const drop = day.log?.flow
      ? `<span class="drop" style="background:${tokens[FLOW_KEY[day.log.flow]]}"></span>`
      : "";
    return `<div class="cell${isToday ? " today" : ""}" style="background:${soft}" data-tip="${esc(parts.join(" · "))}"><span class="dnum">${day.date.getDate()}</span>${drop}</div>`;
  }).join("");
}

function temperatureCardHtml(days, tokens) {
  const pts = [];
  days.forEach((d, i) => {
    if (d.log?.temperatureC != null) pts.push({ i, f: d.log.temperatureC * 9 / 5 + 32, date: d.date });
  });
  if (pts.length < 2) {
    return `<section class="card"><h2>Morning temperature</h2><p class="quiet">Not enough temperatures logged this month to draw the line yet.</p></section>`;
  }
  const fs = pts.map((pt) => pt.f);
  const lo = Math.min(...fs) - 0.3, hi = Math.max(...fs) + 0.3;
  const w = 640, h = 200, padL = 44, padR = 14, padT = 16, padB = 30;
  const x = (i) => padL + (i / Math.max(days.length - 1, 1)) * (w - padL - padR);
  const y = (f) => padT + (1 - (f - lo) / (hi - lo)) * (h - padT - padB);
  const line = pts.map((pt) => `${fmt1(x(pt.i))},${fmt1(y(pt.f))}`).join(" ");
  const ov = tokens.phaseOvulation;
  const dots = pts.map((pt) =>
    `<circle class="dot" cx="${fmt1(x(pt.i))}" cy="${fmt1(y(pt.f))}" r="4.5" fill="${ov}" data-tip="${esc(mmmD(pt.date))} · ${pt.f.toFixed(2)}°F"/>`
  ).join("");
  const first = days[0].date, last = days[days.length - 1].date;
  return `<section class="card"><h2>Morning temperature</h2>
<svg class="chart" viewBox="0 0 ${fmt1(w)} ${fmt1(h)}" role="img" aria-label="Temperature line chart">
  <text class="axis" x="6" y="${fmt1(y(hi - 0.3) + 4)}">${(hi - 0.3).toFixed(1)}°</text>
  <text class="axis" x="6" y="${fmt1(y(lo + 0.3) + 4)}">${(lo + 0.3).toFixed(1)}°</text>
  <text class="axis" x="${fmt1(padL)}" y="${fmt1(h - 8)}">${esc(mmmD(first))}</text>
  <text class="axis" x="${fmt1(w - 70)}" y="${fmt1(h - 8)}">${esc(mmmD(last))}</text>
  <line x1="${fmt1(padL)}" y1="${fmt1(h - padB)}" x2="${fmt1(w - padR)}" y2="${fmt1(h - padB)}" stroke="var(--line)"/>
  <polyline points="${line}" fill="none" stroke="${ov}" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
  ${dots}
</svg>
<p class="quiet">A small rise that holds for a few days usually follows ovulation.</p></section>`;
}

function flowCardHtml(days, tokens) {
  if (!days.some((d) => d.log?.flow)) return ""; // no card at all when nothing logged
  const w = 640, h = 150, padL = 14, padB = 30;
  const bw = (w - padL * 2) / days.length;
  const bars = days.map((d, i) => {
    const f = d.log?.flow;
    if (!f) return "";
    const bh = (FLOW_WEIGHT[f] / 5) * (h - padB - 12);
    return `<rect class="dot" x="${fmt1(padL + i * bw + 1)}" y="${fmt1(h - padB - bh)}" width="${fmt1(bw - 2)}" height="${fmt1(bh)}" rx="3" fill="${tokens[FLOW_KEY[f]]}" data-tip="${esc(mmmD(d.date))} · ${esc(label(f))} flow"/>`;
  }).filter(Boolean).join("");
  const first = days[0].date, last = days[days.length - 1].date;
  return `<section class="card"><h2>Flow</h2>
<svg class="chart" viewBox="0 0 ${fmt1(w)} ${fmt1(h)}" role="img" aria-label="Flow bar chart">
  <line x1="${fmt1(padL)}" y1="${fmt1(h - padB)}" x2="${fmt1(w - padL)}" y2="${fmt1(h - padB)}" stroke="var(--line)"/>
  <text class="axis" x="${fmt1(padL)}" y="${fmt1(h - 8)}">${esc(mmmD(first))}</text>
  <text class="axis" x="${fmt1(w - 70)}" y="${fmt1(h - 8)}">${esc(mmmD(last))}</text>
  ${bars}
</svg></section>`;
}

function weekRowsHtml(days7, tokens) {
  return [...days7].reverse().map((day) => {
    const chips = [];
    if (day.log?.flow) {
      chips.push(`<span class="chip flow" style="background:${tokens[FLOW_KEY[day.log.flow]]}">${esc(label(day.log.flow))} flow</span>`);
    }
    for (const m of [...(day.log?.moods ?? [])].map(label).sort()) chips.push(`<span class="chip">${esc(m)}</span>`);
    for (const s of [...(day.log?.symptoms ?? [])].map(label).sort()) chips.push(`<span class="chip">${esc(s)}</span>`);
    if (day.log?.stretchDone === true) chips.push(`<span class="chip" style="color:var(--good)">Stretched</span>`);
    const body = chips.length ? chips.join("") : `<span class="quiet">A quiet day</span>`;
    return `<div class="wrow"><span class="wday">${esc(weekdayD(day.date))}</span><span class="chips">${body}</span></div>`;
  }).join("");
}

function flagsHtml(flagsList) {
  if (!flagsList.length) {
    return `<p>Nothing out of the ordinary this month. Things look steady, which is exactly what you want to see.</p>`;
  }
  return flagsList.map((f) => `<div class="flag"><i></i><p>${esc(f)}</p></div>`).join("");
}

function expectHtml(expect) {
  if (!expect) return "";
  return `<section class="card"><h2>What to expect next</h2>
<p style="font-family:var(--serif);font-weight:600;color:var(--deep)">${esc(expect.title)}</p>
<p style="margin-top:6px">${esc(expect.body)}</p>
<ul class="tips">${expect.tips.map((t) => `<li>${esc(t)}</li>`).join("")}</ul>
<p class="evidence">${esc(expect.evidenceNote)}</p></section>`;
}

// ---- countdown copy ---------------------------------------------------------

function countdownNumber(p) {
  if (p.daysUntilNextPeriod == null) return "?";
  return p.daysUntilNextPeriod < 0 ? String(Math.abs(p.daysUntilNextPeriod)) : String(p.daysUntilNextPeriod);
}

function countdownLabel(p) {
  const d = p.daysUntilNextPeriod;
  if (d == null) return "still learning";
  return d < 0 ? "days late" : d === 1 ? "day to go" : "days to go";
}

function countdownSentence(p) {
  if (!p.hasHistory || !p.nextPeriodStart) {
    return "A month or two of daily logs and this ring fills in with a real prediction.";
  }
  const dayPart = p.cycleDay != null ? `Cycle day ${p.cycleDay} of about ${p.averageCycleLength}. ` : "";
  return `${dayPart}The next period is expected around ${esc(mmmD(p.nextPeriodStart))}.`;
}
