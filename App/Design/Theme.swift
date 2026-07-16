import SwiftUI
import UIKit

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM — Flowtear
//
//  Ported from the Flowtear Design System (design-system/tokens/*.css). This is
//  the single source of truth for color, type, spacing, radius, shadow, motion.
//  Every view resolves through `Theme` — no view holds a literal hex or size.
//
//  Palette derives from Bloom: a single rose family + one gold + one green,
//  plus two purpose-built ramps (cycle-phase, flow-intensity). Presets ship as
//  full palettes swapped at runtime — light accents (Pink, Cherry, Rose, Peony,
//  Soft, Light) plus a full Dark palette — exactly like the source calculator.
//
//  On top of any preset, an optional CUSTOM ACCENT (a user-picked color) recolors
//  the brand ramp (primary / primaryStrong / deep) so the whole app is fully
//  colour-customizable. The cycle-phase and flow ramps stay fixed: menstrual-red
//  and fertile-gold carry *meaning*, so they are never recolored by a whim pick.
// ─────────────────────────────────────────────────────────────────────────────

@Observable
final class Theme {
    /// Named full-palette preset (see `presetNames`). Persisted.
    var presetName: String { didSet { persist() } }
    /// Optional user-picked accent, overriding the preset's brand ramp. Persisted.
    var customAccentHex: String? { didSet { persist() } }

    private var tokens: [String: String]

    /// Color Studio: per-token overrides laid over everything else. Persisted.
    var studioOverrides: [String: String] { didSet { persist() } }

    private static let presetKey = "flowtear.theme.preset"
    private static let accentKey = "flowtear.theme.accent"
    private static let studioKey = "flowtear.theme.studio"

    init() {
        // Dark is the house default — new installs open in the plum night
        // palette; anything she's ever picked wins over the default.
        let p = UserDefaults.standard.string(forKey: Theme.presetKey) ?? "dark"
        let a = UserDefaults.standard.string(forKey: Theme.accentKey)
        let o = UserDefaults.standard.dictionary(forKey: Theme.studioKey) as? [String: String] ?? [:]
        presetName = p
        customAccentHex = a
        studioOverrides = o
        tokens = Theme.buildTokens(preset: p, accentHex: a).merging(o) { _, n in n }
    }

    /// The tokens the Color Studio may recolor ("nearly everything") — the
    /// semantic cycle/flow ramps stay fixed because their colors carry meaning.
    static let studioTokens: [Tok] = [.bg, .surface, .surfaceSoft, .surface2,
                                      .text, .muted, .line, .flowerCenter, .good, .phaseLuteal]

    static func studioLabel(_ t: Tok) -> String {
        switch t {
        case .bg: "Background";        case .surface: "Cards"
        case .surfaceSoft: "Soft fills"; case .surface2: "Accent panels"
        case .text: "Text";            case .muted: "Soft text"
        case .line: "Hairlines";       case .flowerCenter: "Gold accents"
        case .good: "Success green";   case .phaseLuteal: "Stretch lavender"
        default: t.rawValue
        }
    }

    func setStudioColor(_ t: Tok, _ color: Color) { studioOverrides[t.rawValue] = Theme.hex(from: color) }
    func resetStudio() { studioOverrides = [:] }

    // MARK: mutation (property observers do the persist + rebuild)

    func setPreset(_ name: String) { presetName = name }
    func setCustomAccent(_ color: Color?) { customAccentHex = color.map(Theme.hex(from:)) }
    func resetCustomAccent() { customAccentHex = nil }

    private func persist() {
        UserDefaults.standard.set(presetName, forKey: Theme.presetKey)
        if let a = customAccentHex { UserDefaults.standard.set(a, forKey: Theme.accentKey) }
        else { UserDefaults.standard.removeObject(forKey: Theme.accentKey) }
        UserDefaults.standard.set(studioOverrides, forKey: Theme.studioKey)
        tokens = Theme.buildTokens(preset: presetName, accentHex: customAccentHex)
            .merging(studioOverrides) { _, n in n }
    }

    // MARK: presets

    static let lightPresets = ["cherry", "pink", "rose", "peony", "soft", "light"]
    static let darkPresets  = ["dark", "midnight"]
    static let presetNames  = darkPresets + lightPresets   // dark family first — it's the house default

    static func label(for preset: String) -> String {
        switch preset {
        case "cherry": "Cherry";     case "pink": "Pink";  case "rose": "Rose"
        case "peony":  "Peony";      case "soft": "Soft";  case "light": "Light"
        case "dark":   "Plum Night"; case "midnight": "Midnight"
        default: preset.capitalized
        }
    }

