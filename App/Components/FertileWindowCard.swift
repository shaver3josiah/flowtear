import SwiftUI

// Fertile window + basal body temperature (BBT). Shows the estimated fertile
// window and ovulation day, lets her log today's waking temperature (°F), and
// charts the recent trend — the sustained rise is what confirms ovulation.
// Estimates only, and explicitly NOT a contraceptive method.
struct FertileWindowCard: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store

    private var p: CyclePrediction { store.prediction() }
    private var today: Date { Date() }
    private let cal = Calendar.current

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: 14) {
                header
                windowRows
                Divider().overlay(theme.color(.line))
                tempSection
                Text("Estimates, not a birth-control method.")
                    .font(ffBody(FFType.xs2))
                    .foregroundStyle(theme.color(.muted))
            }
        }
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.color(.phaseFertile))
            Text("Fertile window")
                .font(ffBody(FFType.md, weight: .semibold))
                .foregroundStyle(theme.color(.deep))
            Spacer(minLength: 0)
            if let status = statusText {
                FFBadge(status, tint: .phaseFertile, dot: true)
            }
        }
    }

    // "Fertile now" while inside the window, "In Nd" when it opens soon.
    private var statusText: String? {
        guard let s = p.fertileStart, let e = p.fertileEnd else { return nil }
        let d0 = cal.startOfDay(for: today)
        let start = cal.startOfDay(for: s)
        if d0 >= start && d0 <= cal.startOfDay(for: e) { return "Fertile now" }
        if d0 < start, let days = cal.dateComponents([.day], from: d0, to: start).day, days <= 14 {
            return "In \(days)d"
        }
        return nil
    }

    // MARK: window rows

    @ViewBuilder private var windowRows: some View {
        if let s = p.fertileStart, let e = p.fertileEnd {
            infoRow("Window", "\(fmt(s)) – \(fmt(e))", .phaseFertile)
        }
        if let ov = p.ovulationDate {
            infoRow("Ovulation (est.)", fmt(ov), .phaseOvulation)
        }
        if p.fertileStart == nil {
            Text("Log a couple of cycles to estimate your fertile window.")
                .font(ffBody(FFType.sm))
                .foregroundStyle(theme.color(.muted))
        }
    }

    private func infoRow(_ label: String, _ value: String, _ tint: Tok) -> some View {
        HStack {
            Circle().fill(theme.color(tint)).frame(width: 8, height: 8)
            Text(label).font(ffBody(FFType.sm)).foregroundStyle(theme.color(.text))
            Spacer()
            Text(value).font(ffBody(FFType.sm, weight: .semibold)).foregroundStyle(theme.color(.deep))
        }
    }

    // MARK: basal temperature

    private var tempF: Double? {
        store.log(for: today)?.temperatureC.map { $0 * 9 / 5 + 32 }
    }

    @ViewBuilder private var tempSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Basal temperature")
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(.text))
                Spacer()
                if tempF != nil {
                    Button { store.setTemperatureC(nil, on: today) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.color(.muted))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove today's temperature")
                }
            }

            if let f = tempF {
                Text(String(format: "%.2f °F", f))
                    .font(ffNumber(FFType.xl, weight: .semibold))
                    .foregroundStyle(theme.color(.deep))
                    .contentTransition(.numericText())
                Slider(value: tempBinding, in: 96.0...100.0, step: 0.05)
                    .tint(theme.color(.phaseFertile))
                    .sensoryFeedback(.selection, trigger: tempF)
                    .accessibilityLabel("Basal temperature")
                    .accessibilityValue(String(format: "%.2f degrees Fahrenheit", f))

                let temps = store.recentTemperatures()
                if temps.count >= 2 { sparkline(temps) }
            } else {
                FFButton("Log today's temp", style: .soft, size: .sm, icon: "plus") {
                    store.setTemperatureC(fToC(97.8), on: today)   // seed a typical reading
                }
            }
        }
    }

    private var tempBinding: Binding<Double> {
        Binding(
            get: { tempF ?? 97.8 },
            set: { store.setTemperatureC(fToC($0), on: today) }
        )
    }

    // Simple normalized line of the recent readings (in °F).
    private func sparkline(_ temps: [(date: Date, celsius: Double)]) -> some View {
        let fs = temps.map { $0.celsius * 9 / 5 + 32 }
        let lo = (fs.min() ?? 97) - 0.1
        let hi = (fs.max() ?? 98) + 0.1
        let span = max(hi - lo, 0.2)
        return GeometryReader { geo in
            Path { path in
                for (i, f) in fs.enumerated() {
                    let x = fs.count == 1 ? geo.size.width / 2
                          : geo.size.width * CGFloat(i) / CGFloat(fs.count - 1)
                    let y = geo.size.height * (1 - CGFloat((f - lo) / span))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(theme.color(.phaseFertile),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 40)
        .accessibilityLabel("Recent basal temperature trend, \(temps.count) readings")
    }

    private func fToC(_ f: Double) -> Double { (f - 32) * 5 / 9 }
    private func fmt(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated).day()) }
}
