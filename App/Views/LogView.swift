import SwiftUI

// LogView — the daily log sheet. FlowScale for bleeding, SymptomChip grid for
// symptoms, FFChip for moods, a note field. Discrete taps autosave immediately
// with a warm "Logged, love." confirmation; the note saves on commit (focus
// loss) so we don't write on every keystroke. Binds to a draft DayLog and
// store.upsert.
struct LogView: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var date: Date

    @State private var draft = DayLog(dateKey: "")
    @State private var showToast = false
    @State private var toastToken = 0
    @FocusState private var noteFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.card) {
                datePicker
                flowSection
                moodSection
                symptomSection
                noteSection
            }
            .padding(.horizontal, FFSpace.s4)
            .padding(.top, FFSpace.s2)
            .padding(.bottom, FFSpace.section)
        }
        .overlay(alignment: .top) { toastOverlay }
        .onAppear(perform: reload)
        .onChange(of: date) { _, _ in reload() }
    }

    // MARK: state

    private func reload() {
        draft = store.log(for: date) ?? DayLog(dateKey: store.key(for: date))
    }

    // Discrete-tap autosave + warm confirmation. Idempotent; empty drafts are
    // dropped by the store.
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

    // MARK: sections

    private var datePicker: some View {
        FFCard {
            HStack {
                Text("Logging for")
                    .font(ffBody(FFType.sm, weight: .semibold))
                    .foregroundStyle(theme.color(.muted))
                Spacer()
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(theme.color(.primaryStrong))
            }
        }
    }

    private var flowSection: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                sectionTitle("Flow")
                FlowScale(selection: Binding(
                    get: { draft.flow },
                    set: { draft.flow = $0; save() }
                ))
            }
        }
    }

    private var moodSection: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                sectionTitle("Mood")
                FlowLayout(spacing: FFSpace.inline) {
                    ForEach(Mood.allCases) { mood in
                        FFChip(mood.label, selected: draft.moods.contains(mood)) {
                            draft.moods.formSymmetricDifference([mood])
                            save()
                        }
                    }
                }
            }
        }
    }

    private var symptomSection: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s3) {
                sectionTitle("Symptoms")
                FlowLayout(spacing: FFSpace.inline) {
                    ForEach(Symptom.allCases) { symptom in
                        SymptomChip(symptom, selected: draft.symptoms.contains(symptom)) {
                            draft.symptoms.formSymmetricDifference([symptom])
                            save()
                        }
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                sectionTitle("Note")
                TextField("Anything worth remembering…", text: $draft.note, axis: .vertical)
                    .font(ffBody(FFType.md))
                    .foregroundStyle(theme.color(.text))
                    .lineLimit(2...5)
                    .tint(theme.color(.primaryStrong))
                    .focused($noteFocused)
            }
        }
        // Save on commit: when the note loses focus, not on every keystroke.
        .onChange(of: noteFocused) { _, focused in
            if !focused { save() }
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(ffBody(FFType.md, weight: .semibold))
            .foregroundStyle(theme.color(.deep))
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
