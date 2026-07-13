import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM — Flowtear
//
//  Ported from the Flowtear Design System (design-system/tokens/*.css). This is
//  the single source of truth for color, type, spacing, radius, shadow, motion.
//  Every view resolves through `Theme` — no view holds a literal hex or size.
//
//  Palette derives from Bloom: a single rose family + one gold + one green,
//  plus two purpose-built ramps (cycle-phase, flow-intensity). Four presets ship
//  (Cherry default, Rose, Peony, Soft), swapped at runtime like the source app.
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class Theme {
    var presetName: String { didSet { UserDefaults.standard.set(presetName, forKey: Self.key) } }
    private var tokens: [String: String]

    private static let key = "flowtear.theme.preset"

    init(preset: String = UserDefaults.standard.string(forKey: Theme.key) ?? "cherry") {
        presetName = preset
        tokens = Theme.tokens(for: preset)
    }

    func setPreset(_ name: String) {
        presetName = name
        tokens = Theme.tokens(for: name)
    }

    static let presetNames = ["cherry", "rose", "peony", "soft"]

    // MARK: color access

    /// String-keyed lookup (kept for incremental adoption). In DEBUG a missing
    /// token asserts loudly so a typo/rename can't render an invisible element.
    func color(_ token: String) -> Color {
        guard let raw = tokens[token], let c = Color(hex: raw) else {
            assert(tokens[token] != nil, "Theme: unknown color token \"\(token)\"")
            return .clear
        }
        return c
    }

    /// Typed lookup — prefer this in new code.
    func color(_ t: Tok) -> Color { color(t.rawValue) }

    /// Per-preset warm rose shadow color (used by `.ffCardShadow()`).
    var shadow: Color {
        switch presetName {
        case "rose":  return Color(.sRGB, red: 161/255, green: 28/255,  blue: 65/255,  opacity: 0.16)
        case "peony": return Color(.sRGB, red: 142/255, green: 21/255,  blue: 96/255,  opacity: 0.16)
        case "soft":  return Color(.sRGB, red: 176/255, green: 66/255,  blue: 102/255, opacity: 0.14)
        default:      return Color(.sRGB, red: 176/255, green: 27/255,  blue: 88/255,  opacity: 0.16)
        }
    }

    // MARK: token tables

    /// Base (Cherry) tokens. Presets override only the subset they change.
    private static let base: [String: String] = [
        // surfaces
        "bg": "#FDF2F7", "surface": "#FFFFFF", "surfaceSoft": "#FBE4EE", "surface2": "#FDF0F5",
        // brand
        "primary": "#F06FA7", "primaryStrong": "#E2417F", "deep": "#B01B58",
        // text
        "text": "#421527", "muted": "#885B6D", "line": "#F2CEDF",
        "flowerCenter": "#FFC966", "good": "#17703B",
        // cycle-phase ramp
        "phaseMenstrual": "#E14B7A", "phaseFollicular": "#F7A8C6", "phaseFertile": "#F6BE6A",
        "phaseOvulation": "#EC9A32", "phaseLuteal": "#C98BC7",
        "phaseMenstrualSoft": "#FBDCE6", "phaseFollicularSoft": "#FCE7F0", "phaseFertileSoft": "#FDEDD4",
        "phaseOvulationSoft": "#FBE4C6", "phaseLutealSoft": "#F3E1F1",
        // flow-intensity ramp
        "flowSpotting": "#F7C6D9", "flowLight": "#F492B7", "flowMedium": "#E85C90",
        "flowHeavy": "#BE2C60", "flowNone": "#D9C4CE",
        // ── back-compat aliases used by existing screens (map onto the ramps) ──
        "flow": "#E14B7A",          // period fill = phaseMenstrual
        "flowSoft": "#FBDCE6",      // = phaseMenstrualSoft
        "fertile": "#F6BE6A",       // = phaseFertile
        "ovulation": "#EC9A32",     // = phaseOvulation
        "predicted": "#F7A8C6",     // predicted period tint = phaseFollicular
        "luteal": "#C98BC7",
    ]

    private static func tokens(for preset: String) -> [String: String] {
        let overrides: [String: String]
        switch preset {
        case "rose":
            overrides = ["bg": "#FDF2F1", "surfaceSoft": "#FADDE0", "surface2": "#FCEBEC",
                         "primary": "#E56A87", "primaryStrong": "#CE3E63", "deep": "#A11C41",
                         "text": "#431B23", "muted": "#835862", "line": "#F1CBD1", "flowerCenter": "#FFC878"]
        case "peony":
            overrides = ["bg": "#FDF1F8", "surfaceSoft": "#F9DCEC", "surface2": "#FCEAF3",
                         "primary": "#E15BA4", "primaryStrong": "#C22E85", "deep": "#8E1560",
                         "text": "#3B1030", "muted": "#815571", "line": "#EFC8E0", "flowerCenter": "#FFC966"]
        case "soft":
            overrides = ["bg": "#FEF7F9", "surfaceSoft": "#FBE7ED", "surface2": "#FDF1F4",
                         "primary": "#EE9DBB", "primaryStrong": "#DB6E93", "deep": "#B04266",
                         "text": "#4A2533", "muted": "#82606D", "line": "#F4D8E1", "flowerCenter": "#FFD488"]
        default:
            overrides = [:]
        }
        return base.merging(overrides) { _, new in new }
    }
}

