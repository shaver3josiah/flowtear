import SwiftUI

/// A symptom she just tapped, paired with the last day she felt it and the
/// day she's logging (which may be a back-filled past day, not today).
struct SymptomEcho: Identifiable {
    let symptom: Symptom
    let lastDate: Date
    let loggingDate: Date
    var id: String { symptom.rawValue }
}

// SymptomEchoSheet — the little history card that appears when she logs a
// symptom she's felt before. It answers three questions in one glance: when
// was the last time, what did that whole day look like, and where in her
// cycle was she then compared to now. One tap more shows those days on the
// calendar, annotated.
struct SymptomEchoSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let echo: SymptomEcho
    /// Jump to the calendar focused on this symptom's days (caller wires tabs).
    var onShowCalendar: (Symptom, Date) -> Void = { _, _ in }

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
                HStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.color(.primaryStrong))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(echo.symptom.label), last time")
                            .font(ffDisplay(FFType.lg, weight: .bold))
                            .foregroundStyle(theme.color(.deep))
                        Text(lastFeltLine)
                            .font(ffBody(FFType.sm))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer()
                    FFIconButton("xmark") { dismiss() }
                }

                phaseCompareCard

                if let log = store.log(for: echo.lastDate) {
                    VStack(alignment: .leading, spacing: FFSpace.s2) {
                        Text("THAT WHOLE DAY")
                            .font(ffBody(FFType.xs2, weight: .bold)).tracking(0.8)
                            .foregroundStyle(theme.color(.muted))
                        DayLogSummary(log: log)
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

    private var lastFeltLine: String {
        let when = echo.lastDate.formatted(.dateTime.month(.wide).day())
        if daysAgo == 1 { return loggingToday ? "Yesterday, \(when)" : "\(when), the day before" }
        return loggingToday ? "\(when), \(daysAgo) days ago" : "\(when), \(daysAgo) days earlier"
    }

    // Then vs the day she's logging: the same phase twice is a pattern worth
    // seeing. Both sides are judged AT their own dates, so back-filling a past
    // day compares the right two days (never today by accident).
    private var phaseCompareCard: some View {
        let then = store.phaseSnapshot(at: echo.lastDate)
        let now = store.phaseSnapshot(at: echo.loggingDate)
        return FFCard(variant: .soft) {
            VStack(alignment: .leading, spacing: 6) {
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
