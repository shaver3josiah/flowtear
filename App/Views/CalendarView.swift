import SwiftUI

// CalendarView — the month calendar (DS Flowtear/calendar-screen). One FFCard
// holds the month pager, weekday row, and a 7-col grid of DayCell: each day
// carries its own phase-soft wash, period fill, dashed predicted ring, fertile
// band, and ovulation marker. A FFBadge legend names each state in text so
// nothing rides on color alone. Tapping a day calls onLog(date).
struct CalendarView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    var onLog: (Date) -> Void

    @State private var month = Date()
    private let cal = Calendar.current

    private var p: CyclePrediction { store.prediction() }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.s4) {
                SampleBanner()
                FFCard {
                    VStack(spacing: FFSpace.s3) {
                        monthHeader
                        weekdayRow
                        grid
                    }
                }
                legend
            }
            .padding(.horizontal, FFSpace.s4)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s5)
        }
    }

    // MARK: month pager

    private var monthHeader: some View {
        HStack {
            navButton("chevron.left", "Previous month") { shift(-1) }
            Spacer()
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(ffDisplay(FFType.lg, weight: .semibold))
                .foregroundStyle(theme.color(.deep))
            Spacer()
            navButton("chevron.right", "Next month") { shift(1) }
        }
    }

    private func navButton(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: FFType.md, weight: .semibold))
                .foregroundStyle(theme.color(.primaryStrong))
                .frame(width: FFSpace.tapMin, height: FFSpace.tapMin)
                .background(theme.color(.surfaceSoft), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                Text(s)
                    .font(ffBody(FFType.xs2, weight: .bold))
                    .foregroundStyle(theme.color(.muted))
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    // Weekday initials rotated to the calendar's firstWeekday (Su-first in en_US).
    private var weekdaySymbols: [String] {
        let s = DateFormatter().veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let shift = cal.firstWeekday - 1
        return Array(s[shift...] + s[..<shift])
    }

    // MARK: grid

    private var grid: some View {
        let days = monthGrid()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day { dayCell(day) }
                else { Color.clear.frame(width: FFSpace.tapMin, height: FFSpace.tapMin) }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let st = state(for: date)
        return DayCell(
            day: cal.component(.day, from: date),
            isToday: cal.isDateInToday(date),
            isPeriod: st.isPeriod,
            isPredicted: st.isPredicted,
            isFertile: st.isFertile,
            isOvulation: st.isOvulation,
            flow: st.flow,
            stretchDone: store.log(for: date)?.stretchDone ?? false,
            action: { onLog(date) }
        )
    }

    // MARK: state per day

    private struct DayState {
        var isPeriod = false, isPredicted = false, isFertile = false, isOvulation = false
        var flow: Flow? = nil
    }

    // Logged bleeding wins; then ovulation, fertile window, then a predicted
    // upcoming period. Mutually exclusive so a day reads as exactly one state.
    private func state(for date: Date) -> DayState {
        let d0 = cal.startOfDay(for: date)
        if let log = store.log(for: date), log.isPeriod {
            return DayState(isPeriod: true, flow: log.flow)
        }
        if let ov = p.ovulationDate, cal.isDate(d0, inSameDayAs: ov) {
            return DayState(isOvulation: true)
        }
        if let s = p.fertileStart, let e = p.fertileEnd,
           d0 >= cal.startOfDay(for: s), d0 <= cal.startOfDay(for: e) {
            return DayState(isFertile: true)
        }
        if isPredictedPeriod(d0) {
            return DayState(isPredicted: true)
        }
        return DayState()
    }

    // Predicted period: next start .. next start + avg period length − 1.
    private func isPredictedPeriod(_ d0: Date) -> Bool {
        guard let next = p.nextPeriodStart else { return false }
        let start = cal.startOfDay(for: next)
        guard let end = cal.date(byAdding: .day, value: p.averagePeriodLength - 1, to: start) else { return false }
        return d0 >= start && d0 <= end
    }

    // MARK: legend

    // Every state has its own SHAPE, not just a color, so the legend teaches
    // the glyphs: drop = period, diamond = fertile, star = ovulation,
    // dashed ring = predicted, leaf = stretched.
    private var legend: some View {
        FFCard(variant: .soft) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack(spacing: FFSpace.s4) {
                    legendGlyph("drop.fill", .phaseMenstrual, "Period")
                    legendGlyph("diamond.fill", .phaseFertile, "Fertile")
                    legendGlyph("star.fill", .phaseOvulation, "Ovulation")
                    Spacer(minLength: 0)
                }
                HStack(spacing: FFSpace.s4) {
                    HStack(spacing: 5) {
                        Circle()
                            .strokeBorder(theme.color(.phaseMenstrual),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                            .frame(width: 11, height: 11)
                        legendText("Predicted")
                    }
                    legendGlyph("leaf.fill", .phaseLuteal, "Stretched")
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func legendGlyph(_ icon: String, _ tint: Tok, _ label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(theme.color(tint))
            legendText(label)
        }
    }

    private func legendText(_ t: String) -> some View {
        Text(t).font(ffBody(FFType.xs, weight: .medium)).foregroundStyle(theme.color(.text))
    }

    // MARK: grid math

    private func shift(_ by: Int) {
        if let m = cal.date(byAdding: .month, value: by, to: month) {
            withAnimation(FFMotion.fast) { month = m }
        }
    }

    /// nil-padded 7-col grid for the visible month (leading blanks before day 1).
    private func monthGrid() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: month),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }
        let leading = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range { cells.append(cal.date(byAdding: .day, value: d - 1, to: first)) }
        return cells
    }
}
