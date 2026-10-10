import Foundation
import UserNotifications

/// Island Care reminders: the page decides *when* (see island_ui.js); iOS delivers them as local
/// notifications, the counterpart of Android's AlarmManager + ReminderReceiver.
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Reminders()
    private let prefix = "collectify.reminder."

    func isAuthorized(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let ok = s.authorizationStatus == .authorized || s.authorizationStatus == .provisional || s.authorizationStatus == .ephemeral
            done(ok)
        }
    }

    func requestPermission(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in done(granted) }
    }

    func schedule(id: Int, atMs: Double, title: String, text: String) {
        let seconds = max(5, Date(timeIntervalSince1970: atMs / 1000).timeIntervalSinceNow)
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = text
        c.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: prefix + String(id), content: c, trigger: trigger)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map { $0.identifier }.filter { $0.hasPrefix(self.prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // Show reminders even while the app is open (the page cancels them when the island is on screen).
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
