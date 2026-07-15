import SwiftUI

// "Begin your own" banner — pinned at the top of every main screen while the
// first-launch sample data is active. One tap (confirmed) wipes the demo and
// starts real tracking. Renders nothing once the sample is gone.
struct SampleBanner: View {
    @Environment(Theme.self) private var theme
    @Environment(CycleStore.self) private var store
    @State private var confirming = false

    var body: some View {
        if store.sampleActive {
            Button { confirming = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.color(.flowerCenter))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("You're exploring sample data")
                            .font(ffBody(FFType.sm, weight: .semibold))
                            .foregroundStyle(theme.color(.deep))
                        Text("Tap to clear it and begin your own")
                            .font(ffBody(FFType.xs))
                            .foregroundStyle(theme.color(.muted))
                    }
                    Spacer(minLength: 0)
                    Text("Begin")
                        .font(ffBody(FFType.sm, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(theme.color(.primaryStrong), in: Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.color(.surface2), in: RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FFRadius.md, style: .continuous)
                        .strokeBorder(theme.color(.line), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Begin your own tracking")
            .accessibilityHint("Clears the sample data")
            .confirmationDialog("Clear the sample data?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Begin my own tracking", role: .destructive) { store.clearSampleData() }
                Button("Keep exploring", role: .cancel) {}
            } message: {
                Text("The 3-month preview goes away and the app starts fresh with your own logs.")
            }
        }
    }
}
