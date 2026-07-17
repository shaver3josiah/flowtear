import Foundation
import UserNotifications

// FFReminders — opt-in local notifications, off by default. Two gentle nudges:
// a daily stretch reminder at her chosen time, and a heads-up two days before
// the predicted period. Everything is scheduled on-device; nothing leaves the
// phone. Re-planned whenever settings change or the app comes to the front
// (so the period date tracks her latest logs).
enum FFReminders {
    static let stretchOnKey = "flowtear.remind.stretch"
    static let stretchMinutesKey = "flowtear.remind.stretchMinutes"   // minutes past midnight
    static let periodOnKey = "flowtear.remind.period"

    private static let stretchID = "flowtear.remind.stretch.daily"
    private static let periodID = "flowtear.remind.period.headsup"

    /// Re-plan both notifications from current settings + the latest prediction.
    /// Checks real authorization first: if she declined (or later revoked it in
    /// iOS Settings), the stored toggles flip back OFF so the switches never lie
    /// about a reminder that can't fire.
    static func refresh(nextPeriodStart: Date?) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                let d = UserDefaults.standard
                center.removePendingNotificationRequests(withIdentifiers: [stretchID, periodID])
                switch settings.authorizationStatus {
                case .denied:
                    d.set(false, forKey: stretchOnKey)
                    d.set(false, forKey: periodOnKey)
                    return
                case .notDetermined:
                    return   // the first-enable flow (requestThenRefresh) resolves this
                default:
                    schedule(nextPeriodStart: nextPeriodStart)
                }
            }
        }
    }

    private static func schedule(nextPeriodStart: Date?) {
        let d = UserDefaults.standard
        let center = UNUserNotificationCenter.current()

        if d.bool(forKey: stretchOnKey) {
            let minutes = d.object(forKey: stretchMinutesKey) as? Int ?? 18 * 60
            var comps = DateComponents()
            comps.hour = minutes / 60
            comps.minute = minutes % 60
            let content = UNMutableNotificationContent()
            content.title = "A few gentle minutes, petal?"
            content.body = "Your stretches are ready. Every pose grows the garden."
            content.sound = .default
            center.add(UNNotificationRequest(
                identifier: stretchID, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)))
        }

        if d.bool(forKey: periodOnKey), let next = nextPeriodStart,
           let day = Calendar.current.date(byAdding: .day, value: -2, to: next),
           let fire = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day),
           fire > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Your period is expected in 2 days"
            content.body = "A little heads-up so you can plan some extra kindness."
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                        from: fire)
            center.add(UNNotificationRequest(
                identifier: periodID, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)))
        }
    }

    /// Ask permission the first time a reminder is switched on, then re-plan.
    /// If she declines, the toggles switch themselves back off — honest state.
    static func requestThenRefresh(nextPeriodStart: Date?) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if !granted {
                        UserDefaults.standard.set(false, forKey: stretchOnKey)
                        UserDefaults.standard.set(false, forKey: periodOnKey)
                    }
                    refresh(nextPeriodStart: nextPeriodStart)
                }
            }
    }
}
