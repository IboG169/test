import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    self.scheduleNotifications()
                }
            }
        }
    }

    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let morningHour = UserDefaults.standard.integer(forKey: "morningNotificationHour")
        let morningMinute = UserDefaults.standard.integer(forKey: "morningNotificationMinute")
        let eveningHour = UserDefaults.standard.integer(forKey: "eveningNotificationHour")
        let eveningMinute = UserDefaults.standard.integer(forKey: "eveningNotificationMinute")

        let streak = UserDefaults.standard.integer(forKey: "currentStreak")
        let dayCount = streak + 1

        // Morning notification
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Yalla Ibrahim!"
        morningContent.body = "Tag \(dayCount) wartet auf dich \u{1F680}"
        morningContent.sound = .default

        var morningComponents = DateComponents()
        morningComponents.hour = morningHour == 0 ? 7 : morningHour
        morningComponents.minute = morningMinute

        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "morning", content: morningContent, trigger: morningTrigger)
        center.add(morningRequest)

        // Evening notification
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "YallaFit"
        eveningContent.body = "Hast du heute eingetragen? \u{1F4DD}"
        eveningContent.sound = .default

        var eveningComponents = DateComponents()
        eveningComponents.hour = eveningHour == 0 ? 21 : eveningHour
        eveningComponents.minute = eveningMinute

        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "evening", content: eveningContent, trigger: eveningTrigger)
        center.add(eveningRequest)
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
