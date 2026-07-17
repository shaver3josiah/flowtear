import SwiftUI

// CycleWebReport — the beautiful shareable: a single self-contained HTML file
// (inline CSS + vanilla JS, no network, opens in any browser) that presents
// her recent month the way the app would: her exact theme colors, the serif
// voice, a live countdown ring to the next period, temperature and flow
// charts with touch/hover tooltips, a phase-colored month strip, anything
// worth mentioning, and what to expect next. Notes are deliberately left on
// her phone; this file is made to be sent to someone she trusts.
enum CycleWebReport {

    /// Writes the report to a temp file for the share sheet / mail composer.
    static func htmlFile(store: CycleStore, theme: Theme, recipient: String? = nil) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("uncorked-cycle-report.html")
        do {
            try html(store: store, theme: theme, recipient: recipient)
                .write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch { return nil }
    }

    // MARK: - the page

    static func html(store: CycleStore, theme: Theme, recipient: String? = nil) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let p = store.prediction()

        // Last 35 days, oldest first: the month the report tells.
        let days: [(date: Date, log: DayLog?, phase: CyclePhase?)] = (0..<35).reversed().compactMap { back in
            guard let d = cal.date(byAdding: .day, value: -back, to: today) else { return nil }
            return (d, store.log(for: d), store.phaseSnapshot(at: d).phase)
        }

        let df = DateFormatter(); df.dateFormat = "MMM d"
        let dfLong = DateFormatter(); dfLong.dateStyle = .long

        let phaseTint = p.phase.map { hx(theme, CycleRing.tint($0)) } ?? hx(theme, .primaryStrong)
        let frac = min(Double(p.cycleDay ?? 0) / Double(max(p.averageCycleLength, 1)), 1)
        let dash = 2 * Double.pi * 70
        let flags = CycleReport.flags(store: store)
        let expect = p.phase.map {
            PhaseResearch.report(for: $0, day: p.cycleDay ?? 1, cycleLength: max(p.averageCycleLength, 1))
        }

        // ISO date for the live JS countdown (midnight local of the predicted day).
        let isoNext = p.nextPeriodStart.map {
            CycleStore.dateFmt.string(from: $0) + "T00:00:00"
        }

        let title = recipient.map { "A cycle update for \(esc($0))" } ?? "Cycle report"

