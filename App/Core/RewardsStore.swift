import SwiftUI
import AudioToolbox

// The stretch-garden economy. Points are earned by stretching, spent on flower
// stickers, themes, the custom accent, the Color Studio, and Posey herself.
// Persisted as its OWN UserDefaults blob (with backup) so the cycle history is
// never involved. Lifetime points only ever go up; the balance is what she spends.
//
// EARNING (multiplier applies to everything earned that day):
//   pose checked off            15
//   each pose after the first   +5
//   every pose in the day done  +10
//   first-ever guided pose      +30 (once per pose, via the guided player)
//   multiplier: Anytime ×1 · 3-day starter ×2 · full 14-day ×4

struct FlowerItem: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let price: Int
    let rarity: String
}

struct SoundItem: Identifiable {
    let id: String
    let name: String
    let systemID: UInt32
    let price: Int
}

@Observable
final class RewardsStore {
    private(set) var balance = 0
    private(set) var lifetime = 0
    private(set) var guidedSeen: Set<String> = []     // move names ever guided
    private(set) var ownedFlowers: Set<String> = []
    private(set) var ownedThemes: Set<String> = []
    private(set) var accentUnlocked = false
    private(set) var colorStudioUnlocked = false
    private(set) var poseyOwned = false
    private(set) var ownedSounds: Set<String> = []
    var activeSound: String? { didSet { save() } }
    private(set) var penalizedDays: Set<String> = []   // lock-in misses already charged
    private(set) var tutorialSeen = false
    var activeSticker: String? { didSet { save() } }  // flower id or "posey"
    /// Where her sticker sits around the Today ring (normalized -1…1 offsets).
    var stickerX: Double = 0.78 { didSet { save() } }
    var stickerY: Double = -0.72 { didSet { save() } }
    /// Resting angle of the sticker on the Today ring (radians). Persisted.
    var stickerAngle: Double = -0.9 { didSet { save() } }

    private static let key = "flowtear.rewards.v1"

    init() { load() }

    // MARK: catalog

    static let flowers: [FlowerItem] = [
        FlowerItem(id: "daisy",     emoji: "🌼", name: "Daisy",     price: 100,  rarity: "Common"),
        FlowerItem(id: "tulip",     emoji: "🌷", name: "Tulip",     price: 250,  rarity: "Common"),
        FlowerItem(id: "blossom",   emoji: "🌸", name: "Blossom",   price: 500,  rarity: "Sweet"),
        FlowerItem(id: "camellia",  emoji: "💮", name: "Camellia",  price: 800,  rarity: "Sweet"),
        FlowerItem(id: "rosette",   emoji: "🏵️", name: "Rosette",   price: 1200, rarity: "Lovely"),
        FlowerItem(id: "rose",      emoji: "🌹", name: "Rose",      price: 1800, rarity: "Lovely"),
        FlowerItem(id: "hibiscus",  emoji: "🌺", name: "Hibiscus",  price: 2600, rarity: "Rare"),
        FlowerItem(id: "sunflower", emoji: "🌻", name: "Sunflower", price: 3600, rarity: "Rare"),
        FlowerItem(id: "lotus",     emoji: "🪷", name: "Lotus",     price: 5000, rarity: "Precious"),
        FlowerItem(id: "bouquet",   emoji: "🌹", name: "Red rose bouquet", price: 7500, rarity: "Precious"),
    ]
    static let poseyPrice = 10000

    // Elegant little system chimes — each a different mood of "well done".
    static let sounds: [SoundItem] = [
        SoundItem(id: "swoosh",   name: "Petal swoosh",  systemID: 1001, price: 800),
        SoundItem(id: "songbird", name: "Songbird",      systemID: 1016, price: 1200),
        SoundItem(id: "crystal",  name: "Crystal chime", systemID: 1025, price: 1600),
    ]
    static let themePrice = 600          // pink, peony, soft, light (cherry/rose/dark are free)
    static let accentPrice = 1500
    static let colorStudioPrice = 4000
    static let soundPrice = 1200
    static let starterGift = 100          // exactly a Daisy — her first unlock
    static let freeThemes: Set<String> = ["cherry", "rose", "dark"]

