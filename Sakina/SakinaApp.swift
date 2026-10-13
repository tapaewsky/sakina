import SwiftUI
import UserNotifications

@main
struct SakinaApp: App {
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    #if DEBUG
                    if CommandLine.arguments.contains("-testNotification") { await Reminder.test() }
                    #endif
                }
        }
        .backgroundTask(.appRefresh(Reminder.refreshTaskID)) {
            await Reminder.refreshFromSettings()
        }
    }
}
