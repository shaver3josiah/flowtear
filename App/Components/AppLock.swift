import SwiftUI
import UIKit
import LocalAuthentication

// AppLockGate — optional privacy lock. Off by default; toggled in the pencil
// settings. When on, the garden hides behind Face ID / Touch ID / the device
// passcode on cold launch and whenever the app has been backgrounded.
//
// The lock screen lives in its OWN UIWindow (above .alert level), because
// SwiftUI sheets and fullScreenCovers present ABOVE the view hierarchy — an
// in-view overlay would leave an open sheet visible and interactive while
// "locked". A separate key window also keeps VoiceOver / Switch Control from
// reaching the content behind it; `accessibilityHidden(locked)` on the content
// is the second bolt on that door. If the device has no passcode at all there
// is nothing to lock behind, so the gate quietly stands down.
@Observable @MainActor
final class AppLockModel {
    var needsManualUnlock = false
}

struct AppLockGate: ViewModifier {
    @Environment(Theme.self) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("flowtear.appLock") private var lockOn = false
    @State private var locked: Bool
    @State private var model = AppLockModel()
    @State private var authInFlight = false
    @State private var curtain: UIWindow?

    init() {
        _locked = State(initialValue: UserDefaults.standard.bool(forKey: "flowtear.appLock"))
    }

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(locked)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background && lockOn {
                    locked = true
                    model.needsManualUnlock = false
                    showCurtain()
                }
                // After a cancelled prompt, park on the curtain's Unlock button
                // instead of auto-prompting in a loop (the passcode sheet itself
                // bounces the scene through .inactive/.active).
                if phase == .active && locked && !model.needsManualUnlock {
                    unlock()
                }
            }
            .onAppear {
                if locked {
                    showCurtain()
                    unlock()
                }
            }
    }

    // MARK: curtain window

    private func showCurtain() {
        guard curtain == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState != .unattached })
        else { return }
        let host = UIHostingController(
            rootView: LockScreen(model: model, unlock: unlock).environment(theme))
        let w = UIWindow(windowScene: scene)
        w.windowLevel = .alert + 1
        w.rootViewController = host
        w.makeKeyAndVisible()
        curtain = w
    }

    private func hideCurtain() {
        curtain?.isHidden = true
        curtain = nil
    }

    // MARK: auth

    private func unlock() {
        guard !authInFlight else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            // No device passcode — nothing to lock behind.
            setUnlocked()
            return
        }
        authInFlight = true
        ctx.evaluatePolicy(.deviceOwnerAuthentication,
                           localizedReason: "Unlock your cycle data") { ok, _ in
            DispatchQueue.main.async {
                authInFlight = false
                if ok { setUnlocked() } else { model.needsManualUnlock = true }
            }
        }
    }

    private func setUnlocked() {
        locked = false
        model.needsManualUnlock = false
        hideCurtain()
    }
}

private struct LockScreen: View {
    @Environment(Theme.self) private var theme
    let model: AppLockModel
    let unlock: () -> Void

    var body: some View {
        ZStack {
            theme.color(.bg).ignoresSafeArea()
            VStack(spacing: FFSpace.s4) {
                FlowerMark(size: 72, breathe: true)
                Text("Your garden is private")
                    .font(ffDisplay(FFType.xl, weight: .bold))
                    .foregroundStyle(theme.color(.deep))
                Text("Unlock with Face ID or your passcode.")
                    .font(ffBody(FFType.sm))
                    .foregroundStyle(theme.color(.muted))
                if model.needsManualUnlock {
                    FFButton("Unlock", style: .primary, icon: "faceid") { unlock() }
                        .padding(.top, FFSpace.s2)
                }
            }
            .padding(FFSpace.s5)
        }
    }
}

extension View {
    /// Wrap the app's root in the optional Face ID / passcode lock.
    func appLockGate() -> some View { modifier(AppLockGate()) }
}