    static func isDark(_ preset: String) -> Bool { darkPresets.contains(preset) }
    var isDarkMode: Bool { Theme.isDark(presetName) }

    /// The active accent color (custom pick if set, else the preset's primary).
    var customAccent: Color? { customAccentHex.flatMap { Color(hex: $0) } }

    /// A swatch color for the preset chip in Settings (its primary brand color).
    static func swatch(for preset: String) -> Color {
        Color(hex: buildTokens(preset: preset, accentHex: nil)["primary"] ?? "#F06FA7") ?? .pink
    }

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

    /// Per-scheme card shadow color (warm rose on light, deep ink on dark).
    var shadow: Color {
        if isDarkMode { return Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.5) }
        switch presetName {
        case "rose":  return Color(.sRGB, red: 161/255, green: 28/255, blue: 65/255, opacity: 0.16)
        case "peony": return Color(.sRGB, red: 142/255, green: 21/255, blue: 96/255, opacity: 0.16)
        case "soft":  return Color(.sRGB, red: 176/255, green: 66/255, blue: 102/255, opacity: 0.14)
        default:      return Color(.sRGB, red: 176/255, green: 27/255, blue: 88/255, opacity: 0.16)
        }
    }

    // MARK: token tables

    /// Base (Cherry) tokens. Presets override only the subset they change.
    private static let base: [String: String] = [
        // surfaces
        "bg": "#FDF2F7", "surface": "#FFFFFF", "surfaceSoft": "#FBE4EE", "surface2": "#FDF0F5",
        // brand (primaryStrong deep enough that white text on it clears 4.5:1)
        "primary": "#F06FA7", "primaryStrong": "#D23070", "deep": "#B01B58",
        // text
        "text": "#421527", "muted": "#885B6D", "line": "#F2CEDF",
        "flowerCenter": "#FFC966", "good": "#17703B",
        // Posy's face ink — a deep rose that reads on her pink petals in BOTH
        // schemes (dark presets brighten the petals, so dark ink still lands).
        "bloomInk": "#5E1434",
        // Text/icon color on primary/primaryStrong/deep fills. White on light
        // presets; the dark presets BRIGHTEN those fills to light pinks, so
        // they override this to a deep plum ink (~5.5:1 on their primaryStrong).
        "onPrimary": "#FFFFFF",
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

    private static func buildTokens(preset: String, accentHex: String?) -> [String: String] {
        var t = base.merging(overrides(for: preset)) { _, new in new }
        if let hex = accentHex, let ramp = accentRamp(baseHex: hex, isDark: isDark(preset)) {
            t.merge(ramp) { _, new in new }
        }
        return t
    }

    private static func overrides(for preset: String) -> [String: String] {
        switch preset {
        case "pink":
            // The explicit "pink mode" — candy-bright but no longer neon:
            // the accents sit a step softer so long reading stays gentle.
            return ["bg": "#FEF1F7", "surfaceSoft": "#FCDDEC", "surface2": "#FEEAF3",
                    "primary": "#F9679E", "primaryStrong": "#D62C74", "deep": "#B01A60",
                    "text": "#43132C", "muted": "#8C526F", "line": "#F9CFE2", "flowerCenter": "#FFC55A"]
        case "rose":
            return ["bg": "#FDF2F1", "surfaceSoft": "#FADDE0", "surface2": "#FCEBEC",
                    "primary": "#E56A87", "primaryStrong": "#CE3E63", "deep": "#A11C41",
                    "text": "#431B23", "muted": "#835862", "line": "#F1CBD1", "flowerCenter": "#FFC878"]
        case "peony":
            return ["bg": "#FDF1F8", "surfaceSoft": "#F9DCEC", "surface2": "#FCEAF3",
                    "primary": "#E15BA4", "primaryStrong": "#C22E85", "deep": "#8E1560",
                    "text": "#3B1030", "muted": "#815571", "line": "#EFC8E0", "flowerCenter": "#FFC966"]
        case "soft":
            return ["bg": "#FEF7F9", "surfaceSoft": "#FBE7ED", "surface2": "#FDF1F4",
                    "primary": "#EE9DBB", "primaryStrong": "#C14E73", "deep": "#B04266",
                    "text": "#4A2533", "muted": "#82606D", "line": "#F4D8E1", "flowerCenter": "#FFD488"]
        case "light":
            // Airy near-neutral light: crisp white surfaces, cool-neutral text,
            // rose accent kept for the semantic ramps.
            return ["bg": "#FBFAFB", "surface": "#FFFFFF", "surfaceSoft": "#F3EEF1", "surface2": "#F8F5F7",
                    "primary": "#E75C93", "primaryStrong": "#CE3B76", "deep": "#8A2A54",
                    "text": "#2A2430", "muted": "#726A75", "line": "#E9E2E8", "flowerCenter": "#F5B342"]
        case "dark":
            // Full dark palette — the house default. A rich warm plum rather
            // than flat near-black: surfaces carry a whisper of rose so cards
            // lift off the background, accents run rosier, text a touch
            // creamier. Overrides every scheme + soft-ramp key; the vivid
            // phase/flow tints read fine on dark so they carry through.
            return [
                "bg": "#171118", "surface": "#221925", "surfaceSoft": "#302433", "surface2": "#291E2D",
                "primary": "#F792BC", "primaryStrong": "#F26AA2", "deep": "#F8CCDF",
                "text": "#F8EDF3", "muted": "#C7A9B8", "line": "#3F3140",
                "flowerCenter": "#FFCE73", "good": "#55C389", "onPrimary": "#40122B",
                // dark soft-washes for phase cells/badges (light tints would glow)
                "phaseMenstrualSoft": "#3E2433", "phaseFollicularSoft": "#372230",
                "phaseFertileSoft": "#3C2F20", "phaseOvulationSoft": "#3C2D1C", "phaseLutealSoft": "#32263D",
                "flowNone": "#5E4D56",
                // aliases that point at soft washes
                "flowSoft": "#3E2433",
            ]
        case "midnight":
            // The second dark option — ink and moonlight. Cooler, quieter, and
            // a step deeper than Plum Night: near-black slate surfaces, silvery
            // rose accents, moon-gold kept for the flower center. For nights
            // when plum feels too warm.
            return [
                "bg": "#0F0F14", "surface": "#181820", "surfaceSoft": "#23232F", "surface2": "#1E1E29",
                "primary": "#E48BB3", "primaryStrong": "#ED6FA4", "deep": "#F0C4D8",
                "text": "#F1EDF4", "muted": "#ABA1B6", "line": "#31313F",
                "flowerCenter": "#F3C76F", "good": "#4EBD8C", "onPrimary": "#40122B",
                // dark soft-washes (light tints would glow on near-black)
                "phaseMenstrualSoft": "#391F2E", "phaseFollicularSoft": "#32202C",
                "phaseFertileSoft": "#372B1E", "phaseOvulationSoft": "#362919", "phaseLutealSoft": "#2B2338",
                "flowNone": "#555064",
                // aliases that point at soft washes
                "flowSoft": "#391F2E",
            ]
        default: // cherry
            return [:]
        }
    }

    // MARK: custom-accent ramp

    /// Derive primary / primaryStrong / deep from one user-picked color, scaled by
    /// scheme. On light: strong is darker, deep darker still (contrast on white).
    /// On dark: strong is brighter, deep light (contrast on near-black).
    private static func accentRamp(baseHex: String, isDark: Bool) -> [String: String]? {
        guard let ui = UIColor(hex: baseHex) else { return nil }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        func mk(_ ss: CGFloat, _ bb: CGFloat) -> String {
            UIColor(hue: h, saturation: min(max(ss, 0), 1), brightness: min(max(bb, 0), 1), alpha: 1).hexString
        }
        if isDark {
            return ["primary": mk(s * 0.95, min(b * 1.05, 1.0)),
                    "primaryStrong": mk(s * 0.90, min(b * 1.18, 1.0)),
                    "deep": mk(max(s * 0.55, 0.18), max(b * 1.40, 0.82))]
        }
        return ["primary": mk(min(s * 1.02, 1.0), b),
                "primaryStrong": mk(min(s * 1.14, 1.0), b * 0.84),
                "deep": mk(min(s * 1.18, 1.0), min(b * 0.55, 0.48))]
    }

    static func hex(from color: Color) -> String { UIColor(color).hexString }
}

// MARK: - Typed tokens

enum Tok: String {
    case bg, surface, surfaceSoft, surface2
    case primary, primaryStrong, deep
    case text, muted, line, flowerCenter, good, bloomInk, onPrimary
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
    /// satisfying, longer overshoot for the ring's tap-spin.
    static let ringSpin  = Animation.spring(response: 0.7, dampingFraction: 0.62)
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

extension UIColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   CGFloat((v >> 16) & 0xFF) / 255,
            green: CGFloat((v >> 8) & 0xFF) / 255,
            blue:  CGFloat(v & 0xFF) / 255,
            alpha: 1
        )
    }
    /// "#RRGGBB" (sRGB, alpha dropped). Used to persist a picked accent.
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        func clamp(_ v: CGFloat) -> Int { min(max(Int((v * 255).rounded()), 0), 255) }
        return String(format: "#%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }
}