    /// The emoji for the sticker she has equipped (Posey shows as her bloom).
    var activeStickerEmoji: String? {
        guard let s = activeSticker else { return nil }
        if s == "posey" { return "🌸" }
        return Self.flowers.first { $0.id == s }?.emoji
    }

    /// First open of the Stretch tab: mark the tutorial seen and gift exactly
    /// enough petals for the Daisy, once ever.
    func completeTutorialWithGift() {
        guard !tutorialSeen else { return }
        tutorialSeen = true
        earn(Self.starterGift)
    }

    /// Her chosen celebration sound, if she owns one. (System sounds — asset-free.)
    func playCelebrationIfOwned() {
        guard let id = activeSound,
              let sound = Self.sounds.first(where: { $0.id == id }) else { return }
        AudioServicesPlaySystemSound(SystemSoundID(sound.systemID))
    }

    func soundOwned(_ id: String) -> Bool { ownedSounds.contains(id) }

    @discardableResult
    func buySoundItem(_ id: String) -> Bool {
        guard let item = Self.sounds.first(where: { $0.id == id }),
              !ownedSounds.contains(id), canAfford(item.price) else { return false }
        balance -= item.price
        ownedSounds.insert(id)
        activeSound = id
        AudioServicesPlaySystemSound(SystemSoundID(item.systemID))   // hear it at once
        save(); return true
    }

    /// Lock-in: −5 petals for a missed plan day, charged at most once per day.
    /// Lifetime is untouched — only the spendable balance feels it.
    @discardableResult
    func penalizeMissedDay(_ dateKey: String) -> Bool {
        guard !penalizedDays.contains(dateKey) else { return false }
        penalizedDays.insert(dateKey)
        balance = max(0, balance - 5)
        save(); return true
    }

    // MARK: earning

    /// Points for checking ON a pose. `alreadyDone` = poses done today before
    /// this one; `total` = poses in the session; `multiplier` = plan tier.
    /// Returns the points awarded (for the UI to celebrate with).
    @discardableResult
    func awardPose(alreadyDone: Int, total: Int, multiplier: Int) -> Int {
        var pts = 15
        if alreadyDone >= 1 { pts += 5 }                    // consecutive bonus
        if alreadyDone + 1 == total { pts += 10 }           // whole-day bonus
        let amount = pts * multiplier
        earn(amount)
        return amount
    }

    /// Symmetric take-back when a pose is UNchecked, so toggling can't farm points.
    func revokePose(remainingDone: Int, total: Int, wasFullDay: Bool, multiplier: Int) {
        var pts = 15
        if remainingDone >= 1 { pts += 5 }
        if wasFullDay { pts += 10 }
        balance = max(0, balance - pts * multiplier)
        save()
    }

    /// First-ever guided run of a pose: +30 (once per pose, ever).
    @discardableResult
    func awardGuidedFirstTime(moveName: String, multiplier: Int) -> Int {
        guard !guidedSeen.contains(moveName) else { return 0 }
        guidedSeen.insert(moveName)
        let amount = 30 * multiplier
        earn(amount)
        return amount
    }

    private func earn(_ amount: Int) {
        balance += amount
        lifetime += amount
        save()
    }

    // MARK: spending

    func canAfford(_ price: Int) -> Bool { balance >= price }

    @discardableResult
    func buyFlower(_ id: String) -> Bool {
        guard let f = Self.flowers.first(where: { $0.id == id }),
              !ownedFlowers.contains(id), canAfford(f.price) else { return false }
        balance -= f.price
        ownedFlowers.insert(id)
        if activeSticker == nil { activeSticker = id }
        save(); return true
    }

