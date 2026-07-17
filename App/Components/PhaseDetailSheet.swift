import SwiftUI

// The insight sheet that opens when you tap the CycleRing on a given day: what's
// happening hormonally, what's common right now, and a few tips — phase-colored.
struct PhaseDetailSheet: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let phase: CyclePhase
    let day: Int
    let cycleLength: Int
    var isToday: Bool = false
    var onJumpToToday: (() -> Void)? = nil

    private var report: PhaseReport {
        PhaseResearch.report(for: phase, day: day, cycleLength: cycleLength)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                section("What's happening", content.whatsHappening)
                commonSection
                reportSection
                tipsSection
                if phase == .fertile || phase == .ovulation {
                    Text("Fertile-window estimates aren't a birth-control method.")
                        .font(ffBody(FFType.xs))
                        .foregroundStyle(theme.color(.muted))
                }
                if !isToday, let jump = onJumpToToday {
                    FFButton("Back to today", style: .soft, icon: "arrow.uturn.backward") {
                        jump(); dismiss()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(FFSpace.s5)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.color(.bg))
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cycle day \(day) of \(cycleLength)\(isToday ? " · today" : "")")
                .font(ffBody(FFType.sm, weight: .semibold))
                .foregroundStyle(theme.color(.muted))
            HStack(spacing: 10) {
                Circle().fill(theme.color(CycleRing.tint(phase))).frame(width: 14, height: 14)
                Text(phase.label)
                    .font(ffDisplay(FFType.xl2, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
            }
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                .accessibilityAddTraits(.isHeader)
            Text(body).font(ffBody(FFType.base)).foregroundStyle(theme.color(.text)).lineSpacing(3)
        }
    }

    private var commonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Common right now").font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                .accessibilityAddTraits(.isHeader)
            FlowLayout(spacing: 8) {
                ForEach(content.common, id: \.self) { item in
                    Text(item)
                        .font(ffBody(FFType.xs, weight: .medium))
                        .foregroundStyle(theme.color(.deep))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(theme.color(CycleRing.softTint(phase)), in: Capsule())
                }
            }
        }
    }

    // The short report — the research behind this stretch of her cycle, in a
    // phase-tinted card so it reads as the sheet's centerpiece.
    private var reportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 12, weight: .semibold))
                Text("A short report · \(report.title)")
                    .font(ffBody(FFType.md, weight: .semibold))
            }
            .foregroundStyle(theme.color(.deep))
            .accessibilityAddTraits(.isHeader)
            Text(report.body)
                .font(ffBody(FFType.base))
                .foregroundStyle(theme.color(.text))
                .lineSpacing(4)
            Text(report.evidenceNote)
                .font(ffBody(FFType.xs))
                .foregroundStyle(theme.color(.muted))
                .lineSpacing(2)
        }
        .padding(FFSpace.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.color(CycleRing.softTint(phase)),
                    in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
        // A phase-colored hairline keeps the report reading as the sheet's
        // centerpiece — distinct from the same-tinted chips above it.
        .overlay(
            RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                .strokeBorder(theme.color(CycleRing.tint(phase)).opacity(0.35), lineWidth: 1)
        )
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips").font(ffBody(FFType.md, weight: .semibold)).foregroundStyle(theme.color(.deep))
                .accessibilityAddTraits(.isHeader)
            ForEach(report.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(theme.color(CycleRing.tint(phase)))
                        .frame(width: 6, height: 6).padding(.top, 6)
                    Text(tip).font(ffBody(FFType.base)).foregroundStyle(theme.color(.text))
                }
            }
        }
    }

    // Plain-language, non-alarmist phase content. (Tips now come from the
    // research reports in PhaseResearch — only the intro + chips live here.)
    private var content: (whatsHappening: String, common: [String]) {
        switch phase {
        case .menstrual:
            return ("Your period. The uterine lining sheds while estrogen and progesterone sit at their lowest.",
                    ["Cramps", "Fatigue", "Low back ache", "Low mood", "Headache"])
        case .follicular:
            return ("Your period is over and estrogen is climbing as a new egg matures. Energy and mood usually lift.",
                    ["Rising energy", "Brighter mood", "Clearer skin", "Motivation"])
        case .fertile:
            return ("Your fertile window. Estrogen peaks and cervical mucus turns clear and stretchy. These are the days conception is most likely.",
                    ["Higher libido", "Egg-white discharge", "More energy", "Sharper focus"])
        case .ovulation:
            return ("An egg is released. Some feel a brief one-sided twinge; your basal temperature rises just after.",
                    ["Peak libido", "One-sided twinge", "Temperature rise", "Confidence"])
        case .luteal:
            return ("After ovulation, before your period. Progesterone rises then falls: the PMS window for many.",
                    ["Bloating", "Cravings", "Tender breasts", "Mood shifts", "Cramps building"])
        }
    }
}
