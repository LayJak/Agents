import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func schedule(reminder: PlantReminder, plantName: String) async {
        guard reminder.dueDate > Date(), reminder.isEnabled, !reminder.isResolved else { return }
        _ = await requestAuthorization()
        let c = UNMutableNotificationContent()
        c.title = plantName
        c.body = reminder.note
        c.sound = .default
        c.categoryIdentifier = "PLANT_REMINDER"
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: reminder.id.uuidString, content: c, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(req)
    }

    nonisolated func cancel(reminderID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID.uuidString])
    }
}
