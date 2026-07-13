import SwiftUI

// SymptomChip — a selectable chip bound to the app's Symptom vocabulary
// (DS tracking/SymptomChip). Thin wrapper over FFChip: it just supplies the
// canonical label + the SF Symbol for the symptom. Lay several in a wrapping
// stack for the log sheet. FFChip already carries the `.isSelected` trait.
struct SymptomChip: View {
    private let symptom: Symptom
    private let selected: Bool
    private let action: () -> Void

    init(_ symptom: Symptom, selected: Bool, action: @escaping () -> Void) {
        self.symptom = symptom
        self.selected = selected
        self.action = action
    }

    var body: some View {
        FFChip(symptom.label, selected: selected, icon: symptom.sfSymbol, action: action)
    }
}

// SF Symbol per symptom. Mapped from the DS Lucide names where they exist
// (zap→bolt.fill, moon→moon.fill, cloud-rain→…), reasonable picks for the rest.
// All resolve on iOS 17. ponytail: purely presentational, no test needed.
extension Symptom {
    var sfSymbol: String {
        switch self {
        case .cramps:        "bolt.fill"
        case .headache:      "brain.head.profile"
        case .bloating:      "smallcircle.filled.circle"
        case .tenderBreasts: "heart.fill"
        case .backache:      "figure.stand"
        case .fatigue:       "battery.25"
        case .acne:          "sparkles"
        case .cravings:      "fork.knife"
        case .nausea:        "water.waves"
        case .insomnia:      "moon.fill"
        case .diarrhea:      "toilet.fill"
        case .constipation:  "hourglass"
        }
    }
}
