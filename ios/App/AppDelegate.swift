import UIKit
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let root = RootViewController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = Reminders.shared
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.rootViewController = root
        w.backgroundColor = Theme.background
        w.makeKeyAndVisible()
        window = w
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // iOS may have closed the local sockets while the app was suspended
        root.services.ensureRunning()
    }
}

enum Theme {
    /// The page's dark background, so there is no white flash at the edges.
    static let background = UIColor(red: 0.043, green: 0.063, blue: 0.094, alpha: 1)
    static let gold = UIColor(red: 0.94, green: 0.84, blue: 0.48, alpha: 1)
}
