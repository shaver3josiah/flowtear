import SwiftUI

// LogView — the daily log. Clustered, color-coded sections (Flow rose ·
// Discharge gold · Temperature amber · Mood lavender · Symptoms brand rose ·
// Note ink) under a serif date header. The at-a-glance progress row stays
// PINNED while she scrolls, and the day commits with the slide-to-log flower
// at the bottom — no toast. Edits live in a draft; switching day or leaving
// the tab silently commits as a safety net, so nothing she typed is ever lost.
struct LogView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var date: Date
    var onLogged: () -> Void = {}
    var onOpenStretch: () -> Void = {}
    var onOpenCalendar: () -> Void = {}
    var onOpenInsights: () -> Void = {}
    /// Jump to the calendar focused on one symptom's history (wired by RootView).
    var onShowSymptomOnCalendar: (Symptom, Date) -> Void = { _, _ in }

    @State private var draft = DayLog(dateKey: "")
    @State private var loadedKey = ""
    @State private var showAllSet = false
    @State private var showShop = false
    @State private var symptomEcho: SymptomEcho? = nil
    @FocusState private var noteFocused: Bool

    private let cal = Calendar.current
    private var isToday: Bool { cal.isDateInToday(date) }
    private var stored: DayLog { store.logs[loadedKey] ?? DayLog(dateKey: loadedKey) }
    private var dirty: Bool { draft != stored }

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                SampleBanner()
                header

                LogSection(icon: "drop.fill", title: "Flow",
                           tint: .phaseMenstrual, softTint: .phaseMenstrualSoft,
                           value: draft.flow?.label) {
                    FFPickerSlider(
                        title: "", options: Flow.allCases, label: { $0.label },
                        selection: $draft.flow,
                        tint: .phaseMenstrual
                    )
                }

                LogSection(icon: "humidity.fill", title: "Discharge",
                           tint: .phaseFertile, softTint: .phaseFertileSoft,
                           value: draft.discharge?.label) {
                    FFPickerSlider(
                        title: "", options: Discharge.allCases, label: { $0.label },
                        selection: $draft.discharge,
                        tint: .phaseFertile
                    )
                }

                LogSection(icon: "thermometer.medium", title: "Temperature",
                           tint: .phaseOvulation, softTint: .phaseOvulationSoft,
                           value: tempValueText) {
                    temperatureContent
                }

                LogSection(icon: "face.smiling", title: "Mood",
                           tint: .phaseLuteal, softTint: .phaseLutealSoft,
                           value: countText(draft.moods.count)) {
                    FlowLayout(spacing: FFSpace.inline) {
                        ForEach(Mood.allCases) { mood in
                            FFChip(mood.label, selected: draft.moods.contains(mood),
                                   emoji: mood.emoji, tint: .phaseLuteal) {
                                draft.moods.formSymmetricDifference([mood])
                            }
                        }
                    }
                }

                LogSection(icon: "bolt.heart", title: "Symptoms",
                           tint: .primaryStrong, softTint: .surfaceSoft,
                           value: countText(draft.symptoms.count)) {
                    VStack(alignment: .leading, spacing: FFSpace.s3) {
                        ForEach(Self.symptomGroups, id: \.0) { group in
                            VStack(alignment: .leading, spacing: FFSpace.s2) {
                                Text(group.0.uppercased())
                                    .font(ffBody(FFType.xs2, weight: .bold))
                                    .tracking(0.8)
                                    .foregroundStyle(theme.color(.muted))
                                FlowLayout(spacing: FFSpace.inline) {
                                    ForEach(group.1) { symptom in
                                        let selected = draft.symptoms.contains(symptom)
                                        HStack(spacing: 6) {
                                            SymptomChip(symptom, selected: selected) {
                                                draft.symptoms.formSymmetricDifference([symptom])
                                            }
                                            // A quiet clock pops up beside a picked symptom
                                            // she's felt before. Nothing opens on its own;
                                            // the history tour waits for this tap.
                                            if selected, let last = store.lastFelt(symptom, before: date) {
                                                historyButton(symptom, last: last)
                                            }
                                        }
                                    }
                                }
                                .animation(reduceMotion ? nil : FFMotion.spring, value: draft.symptoms)
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

                // The commit gesture lives at the END of the log — she scrolls
                // down to it when she's finished, like signing at the bottom.
                SlideToLog(enabled: dirty) { commit(); showAllSet = true }
                    .padding(.top, FFSpace.s2)
            }
            .padding(.horizontal, FFSpace.s4)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.section)
        }
        // The progress row rides above the scroll — always visible.
        .safeAreaInset(edge: .top, spacing: 0) {
            glanceRow
                .padding(.horizontal, FFSpace.s4)
                .padding(.vertical, 6)
                .background(theme.color(.bg).opacity(0.97))
        }
        .onAppear(perform: reload)
        .onChange(of: date) { _, _ in
            commitIfDirty()   // draft still carries the previous day's key
            reload()
        }
        .onDisappear { commitIfDirty() }
        .overlay { if showAllSet { allSetOverlay } }
        .sheet(isPresented: $showShop) { GardenShopView() }
        .sheet(item: $symptomEcho) { echo in
            SymptomEchoSheet(echo: echo, onShowCalendar: { sym, day in
                commitIfDirty()   // her taps are saved before the tab changes
                onShowSymptomOnCalendar(sym, day)
            })
        }
    }

    // After the slide: a proud moment, then three clear places to go next.
    private var allSetOverlay: some View {
        ZStack {
            theme.color(.bg).opacity(0.96).ignoresSafeArea()
            PetalRain(count: 12)
            VStack(spacing: FFSpace.s4) {
                Spacer()
                CoachFlower(message: "You're all set, petal! Every pose you check in Stretch grows your flower garden.")
                FFButton("Grow flowers in Stretch", style: .primary, icon: "figure.cooldown") {
                    showAllSet = false; onOpenStretch()
                }
                FFButton("Calendar: your month at a glance", style: .soft, size: .sm, icon: "calendar") {
                    showAllSet = false; onOpenCalendar()
                }
                FFButton("Insights: your patterns over time", style: .soft, size: .sm, icon: "chart.bar.fill") {
                    showAllSet = false; onOpenInsights()
                }
                FFButton("Back to Today", style: .ghost, size: .sm) {
                    showAllSet = false; onLogged()
                }
                Spacer()
            }
            .padding(FFSpace.s5)
        }
        .transition(.opacity)
    }

    // MARK: header — serif date with day-stepping

    private var header: some View {
        ZStack {
            // The date stays truly centered; the controls ride the edges.
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
            HStack(spacing: FFSpace.s2) {
                FFIconButton("chevron.left") { step(-1) }
                    .accessibilityLabel("Previous day")
                Spacer(minLength: 0)
                FFIconButton("bag") { showShop = true }
                    .glitterHint("logShop")
                    .accessibilityLabel("Garden shop")
                FFIconButton("chevron.right") { step(1) }
                    .accessibilityLabel("Next day")
                    .opacity(isToday ? 0.35 : 1)
                    .disabled(isToday)
            }
        }
        .animation(reduceMotion ? nil : FFMotion.signature, value: date)
    }

    private func step(_ by: Int) {
        guard let d = cal.date(byAdding: .day, value: by, to: date), d <= Date() else { return }
        date = d
    }

    // MARK: pinned at-a-glance row

    private var glanceRow: some View {
        HStack(spacing: 0) {
            glanceDot("drop.fill", filled: draft.flow != nil, tint: .phaseMenstrual)
            glanceDot("humidity.fill", filled: draft.discharge != nil, tint: .phaseFertile)
            glanceDot("thermometer.medium",
                      filled: draft.temperatureC != nil || draft.tempSkipped == true,
                      tint: .phaseOvulation)
            glanceDot("face.smiling", filled: !draft.moods.isEmpty, tint: .phaseLuteal)
            glanceDot("bolt.heart", filled: !draft.symptoms.isEmpty, tint: .primaryStrong)
            glanceDot("text.quote", filled: !draft.note.isEmpty, tint: .deep)
        }
        .padding(.vertical, FFSpace.s1)
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
        if draft.tempSkipped == true { parts.append("temperature skipped") }
        if !draft.moods.isEmpty { parts.append("mood") }
        if !draft.symptoms.isEmpty { parts.append("symptoms") }
        if !draft.note.isEmpty { parts.append("a note") }
        return parts.isEmpty ? "nothing yet" : parts.joined(separator: ", ")
    }

    // MARK: temperature — slider ready by default; a checkbox if she skipped

    private var tempF: Double? { draft.temperatureC.map { $0 * 9 / 5 + 32 } }

    private var tempValueText: String? {
        if draft.tempSkipped == true { return "Not today" }
        return tempF.map { String(format: "%.2f°", $0) }
    }

    /// Sensible slider start: her last reading, else a typical 97.8.
    private var suggestedF: Double {
        store.recentTemperatures().last.map { $0.celsius * 9 / 5 + 32 } ?? 97.8
    }

    @ViewBuilder private var temperatureContent: some View {
        if draft.tempSkipped == true {
            checkboxRow(checked: true, label: "Didn't take it this morning") {
                draft.tempSkipped = nil
            }
        } else {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.2f", tempF ?? suggestedF))
                        .font(ffNumber(FFType.xl2, weight: .semibold))
                        .foregroundStyle(theme.color(tempF == nil ? .muted : .deep))
                        .contentTransition(.numericText())
                    Text("°F")
                        .font(ffBody(FFType.sm, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                    if tempF == nil {
                        Text("slide to set")
                            .font(ffBody(FFType.xs))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer()
                }
                Slider(
                    value: Binding(
                        get: { tempF ?? suggestedF },
                        set: { draft.temperatureC = ($0 - 32) * 5 / 9 }
                    ),
                    in: 96.0...100.0, step: 0.05
                )
                .tint(theme.color(.phaseOvulation))
                .accessibilityLabel("Basal temperature")
                .accessibilityValue(String(format: "%.2f degrees Fahrenheit", tempF ?? suggestedF))
                HStack {
                    Text("96°"); Spacer(); Text("100°")
                }
                .font(ffBody(FFType.xs2, weight: .medium))
                .foregroundStyle(theme.color(.muted))

                checkboxRow(checked: false, label: "Didn't take it this morning") {
                    draft.tempSkipped = true
                    draft.temperatureC = nil
                }
            }
        }
    }

    /// The little clock beside a selected symptom. Same 40pt height as the
    /// chips so the row stays level; opens the symptom's history tour.
    private func historyButton(_ symptom: Symptom, last: Date) -> some View {
        Button {
            symptomEcho = SymptomEcho(symptom: symptom, lastDate: last, loggingDate: date)
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.color(.primaryStrong))
                .frame(width: 40, height: 40)
                .background(theme.color(.surfaceSoft), in: Circle())
                .overlay(Circle().strokeBorder(theme.color(.line), lineWidth: 1))
        }
        .buttonStyle(FFPressButtonStyle(scale: 0.9))
        .transition(.scale.combined(with: .opacity))
        .accessibilityLabel("\(symptom.label) history")
        .accessibilityHint("Shows the last time you felt this")
    }

    private func checkboxRow(checked: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(theme.color(checked ? .phaseOvulation : .muted))
                Text(label)
                    .font(ffBody(FFType.sm, weight: .medium))
                    .foregroundStyle(theme.color(.text))
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 32)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: checked)
        .accessibilityAddTraits(checked ? .isSelected : [])
    }

    // MARK: state — draft in, slide (or safety net) out

    private func reload() {
        loadedKey = store.key(for: date)
        draft = store.log(for: date) ?? DayLog(dateKey: loadedKey)
        draft.dateKey = loadedKey
    }

    private func commit() {
        noteFocused = false
        draft.dateKey = loadedKey
        store.upsert(draft)
    }

    /// Safety net: leaving the day or the tab commits silently, so edits never
    /// vanish just because she didn't swipe.
    private func commitIfDirty() {
        guard !loadedKey.isEmpty, dirty else { return }
        commit()
    }

    private func countText(_ n: Int) -> String? {
        n == 0 ? nil : "\(n) picked"
    }

    // Symptoms clustered the way she'd think of them, not alphabetically.
    static let symptomGroups: [(String, [Symptom])] = [
        ("Aches", [.cramps, .headache, .backache]),
        ("Body", [.bloating, .tenderBreasts, .acne]),
        ("Digestion", [.nausea, .cravings, .diarrhea, .constipation]),
        ("Energy & sleep", [.fatigue, .insomnia]),
    ]
}

// Small, classy faces that help her pick — one quiet emoji per mood.
extension Mood {
    var emoji: String {
        switch self {
        case .happy:     "😊"
        case .calm:      "😌"
        case .sensitive: "🥺"
        case .sad:       "😢"
        case .irritable: "😤"
        case .anxious:   "😟"
        case .energized: "🤩"
        case .tired:     "😴"
        }
    }
}

// MARK: - LogSection — the shared cluster chrome that keeps every section aligned

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
