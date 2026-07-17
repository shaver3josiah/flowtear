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
    /// When set, the calendar opens on this symptom's history: marked days,
    /// an explaining banner, and prev/next stepping between occurrences.
    @Binding var focus: SymptomFocus?

    @State private var month = Date()
    @State private var focusedOccurrence: Date? = nil
    private let cal = Calendar.current

    private var p: CyclePrediction { store.prediction() }

    /// Every day she's felt the focused symptom, oldest to newest.
    private var occurrences: [Date] {
        guard let f = focus else { return [] }
        return store.daysFelt(f.symptom)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.s4) {
                SampleBanner()
                if focus != nil { focusBanner }
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
        .onAppear { adoptFocus() }
        .onChange(of: focus?.anchor) { _, _ in adoptFocus() }
    }

    /// Land on the anchor occurrence and scroll the month to it.
    private func adoptFocus() {
        guard let f = focus else { return }
        focusedOccurrence = cal.startOfDay(for: f.anchor)
        withAnimation(FFMotion.fast) { month = f.anchor }
    }

    // MARK: symptom history banner

    // Explains what the marks mean and steps day to day through the history.
    private var focusBanner: some View {
        let days = occurrences
        let selected = focusedOccurrence ?? days.last
        let idx = selected.flatMap { s in days.firstIndex { cal.isDate($0, inSameDayAs: s) } }
        return FFCard(variant: .accent) {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.heart")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.color(.primaryStrong))
                    Text("\(focus?.symptom.label ?? "") days")
                        .font(ffBody(FFType.md, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                    Spacer()
                    FFIconButton("xmark") {
                        withAnimation(FFMotion.fast) { focus = nil; focusedOccurrence = nil }
                    }
                    .accessibilityLabel("Close symptom history")
                }
                Text(days.count == 1
                     ? "One day is marked below with a ring."
                     : "\(days.count) days are marked below with rings. Step through them, or tap any marked day.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))

                if let sel = selected {
                    HStack(spacing: FFSpace.s2) {
                        navButton("chevron.left", "Earlier day") { step(-1, in: days) }
                            .opacity(idx == 0 ? 0.35 : 1)
                            .disabled(idx == 0)
                        Spacer(minLength: 0)
                        VStack(spacing: 1) {
                            Text(sel.formatted(.dateTime.month(.wide).day().year()))
                                .font(ffBody(FFType.sm, weight: .bold))
                                .foregroundStyle(theme.color(.deep))
                            if let phase = store.phaseSnapshot(at: sel).phase,
                               let day = store.phaseSnapshot(at: sel).day {
                                Text("\(phase.label) phase, cycle day \(day)")
                                    .font(ffBody(FFType.xs))
                                    .foregroundStyle(theme.color(.muted))
                            }
                        }
                        Spacer(minLength: 0)
                        navButton("chevron.right", "Later day") { step(1, in: days) }
                            .opacity(idx == days.count - 1 ? 0.35 : 1)
                            .disabled(idx == days.count - 1)
                    }

                    if let log = store.log(for: sel) {
                        DayLogSummary(log: log)
                    }
                    FFButton("Open this day's log", style: .soft, size: .sm, icon: "square.and.pencil") {
                        onLog(sel)
                    }
                }
            }
        }
    }

    private func step(_ by: Int, in days: [Date]) {
        guard let sel = focusedOccurrence ?? days.last,
              let idx = days.firstIndex(where: { cal.isDate($0, inSameDayAs: sel) }) else { return }
        let next = idx + by
        guard days.indices.contains(next) else { return }
        withAnimation(FFMotion.fast) {
            focusedOccurrence = days[next]
            month = days[next]
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
        let isOccurrence = focus != nil && occurrences.contains { cal.isDate($0, inSameDayAs: date) }
        let isSelectedOccurrence = isOccurrence
            && focusedOccurrence.map { cal.isDate($0, inSameDayAs: date) } == true
        return DayCell(
            day: cal.component(.day, from: date),
            isToday: cal.isDateInToday(date),
            isPeriod: st.isPeriod,
            isPredicted: st.isPredicted,
            isFertile: st.isFertile,
            isOvulation: st.isOvulation,
            flow: st.flow,
            stretchDone: store.log(for: date)?.stretchDone ?? false,
            action: {
                // In history mode a marked day selects itself in the banner;
                // everything else still opens the day's log as always.
                if isOccurrence {
                    withAnimation(FFMotion.fast) { focusedOccurrence = cal.startOfDay(for: date) }
                } else {
                    onLog(date)
                }
            }
        )
        // Rings mark the focused symptom's days; the selected one is bolder.
        // Gold on dark, deep rose on light: the mark must read on white cards
        // and on the pale period wash, not just on near-black.
        .overlay {
            if isOccurrence {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(theme.isDarkMode ? theme.color(.flowerCenter)
                                                   : theme.color(.primaryStrong),
                                  lineWidth: isSelectedOccurrence ? 2.5 : 1.5)
                    .allowsHitTesting(false)
            }
        }
        // VoiceOver hears what the ring shows: which days are marked, which is
        // selected, and that tapping now selects instead of opening the log.
        .accessibilityValue(isOccurrence ? "\(focus?.symptom.label ?? "symptom") day" : "")
        .accessibilityHint(isOccurrence ? "Selects this day in the history banner" : "")
        .accessibilityAddTraits(isSelectedOccurrence ? .isSelected : [])
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

/// A calendar deep-link: show one symptom's whole history, opened on `anchor`.
struct SymptomFocus: Equatable {
    let symptom: Symptom
    let anchor: Date
}
