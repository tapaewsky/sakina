import BackgroundTasks
import Foundation
import UserNotifications

/// Напоминания: 1, 3 или 5 в день, равномерно с утра до вечера, в каждом — свой текст.
@MainActor
enum Reminder {
    static let counts = [1, 3, 5]

    static func hours(for count: Int) -> [Int] {
        switch count {
        case 1:  [9]
        case 3:  [9, 14, 20]
        default: [8, 11, 14, 17, 20]
        }
    }

    static func schedule(count: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return false }
        await removeDaily()

        // iOS хранит не больше 64 запланированных уведомлений — расписание продлевается при каждом открытии
        let hours = hours(for: count)
        let days = min(30, 60 / hours.count)
        let calendar = Calendar.current
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: .now) else { continue }
            for (slot, hour) in hours.enumerated() {
                guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day), fire > .now else { continue }
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                let request = UNNotificationRequest(identifier: "d\(offset)-\(slot)", content: content(for: Verse.at(fire, slot: slot)), trigger: trigger)
                try? await center.add(request)
            }
        }
        return true
    }

    /// Продлить расписание по сохранённым настройкам (при открытии приложения и в фоне)
    static func refreshFromSettings() async {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "reminderOn") else { return }
        let count = defaults.object(forKey: "reminderCount") as? Int ?? 3
        _ = await schedule(count: count)
        requestBackgroundRefresh()
    }

    // Фоновое обновление — чтобы уведомления не заканчивались, даже если приложение долго не открывают
    nonisolated static let refreshTaskID = "cam.sakina.refresh"

    nonisolated static func requestBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func cancel() {
        Task { await removeDaily() }
    }

    /// Убрать только ежедневные уведомления (их id начинаются с «d»)
    private static func removeDaily() async {
        let center = UNUserNotificationCenter.current()
        let ids = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("d") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Пробное уведомление через несколько секунд (запуск с аргументом -testNotification)
    static func test(after seconds: TimeInterval = 5) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "test", content: content(for: Verse.at(.now, slot: 2)), trigger: trigger))
    }

    private static func content(for verse: Verse) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = verse.isAyah ? "Аят" : "Хадис"
        content.subtitle = verse.source
        content.body = verse.text
        content.sound = .default
        content.threadIdentifier = "daily"
        content.userInfo = ["verseID": verse.id]
        return content
    }
}

/// Какой текст открыть — по нажатию на уведомление
@MainActor
final class Router: ObservableObject {
    static let shared = Router()
    @Published var verseID: Int?
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// Показывать уведомление, даже если приложение открыто
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let id = response.notification.request.content.userInfo["verseID"] as? Int else { return }
        await MainActor.run { Router.shared.verseID = id }
    }
}
