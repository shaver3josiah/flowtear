import SwiftUI

// The hidden "about" — found by double-tapping the flower in Today's top-left
// corner. A little love letter plus four tap-through FAQs.
struct AboutView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var openFAQ: Int? = nil

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "Version \(v) (\(b))"
    }

    private let faqs: [(q: String, a: String)] = [
        ("How accurate are the predictions?",
         "They're estimates built from your own logs. The ring starts as a best guess and sharpens with every cycle you record. Predictions are never a promise, and the fertile window is not birth control."),
        ("Where does my data live?",
         "On this phone, full stop. No account, no cloud, no analytics. You can export everything as a spreadsheet from Insights whenever you like. It's your data."),
        ("How do petal points work?",
         "Every stretch pose you check earns 15, chains earn +5, a finished day +10, and first-time guided poses +30, all multiplied by your plan (trio ×1, 3-day ×2, 14-day ×4). Spend them in the garden shop. The full rules live behind the book icon in Stretch."),
        ("Can stretching really help cramps?",
         "The research is genuinely promising: clinical trials of gentle poses like Cobra, Cat and Fish reduced period-cramp pain, and a review of many studies agrees. It's preventive, builds over a couple of cycles, and it's wellness support, not medical care."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: FFSpace.s5) {
                HStack {
                    Spacer()
                    FFIconButton("xmark") { dismiss() }
                }
                FlowerMark(size: 64, breathe: true)
                Text("Uncorked")
                    .font(ffScript(38))
                    .foregroundStyle(theme.color(.deep))
                Text("A little garden for your cycle: tracking, honest predictions, and Posey cheering you through the stretchy weeks. Made with love.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                Text(version)
                    .font(ffBody(FFType.xs2, weight: .medium))
                    .foregroundStyle(theme.color(.muted))

                VStack(spacing: FFSpace.s2) {
                    ForEach(Array(faqs.enumerated()), id: \.offset) { i, faq in
                        faqCard(i, faq)
                    }
                }
            }
            .padding(FFSpace.s5)
        }
        .background(theme.color(.bg))
    }

    private func faqCard(_ i: Int, _ faq: (q: String, a: String)) -> some View {
        let open = openFAQ == i
        return Button {
            withAnimation(FFMotion.fast) { openFAQ = open ? nil : i }
        } label: {
            VStack(alignment: .leading, spacing: FFSpace.s2) {
                HStack {
                    Text(faq.q)
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(theme.color(.deep))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.color(.muted))
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                if open {
                    Text(faq.a)
                        .font(ffBody(FFType.sm))
                        .foregroundStyle(theme.color(.text))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity)
                }
            }
            .padding(FFSpace.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.color(.surface), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                .strokeBorder(theme.color(.line), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint(open ? "Collapses the answer" : "Shows the answer")
    }
}
