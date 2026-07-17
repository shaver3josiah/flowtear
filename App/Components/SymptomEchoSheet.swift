import SwiftUI

/// A symptom she just tapped, paired with the last day she felt it and the
/// day she's logging (which may be a back-filled past day, not today).
struct SymptomEcho: Identifiable {
    let symptom: Symptom
    let lastDate: Date
    let loggingDate: Date
    var id: String { symptom.rawValue }
}

// SymptomEchoSheet — the history tour behind the little clock button next to
// a symptom she's felt before. The headline answers the one essential
// question ("when was the last time?") in a single calm line; everything
// deeper waits behind tappable questions that expand in place, so she reads
// exactly as much as she wants and never meets a wall of text.
struct SymptomEchoSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let echo: SymptomEcho
    /// Jump to the calendar focused on this symptom's days (caller wires tabs).
    var onShowCalendar: (Symptom, Date) -> Void = { _, _ in }

    @State private var open: Set<String> = []

    private var daysAgo: Int {
        Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: echo.lastDate),
            to: Calendar.current.startOfDay(for: echo.loggingDate)).day ?? 0
    }

    private var loggingToday: Bool {
        Calendar.current.isDateInToday(echo.loggingDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpace.s4) {
                header

                Text("Tap any question below to open it up.")
                    .font(ffBody(FFType.xs))
                    .foregroundStyle(theme.color(.muted))

                VStack(alignment: .leading, spacing: FFSpace.s3) {
                    tourRow("cycle", icon: "arrow.triangle.2.circlepath",
                            title: "Where in your cycle, then and now") {
                        phaseCompare
                    }
                    if let log = store.log(for: echo.lastDate) {
                        tourRow("day", icon: "list.bullet.rectangle.portrait",
                                title: "What that whole day looked like") {
                            DayLogSummary(log: log)
                        }
                    }
                    tourRow("times", icon: "calendar",
                            title: "How often it visits") {
                        timesContent
                    }
                }

                FFButton("See those days on the calendar", style: .primary, icon: "calendar") {
                    dismiss()
                    onShowCalendar(echo.symptom, echo.lastDate)
                }
                FFButton("Keep logging", style: .ghost, size: .sm) { dismiss() }
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: header — the one-glance answer, nothing else

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.color(.primaryStrong))
            VStack(alignment: .leading, spacing: 2) {
                Text(echo.symptom.label)
                    .font(ffDisplay(FFType.lg, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                Text(lastFeltLine)
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
            }
            Spacer()
            FFIconButton("xmark") { dismiss() }
        }
    }

    private var lastFeltLine: String {
        let when = echo.lastDate.formatted(.dateTime.month(.wide).day())
        if daysAgo == 1 { return loggingToday ? "Last felt yesterday, \(when)" : "Last felt \(when), the day before" }
        return loggingToday ? "Last felt \(when), \(daysAgo) days ago" : "Last felt \(when), \(daysAgo) days earlier"
    }

    // MARK: the tour rows — a question that expands in place

    private func tourRow(_ id: String, icon: String, title: String,
                         @ViewBuilder content: () -> some View) -> some View {
        let isOpen = open.contains(id)
        return VStack(alignment: .leading, spacing: FFSpace.s2) {
            Button {
                withAnimation(reduceMotion ? nil : FFMotion.spring) {
                    if isOpen { open.remove(id) } else { open.insert(id) }
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(theme.color(.surfaceSoft))
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.color(.primaryStrong))
                    }
                    .frame(width: 30, height: 30)
                    Text(title)
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.text))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
                .frame(minHeight: FFSpace.tapMin)
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOpen ? "Collapses this answer" : "Expands this answer")
            .accessibilityAddTraits(isOpen ? .isSelected : [])

            if isOpen {
                content()
                    .padding(.leading, 40)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }

            Rectangle().fill(theme.color(.line)).frame(height: 1)
        }
    }

    // Then vs the day she's logging: the same phase twice is a pattern worth
    // seeing. Both sides are judged AT their own dates, so back-filling a past
    // day compares the right two days (never today by accident).
    private var phaseCompare: some View {
        let then = store.phaseSnapshot(at: echo.lastDate)
        let now = store.phaseSnapshot(at: echo.loggingDate)
        return VStack(alignment: .leading, spacing: 6) {
            if let phase = then.phase, let day = then.day {
                HStack(spacing: 8) {
                    Circle().fill(theme.color(CycleRing.tint(phase))).frame(width: 9, height: 9)
                    Text("Then: \(phase.label) phase, cycle day \(day)")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.text))
                }
            }
            if let phase = now.phase, let day = now.day {
                HStack(spacing: 8) {
                    Circle().fill(theme.color(CycleRing.tint(phase))).frame(width: 9, height: 9)
                    Text("\(loggingToday ? "Now" : "This day"): \(phase.label) phase, cycle day \(day)")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.text))
                }
                if let thenPhase = then.phase {
                    Text(thenPhase == phase
                         ? "Same part of your cycle both times. Bodies love a rhythm."
                         : "A different part of your cycle this time.")
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                }
            }
        }
    }

    // Every earlier day with this symptom, told in one gentle sentence.
    private var timesContent: some View {
        let cutoff = Calendar.current.startOfDay(for: echo.loggingDate)
        let earlier = store.daysFelt(echo.symptom).filter { $0 < cutoff }
        return Text(timesLine(earlier))
            .font(ffBody(FFType.sm))
            .foregroundStyle(theme.color(.text))
            .lineSpacing(2)
    }

    private func timesLine(_ earlier: [Date]) -> String {
        guard let first = earlier.first else {
            return "This is the first time you've logged it."
        }
        let firstWhen = first.formatted(.dateTime.month(.wide).day())
        if earlier.count == 1 {
            return "Once before now, on \(firstWhen)."
        }
        return "\(earlier.count) times before now. The first was \(firstWhen)."
    }
}

// DayLogSummary — one day's whole log as compact readable rows. Shared by the
// symptom echo sheet and the calendar's history banner.
struct DayLogSummary: View {
    @Environment(Theme.self) private var theme
    let log: DayLog

    var body: some View {
        VStack(alignment: .leading, spacing: FFSpace.s2) {
            if let flow = log.flow {
                row("drop.fill", .phaseMenstrual, "\(flow.label) flow")
            }
            if let d = log.discharge {
                row("humidity.fill", .phaseFertile, "\(d.label) discharge")
            }
            if let c = log.temperatureC {
                row("thermometer.medium", .phaseOvulation,
                    String(format: "%.2f° in the morning", c * 9 / 5 + 32))
            }
            if !log.moods.isEmpty {
                row("face.smiling", .phaseLuteal,
                    log.moods.map(\.label).sorted().joined(separator: ", "))
            }
            if !log.symptoms.isEmpty {
                row("bolt.heart", .primaryStrong,
                    log.symptoms.map(\.label).sorted().joined(separator: ", "))
            }
            if !log.note.isEmpty {
                row("text.quote", .deep, "\u{201C}\(log.note)\u{201D}")
            }
            if log.stretchDone == true {
                row("leaf.fill", .phaseLuteal, "Stretched that day")
            }
        }
        .padding(FFSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
            .strokeBorder(theme.color(.line), lineWidth: 1))
    }

    private func row(_ icon: String, _ tint: Tok, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.color(tint))
                .frame(width: 20)
                .padding(.top, 1)
            Text(text)
                .font(ffBody(FFType.sm))
                .foregroundStyle(theme.color(.text))
                .lineSpacing(2)
        }
    }
}
