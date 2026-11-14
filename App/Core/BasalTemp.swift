import Foundation

// Basal temperature in the unit her region actually uses. Storage stays
// Celsius everywhere (DayLog.temperatureC is the contract); only the display,
// the slider bounds and the spoken value change. Every screen that shows a
// waking temperature routes through here, so there is one place to be right.
//
// ponytail: read from the locale, like Apple's own Health and Weather. No
// setting to find and nothing to migrate — add a manual override only if
// someone actually asks for one.
enum BasalTemp {
    /// US locales measure in Fahrenheit; everyone else, including the UK,
    /// reads body temperature in Celsius.
    static let usesCelsius: Bool = Locale.current.measurementSystem != .us

    static var unit: String { usesCelsius ? "°C" : "°F" }

    /// Plausible waking-temperature span, in display units. The two ranges are
    /// the same span: 96–100 °F is 35.6–37.8 °C.
    static var range: ClosedRange<Double> { usesCelsius ? 35.6...37.8 : 96.0...100.0 }

    /// One step of a drugstore basal thermometer.
    static let step: Double = 0.05

    /// A typical waking reading, for seeding a slider she hasn't moved yet.
    static var typicalDisplay: Double { usesCelsius ? 36.5 : 97.8 }
    static var typicalCelsius: Double { celsius(fromDisplay: typicalDisplay) }

    static func display(_ celsius: Double) -> Double {
        usesCelsius ? celsius : celsius * 9 / 5 + 32
    }

    static func celsius(fromDisplay v: Double) -> Double {
        usesCelsius ? v : (v - 32) * 5 / 9
    }

    /// "36.50" — the number alone, to pair with `unit`.
    static func text(_ celsius: Double) -> String {
        String(format: "%.2f", display(celsius))
    }

    /// "36.50 °C" — number and unit, for one-line readouts and reports.
    static func labelled(_ celsius: Double) -> String {
        "\(text(celsius)) \(unit)"
    }

    /// What VoiceOver reads out, from a value already in display units.
    static func spoken(display v: Double) -> String {
        String(format: "%.2f degrees %@", v, usesCelsius ? "Celsius" : "Fahrenheit")
    }
}