// MARK: - Typed tokens

enum Tok: String {
    case bg, surface, surfaceSoft, surface2
    case primary, primaryStrong, deep
    case text, muted, line, flowerCenter, good
    case phaseMenstrual, phaseFollicular, phaseFertile, phaseOvulation, phaseLuteal
    case phaseMenstrualSoft, phaseFollicularSoft, phaseFertileSoft, phaseOvulationSoft, phaseLutealSoft
    case flowSpotting, flowLight, flowMedium, flowHeavy, flowNone
}

// MARK: - Spacing & radius (spacing.css)

enum FFSpace {
    static let s1: CGFloat = 4,  s2: CGFloat = 8,  s3: CGFloat = 12, s4: CGFloat = 16
    static let s5: CGFloat = 20, s6: CGFloat = 24, s7: CGFloat = 32, s8: CGFloat = 40
    static let card: CGFloat = 18      // Card interior padding
    static let section: CGFloat = 24   // between stacked cards
    static let inline: CGFloat = 8     // between inline chips/icons
    static let screenMax: CGFloat = 440
    static let tapMin: CGFloat = 44
}

enum FFRadius {
    static let sm: CGFloat = 12, md: CGFloat = 16, card: CGFloat = 22, lg: CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Type scale (typography.css). Font.custom falls back to system if the
// family isn't bundled yet — drop the OFL .ttf files into App/Resources/Fonts/
// and add them to project.yml UIAppFonts to activate. Sizes match the DS ramp.

enum FFType {
    static let xs2: CGFloat = 11, xs: CGFloat = 12, sm: CGFloat = 13, base: CGFloat = 15
    static let md: CGFloat = 16, lg: CGFloat = 18, xl: CGFloat = 22, xl2: CGFloat = 28
    static let xl3: CGFloat = 40, xl4: CGFloat = 56, xl5: CGFloat = 72
}

/// Quicksand — all UI/body.
func ffBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom("Quicksand", size: size).weight(weight)
}
/// Playfair Display — headings.
func ffDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
    .custom("Playfair Display", size: size).weight(weight)
}
/// Playfair Display, tabular — big numerals (cycle day, stats, countdowns).
func ffNumber(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
    .custom("Playfair Display", size: size).weight(weight).monospacedDigit()
}
/// Great Vibes — the wordmark & rare affectionate lines.
func ffScript(_ size: CGFloat) -> Font { .custom("Great Vibes", size: size) }

// MARK: - Motion (effects.css). Signature ease + gentle spring. Loops must gate
// on accessibilityReduceMotion at the call site.

enum FFMotion {
    /// cubic-bezier(.22,1,.36,1) — view/card entrances, ring fills.
    static let signature = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.3)
    static let fast      = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.18)
    static let slow      = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.45)
    /// gentle overshoot for taps (cubic-bezier(.34,1.56,.64,1))
    static let spring    = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let pressScale: CGFloat = 0.96
}

/// View-in transition (opacity + 8px rise) — the DS signature entrance.
extension AnyTransition {
    static var ffViewIn: AnyTransition {
        .asymmetric(insertion: .opacity.combined(with: .offset(y: 8)),
                    removal: .opacity)
    }
}

// MARK: - Card shadow modifier (warm rose drop, never grey)

extension View {
    /// Soft rose card shadow: --shadow-card `0 8px 24px -12px var(--shadow)`.
    func ffCardShadow(_ theme: Theme) -> some View {
        shadow(color: theme.shadow, radius: 12, x: 0, y: 8)
    }
    /// Floating/elevated shadow: --shadow-float.
    func ffFloatShadow(_ theme: Theme) -> some View {
        shadow(color: theme.shadow, radius: 20, x: 0, y: 12)
    }
}

// MARK: - hex

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue:  Double(v & 0xFF) / 255
        )
    }
}