        return #"""
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Uncorked, \#(title)</title>
<style>
  :root{
    --bg:\#(hx(theme, .bg)); --surface:\#(hx(theme, .surface)); --soft:\#(hx(theme, .surfaceSoft));
    --text:\#(hx(theme, .text)); --muted:\#(hx(theme, .muted)); --deep:\#(hx(theme, .deep));
    --primary:\#(hx(theme, .primary)); --strong:\#(hx(theme, .primaryStrong)); --line:\#(hx(theme, .line));
    --good:\#(hx(theme, .good)); --gold:\#(hx(theme, .flowerCenter));
    --menstrual:\#(hx(theme, .phaseMenstrual)); --follicular:\#(hx(theme, .phaseFollicular));
    --fertile:\#(hx(theme, .phaseFertile)); --ovulation:\#(hx(theme, .phaseOvulation));
    --luteal:\#(hx(theme, .phaseLuteal));
    --menstrualSoft:\#(hx(theme, .phaseMenstrualSoft)); --follicularSoft:\#(hx(theme, .phaseFollicularSoft));
    --fertileSoft:\#(hx(theme, .phaseFertileSoft)); --ovulationSoft:\#(hx(theme, .phaseOvulationSoft));
    --lutealSoft:\#(hx(theme, .phaseLutealSoft));
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
        font-size:.8rem;background:\#(phasePillBg(theme, p.phase));color:\#(phasePillInk(theme, p.phase))}

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
  <h1>\#(title)</h1>
  <p class="sub">Prepared \#(esc(dfLong.string(from: Date()))) from daily logs. Estimates to talk over, never a diagnosis.</p>

  <section class="card">
    <div class="count">
      <div class="ringwrap" role="img" aria-label="Cycle progress ring">
        <svg viewBox="0 0 160 160">
          <circle cx="80" cy="80" r="70" fill="none" stroke="var(--line)" stroke-width="11"/>
          <circle cx="80" cy="80" r="70" fill="none" stroke="\#(phaseTint)" stroke-width="11"
                  stroke-linecap="round" stroke-dasharray="\#(fmt(dash))"
                  stroke-dashoffset="\#(fmt(dash * (1 - frac)))" transform="rotate(-90 80 80)"/>
        </svg>
        <div class="ringcenter"><div class="bignum">\#(countdownNumber(p))<small>\#(countdownLabel(p))</small></div></div>
      </div>
      <div class="countcopy">
        <span class="pill">\#(p.phase.map { esc($0.label) + " phase" } ?? "Learning her rhythm")</span>
        <p>\#(countdownSentence(p, df: df))</p>
        <p class="tick" id="tick" aria-live="off"></p>
      </div>
    </div>
  </section>

  <section class="card">
    <h2>The month, day by day</h2>
    <p class="quiet">\#(esc(df.string(from: days.first?.date ?? today))) to \#(esc(df.string(from: today))). Hover or tap a day.</p>
    <div class="strip">\#(stripCells(days: days, theme: theme, today: today, df: df))</div>
    <div class="legend">
      <span><i style="background:var(--menstrual)"></i>Period</span>
      <span><i style="background:var(--follicular)"></i>Follicular</span>
      <span><i style="background:var(--fertile)"></i>Fertile</span>
      <span><i style="background:var(--ovulation)"></i>Ovulation</span>
      <span><i style="background:var(--luteal)"></i>Luteal</span>
      <span><i style="background:\#(hx(theme, .flowSuperHeavy))"></i>Flow dot, darker is heavier</span>
    </div>
  </section>

  \#(temperatureCard(days: days, theme: theme, df: df))
  \#(flowCard(days: days, theme: theme, df: df))

  <section class="card">
    <h2>The past week</h2>
    <div class="week">\#(weekRows(days: Array(days.suffix(7)), theme: theme))</div>
  </section>

  <section class="card">
    <h2>Worth mentioning</h2>
    \#(flags.isEmpty
        ? #"<p>Nothing out of the ordinary this month. Things look steady, which is exactly what you want to see.</p>"#
        : flags.map { #"<div class="flag"><i></i><p>\#(esc($0))</p></div>"# }.joined())
  </section>

  \#(expectCard(expect))

  <footer>
    <div class="wordmark">Uncorked</div>
    <p>Averages: \#(p.averageCycleLength)-day cycle, \#(p.averagePeriodLength)-day period.
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
\#(isoNext.map { iso in #"""
const next = new Date('\#(iso)');
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
"""# } ?? "")
</script>
</body>
</html>
"""#
    }

    // MARK: - section builders

    private static func stripCells(days: [(date: Date, log: DayLog?, phase: CyclePhase?)],
                                   theme: Theme, today: Date, df: DateFormatter) -> String {
        let cal = Calendar.current
        return days.map { day in
            let soft = day.phase.map { softHex(theme, $0) } ?? hx(theme, .surfaceSoft)
            let isToday = cal.isDate(day.date, inSameDayAs: today)
            var tipParts = [df.string(from: day.date)]
            if let ph = day.phase { tipParts.append("\(ph.label) phase") }
            if let f = day.log?.flow { tipParts.append("\(f.label) flow") }
            if let syms = day.log?.symptoms, !syms.isEmpty {
                tipParts.append(syms.map(\.label).sorted().joined(separator: ", "))
            }
            if day.log == nil || day.log?.isEmpty == true { tipParts.append("nothing logged") }
            let drop = day.log?.flow.map {
                #"<span class="drop" style="background:\#(flowHex(theme, $0))"></span>"#
            } ?? ""
            let num = cal.component(.day, from: day.date)
            return #"<div class="cell\#(isToday ? " today" : "")" style="background:\#(soft)" data-tip="\#(esc(tipParts.joined(separator: " · ")))"><span class="dnum">\#(num)</span>\#(drop)</div>"#
        }.joined()
    }

    private static func temperatureCard(days: [(date: Date, log: DayLog?, phase: CyclePhase?)],
                                        theme: Theme, df: DateFormatter) -> String {
        let pts: [(i: Int, f: Double, date: Date)] = days.enumerated().compactMap { i, d in
            d.log?.temperatureC.map { (i, $0 * 9 / 5 + 32, d.date) }
        }
        guard pts.count >= 2 else {
            return #"<section class="card"><h2>Morning temperature</h2><p class="quiet">Not enough temperatures logged this month to draw the line yet.</p></section>"#
        }
        let lo = (pts.map(\.f).min() ?? 97) - 0.3
        let hi = (pts.map(\.f).max() ?? 99) + 0.3
        let w = 640.0, h = 200.0, padL = 44.0, padR = 14.0, padT = 16.0, padB = 30.0
        func x(_ i: Int) -> Double { padL + Double(i) / Double(max(days.count - 1, 1)) * (w - padL - padR) }
        func y(_ f: Double) -> Double { padT + (1 - (f - lo) / (hi - lo)) * (h - padT - padB) }
        let line = pts.map { "\(fmt(x($0.i))),\(fmt(y($0.f)))" }.joined(separator: " ")
        let dots = pts.map {
            #"<circle class="dot" cx="\#(fmt(x($0.i)))" cy="\#(fmt(y($0.f)))" r="4.5" fill="\#(hx(theme, .phaseOvulation))" data-tip="\#(esc(df.string(from: $0.date))) · \#(String(format: "%.2f", $0.f))°F"/>"#
        }.joined()
        return #"""
<section class="card"><h2>Morning temperature</h2>
<svg class="chart" viewBox="0 0 \#(fmt(w)) \#(fmt(h))" role="img" aria-label="Temperature line chart">
  <text class="axis" x="6" y="\#(fmt(y(hi - 0.3) + 4))">\#(String(format: "%.1f", hi - 0.3))°</text>
  <text class="axis" x="6" y="\#(fmt(y(lo + 0.3) + 4))">\#(String(format: "%.1f", lo + 0.3))°</text>
  <text class="axis" x="\#(fmt(padL))" y="\#(fmt(h - 8))">\#(esc(df.string(from: days.first!.date)))</text>
  <text class="axis" x="\#(fmt(w - 70))" y="\#(fmt(h - 8))">\#(esc(df.string(from: days.last!.date)))</text>
  <line x1="\#(fmt(padL))" y1="\#(fmt(h - padB))" x2="\#(fmt(w - padR))" y2="\#(fmt(h - padB))" stroke="var(--line)"/>
  <polyline points="\#(line)" fill="none" stroke="\#(hx(theme, .phaseOvulation))" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"/>
  \#(dots)
</svg>
<p class="quiet">A small rise that holds for a few days usually follows ovulation.</p></section>
"""#
    }

    private static func flowCard(days: [(date: Date, log: DayLog?, phase: CyclePhase?)],
                                 theme: Theme, df: DateFormatter) -> String {
        guard days.contains(where: { $0.log?.flow != nil }) else { return "" }
        let w = 640.0, h = 150.0, padL = 14.0, padB = 30.0
        let bw = (w - padL * 2) / Double(days.count)
        let bars = days.enumerated().compactMap { i, d -> String? in
            guard let f = d.log?.flow else { return nil }
            let bh = Double(f.weight) / 5.0 * (h - padB - 12)
            return #"<rect class="dot" x="\#(fmt(padL + Double(i) * bw + 1))" y="\#(fmt(h - padB - bh))" width="\#(fmt(bw - 2))" height="\#(fmt(bh))" rx="3" fill="\#(flowHex(theme, f))" data-tip="\#(esc(df.string(from: d.date))) · \#(esc(f.label)) flow"/>"#
        }.joined()
        return #"""
<section class="card"><h2>Flow</h2>
<svg class="chart" viewBox="0 0 \#(fmt(w)) \#(fmt(h))" role="img" aria-label="Flow bar chart">
  <line x1="\#(fmt(padL))" y1="\#(fmt(h - padB))" x2="\#(fmt(w - padL))" y2="\#(fmt(h - padB))" stroke="var(--line)"/>
  <text class="axis" x="\#(fmt(padL))" y="\#(fmt(h - 8))">\#(esc(df.string(from: days.first!.date)))</text>
  <text class="axis" x="\#(fmt(w - 70))" y="\#(fmt(h - 8))">\#(esc(df.string(from: days.last!.date)))</text>
  \#(bars)
</svg></section>
"""#
    }

    private static func weekRows(days: [(date: Date, log: DayLog?, phase: CyclePhase?)],
                                 theme: Theme) -> String {
        let wd = DateFormatter(); wd.dateFormat = "EEE d"
        return days.reversed().map { day in
            var chips: [String] = []
            if let f = day.log?.flow {
                chips.append(#"<span class="chip flow" style="background:\#(flowHex(theme, f))">\#(esc(f.label)) flow</span>"#)
            }
            for m in (day.log?.moods ?? []).map(\.label).sorted() { chips.append(#"<span class="chip">\#(esc(m))</span>"#) }
            for s in (day.log?.symptoms ?? []).map(\.label).sorted() { chips.append(#"<span class="chip">\#(esc(s))</span>"#) }
            if day.log?.stretchDone == true { chips.append(#"<span class="chip" style="color:var(--good)">Stretched</span>"#) }
            let body = chips.isEmpty ? #"<span class="quiet">A quiet day</span>"# : chips.joined()
            return #"<div class="wrow"><span class="wday">\#(esc(wd.string(from: day.date)))</span><span class="chips">\#(body)</span></div>"#
        }.joined()
    }

    private static func expectCard(_ r: PhaseReport?) -> String {
        guard let r else { return "" }
        return #"""
<section class="card"><h2>What to expect next</h2>
<p style="font-family:var(--serif);font-weight:600;color:var(--deep)">\#(esc(r.title))</p>
<p style="margin-top:6px">\#(esc(r.body))</p>
<ul class="tips">\#(r.tips.map { "<li>\(esc($0))</li>" }.joined())</ul>
<p class="evidence">\#(esc(r.evidenceNote))</p></section>
"""#
    }

    // MARK: - countdown copy

    private static func countdownNumber(_ p: CyclePrediction) -> String {
        guard let d = p.daysUntilNextPeriod else { return "?" }
        return d < 0 ? "\(abs(d))" : "\(d)"
    }

    private static func countdownLabel(_ p: CyclePrediction) -> String {
        guard let d = p.daysUntilNextPeriod else { return "still learning" }
        return d < 0 ? "days late" : (d == 1 ? "day to go" : "days to go")
    }

    private static func countdownSentence(_ p: CyclePrediction, df: DateFormatter) -> String {
        guard p.hasHistory, let next = p.nextPeriodStart else {
            return "A month or two of daily logs and this ring fills in with a real prediction."
        }
        let day = p.cycleDay.map { "Cycle day \($0) of about \(p.averageCycleLength). " } ?? ""
        return "\(day)The next period is expected around \(esc(df.string(from: next)))."
    }

    // MARK: - color + text helpers

    private static func hx(_ theme: Theme, _ t: Tok) -> String { Theme.hex(from: theme.color(t)) }

    private static func softHex(_ theme: Theme, _ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:  hx(theme, .phaseMenstrualSoft)
        case .follicular: hx(theme, .phaseFollicularSoft)
        case .fertile:    hx(theme, .phaseFertileSoft)
        case .ovulation:  hx(theme, .phaseOvulationSoft)
        case .luteal:     hx(theme, .phaseLutealSoft)
        }
    }

    private static func flowHex(_ theme: Theme, _ f: Flow) -> String {
        switch f {
        case .spotting:   hx(theme, .flowSpotting)
        case .light:      hx(theme, .flowLight)
        case .medium:     hx(theme, .flowMedium)
        case .heavy:      hx(theme, .flowHeavy)
        case .superHeavy: hx(theme, .flowSuperHeavy)
        }
    }

    private static func phasePillBg(_ theme: Theme, _ phase: CyclePhase?) -> String {
        phase.map { softHex(theme, $0) } ?? hx(theme, .surfaceSoft)
    }

    private static func phasePillInk(_ theme: Theme, _ phase: CyclePhase?) -> String {
        hx(theme, .deep)
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func fmt(_ v: Double) -> String { String(format: "%.1f", v) }
}
