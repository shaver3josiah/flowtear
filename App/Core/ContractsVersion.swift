import Foundation

// The contracts version the iOS app was last synced to. This is the single line
// the cross-platform drift check reads to tell whether native iOS has fallen
// behind (or ahead of) the web/Android build. Bump it together with
// contracts/manifest.json and web/core/version.js whenever shared behavior —
// the cycle algorithm, the logged-data models, or the design tokens — changes.
enum Contracts {
    static let version = "1.4.0"
}
