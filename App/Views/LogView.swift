import SwiftUI

// LogView — the daily log, redesigned as clustered, color-coded sections in the
// iOS inset-group manner with an old-money finish: serif headers, hairlines, a
// gold-touched at-a-glance row, and gentle spring motion everywhere. Each
// cluster carries one hue family so the eye groups it instantly:
//   Flow rose · Discharge gold · Temperature amber · Mood lavender ·
//   Symptoms brand rose · Note ink.
// Discrete taps autosave; the note saves on focus loss; temperature saves when
// the slider settles.
struct LogView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var date: Date

    @State private var draft = DayLog(dateKey: "")
    @State private var showToast = false
    @State private var toastToken = 0
    @FocusState private var noteFocused: Bool

    private let cal = Calendar.current
    private var isToday: Bool { cal.isDateInToday(date) }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                SampleBanner()
                header
                glanceRow

                LogSection(icon: "drop.fill", title: "Flow",
                           tint: .phaseMenstrual, softTint: .phaseMenstrualSoft,
                           value: draft.flow?.label) {
                    FFPickerSlider(
                        title: "", options: Flow.allCases, label: { $0.label },
                        selection: Binding(get: { draft.flow },
                                           set: { draft.flow = $0; save() }),
                        tint: .phaseMenstrual
                    )
                }

                LogSection(icon: "humidity.fill", title: "Discharge",
                           tint: .phaseFertile, softTint: .phaseFertileSoft,
                           value: draft.discharge?.label) {
                    FFPickerSlider(
                        title: "", options: Discharge.allCases, label: { $0.label },
                        selection: Binding(get: { draft.discharge },
                                           set: { draft.discharge = $0; save() }),
                        tint: .phaseFertile
                    )
                }

                LogSection(icon: "thermometer.medium", title: "Temperature",
                           tint: .phaseOvulation, softTint: .phaseOvulationSoft,
                           value: tempF.map { String(format: "%.2f°", $0) }) {
                    temperatureContent
                }

                LogSection(icon: "face.smiling", title: "Mood",
                           tint: .phaseLuteal, softTint: .phaseLutealSoft,
                           value: countText(draft.moods.count)) {
                    FlowLayout(spacing: FFSpace.inline) {
                        ForEach(Mood.allCases) { mood in
                            FFChip(mood.label, selected: draft.moods.contains(mood), tint: .phaseLuteal) {
                                draft.moods.formSymmetricDifference([mood])
                                save()
                            }
                        }
                    }
                }

                LogSection(icon: "bolt.heart", title: "Symptoms",
                           tint: .primaryStrong, softTint: .surfaceSoft,
                           value: countText(draft.symptoms.count)) {
                    FlowLayout(spacing: FFSpace.inline) {
                        ForEach(Symptom.allCases) { symptom in
                            SymptomChip(symptom, selected: draft.symptoms.contains(symptom)) {
                                draft.symptoms.formSymmetricDifference([symptom])
                                save()
                            }
                        }
                    }
                }

                LogSection(icon: "text.quote", title: "Note",
                           tint: .deep, softTint: .surface2,
                           value: draft.note.isEmpty ? nil : "Written") {
                    TextField("Anything worth remembering…", text: $draft.note, axis: .vertical)
                        .font(ffBody(FFType.md))
                        .foregroundStyle(theme.color(.text))
                        .lineLimit(2...5)
                        .tint(theme.color(.primaryStrong))
                        .focused($noteFocused)
                }
                .onChange(of: noteFocused) { _, focused in
                    if !focused { save() }
                }
            }
            .padding(.horizontal, FFSpace.s4)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.section)
        }
        .overlay(alignment: .top) { toastOverlay }
        .onAppear(perform: reload)
        .onChange(of: date) { _, _ in reload() }
    }

    // MARK: header — serif date with day-stepping, iOS-native compact picker

    private var header: some View {
        HStack(spacing: FFSpace.s2) {
            FFIconButton("chevron.left") { step(-1) }
                .accessibilityLabel("Previous day")
            Spacer(minLength: 0)
            VStack(spacing: 3) {
                Text(isToday ? "Today" : date.formatted(.dateTime.weekday(.wide)))
                    .font(ffDisplay(FFType.xl, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                    .contentTransition(.opacity)
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(theme.color(.primaryStrong))
            }
            Spacer(minLength: 0)
            FFIconButton("chevron.right") { step(1) }
                .accessibilityLabel("Next day")
                .opacity(isToday ? 0.35 : 1)
                .disabled(isToday)
        }
        .animation(reduceMotion ? nil : FFMotion.signature, value: date)
    }

    private func step(_ by: Int) {
        guard let d = cal.date(byAdding: .day, value: by, to: date), d <= Date() else { return }
        date = d
    }

    // MARK: at-a-glance — one gold-hairlined row of section dots that fill in

    private var glanceRow: some View {
        HStack(spacing: 0) {
            glanceDot("drop.fill", filled: draft.flow != nil, tint: .phaseMenstrual)
            glanceDot("humidity.fill", filled: draft.discharge != nil, tint: .phaseFertile)
            glanceDot("thermometer.medium", filled: draft.temperatureC != nil, tint: .phaseOvulation)
            glanceDot("face.smiling", filled: !draft.moods.isEmpty, tint: .phaseLuteal)
            glanceDot("bolt.heart", filled: !draft.symptoms.isEmpty, tint: .primaryStrong)
            glanceDot("text.quote", filled: !draft.note.isEmpty, tint: .deep)
        }
        .padding(.vertical, FFSpace.s2)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.color(.flowerCenter).opacity(0.6)).frame(height: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Logged today: \(glanceSummary)")
    }

    private func glanceDot(_ icon: String, filled: Bool, tint: Tok) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(filled ? theme.color(tint) : theme.color(.line))
            .frame(maxWidth: .infinity)
            .scaleEffect(filled ? 1.0 : 0.85)
            .animation(reduceMotion ? nil : FFMotion.spring, value: filled)
    }

    private var glanceSummary: String {
        var parts: [String] = []
        if draft.flow != nil { parts.append("flow") }
        if draft.discharge != nil { parts.append("discharge") }
        if draft.temperatureC != nil { parts.append("temperature") }
        if !draft.moods.isEmpty { parts.append("mood") }
        if !draft.symptoms.isEmpty { parts.append("symptoms") }
        if !draft.note.isEmpty { parts.append("a note") }
        return parts.isEmpty ? "nothing yet" : parts.joined(separator: ", ")
    }

    // MARK: temperature — big serif numeral + settling slider

    private var tempF: Double? { draft.temperatureC.map { $0 * 9 / 5 + 32 } }

    @ViewBuilder private var temperatureContent: some View {
        if let f = tempF {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.2f", f))
                        .font(ffNumber(FFType.xl2, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                        .contentTransition(.numericText())
                    Text("°F")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                    Spacer()
                    Button {
                        draft.temperatureC = nil
                        save()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.color(.muted))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove temperature")
                }
                Slider(
                    value: Binding(
                        get: { tempF ?? 97.8 },
                        set: { draft.temperatureC = ($0 - 32) * 5 / 9 }
                    ),
                    in: 96.0...100.0, step: 0.05,
                    onEditingChanged: { editing in if !editing { save() } }
                )
                .tint(theme.color(.phaseOvulation))
                .accessibilityLabel("Basal temperature")
                .accessibilityValue(String(format: "%.2f degrees Fahrenheit", f))
                HStack {
                    Text("96°"); Spacer(); Text("100°")
                }
                .font(ffBody(FFType.xs2, weight: .medium))
                .foregroundStyle(theme.color(.muted))
            }
        } else {
            FFButton("Add this morning's temp", style: .soft, size: .sm, icon: "plus") {
                draft.temperatureC = (97.8 - 32) * 5 / 9
                save()
            }
        }
    }

    // MARK: state

    private func reload() {
        draft = store.log(for: date) ?? DayLog(dateKey: store.key(for: date))
    }

    private func save() {
        draft.dateKey = store.key(for: date)
        store.upsert(draft)
        flash()
    }

    private func flash() {
        toastToken += 1
        let token = toastToken
        withAnimation(reduceMotion ? nil : FFMotion.spring) { showToast = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if token == toastToken {
                withAnimation(reduceMotion ? nil : FFMotion.fast) { showToast = false }
            }
        }
    }

    private func countText(_ n: Int) -> String? {
        n == 0 ? nil : "\(n) picked"
    }

    @ViewBuilder private var toastOverlay: some View {
        if showToast {
            FFToast(message: "Logged.")
                .padding(.top, FFSpace.s2)
                .allowsHitTesting(false)
                .transition(reduceMotion
                    ? .opacity
                    : .move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - LogSection — the shared cluster chrome that keeps every section aligned

// One consistent anatomy for every cluster: a tinted icon medallion, a serif
// title, a live value readout on the trailing edge, then the content on a
// shared inset. Alignment lives here once, so sections can't drift apart.
private struct LogSection<Content: View>: View {
    @Environment(Theme.self) private var theme
    let icon: String
    let title: String
    let tint: Tok
    let softTint: Tok
    var value: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(theme.color(softTint))
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.color(tint))
                    }
                    .frame(width: 30, height: 30)
                    Text(title)
                        .font(ffDisplay(FFType.md, weight: .semibold))
                        .foregroundStyle(theme.color(.deep))
                    Spacer(minLength: 4)
                    if let value {
                        Text(value)
                            .font(ffBody(FFType.sm, weight: .bold))
                            .foregroundStyle(theme.color(tint))
                            .contentTransition(.opacity)
                            .transition(.opacity)
                    }
                }
                content()
            }
        }
        .animation(FFMotion.fast, value: value)
    }
}

// Minimal wrapping HStack (native SwiftUI Layout — no dependency). Wraps chips
// to the next line when they run out of width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: maxW == .infinity ? x : maxW, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}