    @discardableResult
    func buyPosey() -> Bool {
        guard !poseyOwned, canAfford(Self.poseyPrice) else { return false }
        balance -= Self.poseyPrice
        poseyOwned = true
        activeSticker = "posey"
        save(); return true
    }

    func themeOwned(_ name: String) -> Bool {
        Self.freeThemes.contains(name) || ownedThemes.contains(name)
    }

    @discardableResult
    func buyTheme(_ name: String) -> Bool {
        guard !themeOwned(name), canAfford(Self.themePrice) else { return false }
        balance -= Self.themePrice
        ownedThemes.insert(name)
        save(); return true
    }

    @discardableResult
    func buyAccent() -> Bool {
        guard !accentUnlocked, canAfford(Self.accentPrice) else { return false }
        balance -= Self.accentPrice
        accentUnlocked = true
        save(); return true
    }

    @discardableResult
    func buyColorStudio() -> Bool {
        guard !colorStudioUnlocked, canAfford(Self.colorStudioPrice) else { return false }
        balance -= Self.colorStudioPrice
        colorStudioUnlocked = true
        save(); return true
    }

    // MARK: persistence (own blob + backup — never touches cycle data)

    private struct Blob: Codable {
        var balance = 0, lifetime = 0
        var guidedSeen: Set<String> = []
        var ownedFlowers: Set<String> = []
        var ownedThemes: Set<String> = []
        var accentUnlocked = false, colorStudioUnlocked = false, poseyOwned = false
        var activeSticker: String?
        var soundUnlocked: Bool? = false       // legacy single-chime flag
        var tutorialSeen: Bool? = false
        var stickerX: Double? = 0.78
        var stickerY: Double? = -0.72
        var ownedSounds: Set<String>? = []
        var activeSound: String?
        var penalizedDays: Set<String>? = []
        var stickerAngle: Double? = -0.9
    }

    private func save() {
        let b = Blob(balance: balance, lifetime: lifetime, guidedSeen: guidedSeen,
                     ownedFlowers: ownedFlowers, ownedThemes: ownedThemes,
                     accentUnlocked: accentUnlocked, colorStudioUnlocked: colorStudioUnlocked,
                     poseyOwned: poseyOwned, activeSticker: activeSticker,
                     soundUnlocked: false, tutorialSeen: tutorialSeen,
                     stickerX: stickerX, stickerY: stickerY,
                     ownedSounds: ownedSounds, activeSound: activeSound,
                     penalizedDays: penalizedDays, stickerAngle: stickerAngle)
        guard let data = try? JSONEncoder().encode(b) else { return }
        if let prev = UserDefaults.standard.data(forKey: Self.key) {
            UserDefaults.standard.set(prev, forKey: Self.key + ".backup")
        }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    private func load() {
        for key in [Self.key, Self.key + ".backup"] {
            if let data = UserDefaults.standard.data(forKey: key),
               let b = try? JSONDecoder().decode(Blob.self, from: data) {
                balance = b.balance; lifetime = b.lifetime; guidedSeen = b.guidedSeen
                ownedFlowers = b.ownedFlowers; ownedThemes = b.ownedThemes
                accentUnlocked = b.accentUnlocked; colorStudioUnlocked = b.colorStudioUnlocked
                poseyOwned = b.poseyOwned; activeSticker = b.activeSticker
                tutorialSeen = b.tutorialSeen ?? false
                stickerX = b.stickerX ?? 0.78
                stickerY = b.stickerY ?? -0.72
                ownedSounds = b.ownedSounds ?? []
                activeSound = b.activeSound
                penalizedDays = b.penalizedDays ?? []
                stickerAngle = b.stickerAngle ?? -0.9
                // Migrate the old single-chime unlock into the crystal chime.
                if b.soundUnlocked == true && ownedSounds.isEmpty {
                    ownedSounds.insert("crystal")
                    if activeSound == nil { activeSound = "crystal" }
                }
                return
            }
        }
    }
}
