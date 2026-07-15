import Foundation

// Everything a user can log for a single day. `dateKey` is "yyyy-MM-dd" so logs
// are date-keyed, timezone-stable, and trivially Codable.

enum Flow: String, Codable, CaseIterable, Identifiable {
    case spotting, light, medium, heavy
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    /// Relative weight — used if we later score flow intensity. Bleeding = any case.
    var weight: Int { switch self { case .spotting: 1; case .light: 2; case .medium: 3; case .heavy: 4 } }
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case happy, calm, sensitive, sad, irritable, anxious, energized, tired
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum Symptom: String, Codable, CaseIterable, Identifiable {
    case cramps, headache, bloating, tenderBreasts, backache, fatigue,
         acne, cravings, nausea, insomnia, diarrhea, constipation
    var id: String { rawValue }
    var label: String {
        switch self {
        case .tenderBreasts: "Tender breasts"
        default: rawValue.capitalized
        }
    }
}

// Cervical fluid / discharge — ordered dry → egg-white (the fertility signal).
enum Discharge: String, Codable, CaseIterable, Identifiable {
    case dry, sticky, creamy, watery, eggWhite
    var id: String { rawValue }
    var label: String {
        switch self {
        case .eggWhite: "Egg white"
        default: rawValue.capitalized
        }
    }
}

struct DayLog: Codable, Identifiable, Equatable {
    var dateKey: String            // "yyyy-MM-dd"
    var flow: Flow?                // nil = no bleeding recorded that day
    var moods: Set<Mood> = []
    var symptoms: Set<Symptom> = []
    var note: String = ""
    var temperatureC: Double?      // optional BBT
    var stretchDone: Bool?         // marked the day's cramp-ease stretch session complete
    var discharge: Discharge?      // cervical fluid (optional decodes keep old data valid)

    var id: String { dateKey }
    var isPeriod: Bool { flow != nil }
    var isEmpty: Bool {
        flow == nil && moods.isEmpty && symptoms.isEmpty
            && note.isEmpty && temperatureC == nil && (stretchDone ?? false) == false
            && discharge == nil
    }
}

// User cycle configuration (defaults used until enough history exists).
struct CycleSettings: Codable {
    var defaultCycleLength: Int = 28
    var defaultPeriodLength: Int = 5
    var lutealPhaseLength: Int = 14   // ovulation ≈ nextPeriod − luteal
}

enum CyclePhase: String, Codable {
    case menstrual, follicular, fertile, ovulation, luteal
    var label: String { rawValue.capitalized }
}
