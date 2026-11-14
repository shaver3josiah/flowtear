import SwiftUI

// CalendarView — the month calendar (DS Flowtear/calendar-screen). One FFCard
// holds the month pager (chevrons, swipes, a back-to-today chip), weekday row,
// and a 7-col grid of DayCell: each day carries its own phase-soft wash, period
// fill, dashed predicted ring, fertile band, and ovulation marker. Predictions
// are projected a full year ahead; upcoming fertile days shimmer. A legend
// names each state in text so nothing rides on color alone. Tapping a day
// calls onLog(date).
struct CalendarView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    var onLog: (Date) -> Void
    /// When set, the calendar opens on this symptom's history: marked days,
    /// an explaining banner, and prev/next stepping between occurrences.
    @Binding var focus: SymptomFocus?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var month = Date()
    @State private var focusedOccurrence: Date? = nil
    /// A tapped day that hasn't happened yet: we show what's predicted for it
    /// rather than an editable log, so a future day can never be written to.
    @State private var peek: PeekDay? = nil
    /// Which way the month just moved (+1 forward, −1 back) — shapes the
    /// grid's slide-in so paging feels like turning, not swapping.
    @State private var monthDirection = 1
    /// Counts her own pager actions; drives the paging haptic.
    @State private var pagerMoves = 0
    private let cal = Calendar.current

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
                        if !isOnThisMonth { todayChip }
                        weekdayRow
                        grid
                            .id(monthKey)
                            .transition(.asymmetric(
                                insertion: .offset(x: CGFloat(monthDirection) * 28).combined(with: .opacity),
                                removal: .opacity))
                    }
                    .contentShape(Rectangle())
                    // simultaneous, so the page's vertical scroll keeps first
                    // claim on up-and-down drags (onEnded filters direction).
                    .simultaneousGesture(monthSwipe)
                }
                // Keyed to deliberate pager taps (chevrons, swipes, the chip),
                // never the programmatic jump a symptom-history landing makes.
                .sensoryFeedback(.selection, trigger: pagerMoves)
                legend
            }
            .padding(.horizontal, FFSpace.s4)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.s5)
        }
        .onAppear { adoptFocus() }
        .onChange(of: focus?.anchor) { _, _ in adoptFocus() }
        .sheet(item: $peek) { p in
            PhaseDetailSheet(phase: p.phase, day: p.day,
                             cycleLength: store.prediction().averageCycleLength,
                             dateLabel: p.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Land on the anchor occurrence and scroll the month to it.
    private func adoptFocus() {
        guard let f = focus else { return }
        focusedOccurrence = cal.startOfDay(for: f.anchor)
        go(to: f.anchor)
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
        withAnimation(FFMotion.fast) { focusedOccurrence = days[next] }
        go(to: days[next])
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
        .buttonStyle(FFPressButtonStyle(scale: 0.92))
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
        // One projection pass per render: every predicted period and fertile
        // window for the year ahead, instead of re-deriving per day cell.
        let windows = store.projectedCycles()
        let today0 = cal.startOfDay(for: Date())
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day { dayCell(day, windows: windows, today0: today0) }
                else { Color.clear.frame(width: FFSpace.tapMin, height: FFSpace.tapMin) }
            }
        }
    }

    private func dayCell(_ date: Date, windows: [ProjectedCycle], today0: Date) -> some View {
        let st = state(for: date, windows: windows)
        let isOccurrence = focus != nil && occurrences.contains { cal.isDate($0, inSameDayAs: date) }
        let isSelectedOccurrence = isOccurrence
            && focusedOccurrence.map { cal.isDate($0, inSameDayAs: date) } == true
        // Upcoming fertile days carry the shimmer; the gleam is staggered by
        // weekday column so it travels along the window like light on water.
        let shimmers = (st.isFertile || st.isOvulation) && date >= today0
        return DayCell(
            day: cal.component(.day, from: date),
            isToday: cal.isDateInToday(date),
            isPeriod: st.isPeriod,
            isPredicted: st.isPredicted,
            isFertile: st.isFertile,
            isOvulation: st.isOvulation,
            flow: st.flow,
            stretchDone: store.log(for: date)?.stretchDone ?? false,
            shimmers: shimmers,
            shimmerDelay: Double(column(for: date)) * 0.14,
            action: {
                let d0 = cal.startOfDay(for: date)
                // In history mode a marked day selects itself in the banner.
                if isOccurrence {
                    withAnimation(FFMotion.fast) { focusedOccurrence = d0 }
                } else if d0 > today0 {
                    // A day that hasn't happened has nothing to log. Show what
                    // the prediction says about it instead; with no history
                    // yet there is nothing to say, so the tap stays quiet.
                    let snap = store.phaseSnapshot(at: date)
                    if let phase = snap.phase, let day = snap.day {
                        peek = PeekDay(date: d0, phase: phase, day: day)
                    }
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
        .accessibilityHint(isOccurrence ? "Selects this day in the history banner"
                           : (cal.startOfDay(for: date) > today0
                              ? "Shows what's predicted for this day"
                              : "Opens this day's log"))
        .accessibilityAddTraits(isSelectedOccurrence ? .isSelected : [])
    }

    // MARK: state per day

    private struct DayState {
        var isPeriod = false, isPredicted = false, isFertile = false, isOvulation = false
        var flow: Flow? = nil
    }

    // Logged bleeding wins; then ovulation, fertile window, then a predicted
    // period, across every projected cycle in the year ahead. Mutually
    // exclusive so a day reads as exactly one state.
    private func state(for date: Date, windows: [ProjectedCycle]) -> DayState {
        let d0 = cal.startOfDay(for: date)
        if let log = store.log(for: date), log.isPeriod {
            return DayState(isPeriod: true, flow: log.flow)
        }
        if windows.contains(where: { cal.isDate(d0, inSameDayAs: $0.ovulation) }) {
            return DayState(isOvulation: true)
        }
        if windows.contains(where: { d0 >= $0.fertileStart && d0 <= $0.fertileEnd }) {
            return DayState(isFertile: true)
        }
        if windows.contains(where: { d0 >= $0.periodStart && d0 <= $0.periodEnd }) {
            return DayState(isPredicted: true)
        }
        return DayState()
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
                Text("Fertile days shimmer a whole year ahead, projected from your average cycle. The further out, the softer the guess.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))
                    .lineSpacing(2)
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
        guard let m = cal.date(byAdding: .month, value: by, to: month) else { return }
        pagerMoves += 1
        go(to: m)
    }

    /// Every month move funnels through here so the slide direction and the
    /// animation stay consistent (chevrons, swipes, the today chip, and
    /// symptom-history steps all land the same way). Reduce Motion swaps the
    /// slide for an instant change.
    private func go(to target: Date) {
        monthDirection = target >= month ? 1 : -1
        withAnimation(reduceMotion ? nil : FFMotion.signature) { month = target }
    }

    private var isOnThisMonth: Bool {
        cal.isDate(month, equalTo: Date(), toGranularity: .month)
    }

    /// Stable per-month identity for the grid transition and the haptic trigger.
    private var monthKey: Int {
        cal.component(.year, from: month) * 100 + cal.component(.month, from: month)
    }

    /// "next month" / "4 months ahead" / "2 months back" for the today chip.
    private var monthDistance: String {
        let now = cal.dateComponents([.year, .month], from: Date())
        let then = cal.dateComponents([.year, .month], from: month)
        let m = ((then.year ?? 0) - (now.year ?? 0)) * 12 + (then.month ?? 0) - (now.month ?? 0)
        switch m {
        case 1: return "next month"
        case -1: return "last month"
        case let x where x > 1: return "\(x) months ahead"
        case let x where x < -1: return "\(-x) months back"
        default: return ""
        }
    }

    // One tap home after wandering the year ahead.
    private var todayChip: some View {
        Button {
            pagerMoves += 1
            go(to: Date())
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.color(.primaryStrong))
                Text("Back to today")
                    .font(ffBody(FFType.xs, weight: .bold))
                    .foregroundStyle(theme.color(.primaryStrong))
                if !monthDistance.isEmpty {
                    Text("· \(monthDistance)")
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(theme.color(.surfaceSoft), in: Capsule())
            .frame(minHeight: 32)
        }
        .buttonStyle(FFPressButtonStyle())
        .transition(.ffViewIn)
        .accessibilityLabel("Back to today. Viewing \(monthDistance).")
    }

    /// A sideways swipe pages the month; vertical drags stay with the scroll.
    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { v in
                guard abs(v.translation.width) > abs(v.translation.height),
                      abs(v.translation.width) > 40 else { return }
                shift(v.translation.width < 0 ? 1 : -1)
            }
    }

    /// 0-based grid column (weekday rotated to the calendar's firstWeekday).
    private func column(for date: Date) -> Int {
        (cal.component(.weekday, from: date) - cal.firstWeekday + 7) % 7
    }

    /// nil-padded 7-col grid for the visible month (leading blanks before day 1).
    private func monthGrid() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: month),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: month)) else { return [] }
        var cells: [Date?] = Array(repeating: nil, count: column(for: first))
        for d in range { cells.append(cal.date(byAdding: .day, value: d - 1, to: first)) }
        return cells
    }
}

/// A future day the calendar is showing a prediction for, not a log.
private struct PeekDay: Identifiable {
    let date: Date
    let phase: CyclePhase
    let day: Int
    var id: Date { date }
}

/// A calendar deep-link: show one symptom's whole history, opened on `anchor`.
struct SymptomFocus: Equatable {
    let symptom: Symptom
    let anchor: Date
}
