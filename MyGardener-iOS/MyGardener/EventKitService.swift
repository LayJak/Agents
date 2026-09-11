import Foundation
import EventKit

actor EventKitService {
    static let shared = EventKitService()
    private let store = EKEventStore()

    func sync(reminder: PlantReminder, plant: Plant) async {
        switch reminder.integration {
        case .appOnly: return
        case .reminders: _ = await createReminder(reminder, plant: plant)
        case .calendar: _ = await createCalendarEvent(reminder, plant: plant)
        case .both:
            _ = await createReminder(reminder, plant: plant)
            _ = await createCalendarEvent(reminder, plant: plant)
        }
    }

    func deleteSynced(reminder: PlantReminder) async {
        if let id = reminder.appleReminderIdentifier, let item = store.calendarItem(withIdentifier: id) as? EKReminder { try? store.remove(item, commit: true) }
        if let id = reminder.appleCalendarIdentifier, let item = store.event(withIdentifier: id) { try? store.remove(item, span: .thisEvent, commit: true) }
    }

    private func createReminder(_ r: PlantReminder, plant: Plant) async -> String? {
        let granted: Bool
        if #available(iOS 17.0, *) { granted = (try? await store.requestFullAccessToReminders()) ?? false }
        else { granted = (try? await store.requestAccess(to: .reminder)) ?? false }
        guard granted, let cal = store.defaultCalendarForNewReminders() else { return nil }
        let item = EKReminder(eventStore: store)
        item.calendar = cal
        item.title = "\(plant.name): \(r.note)"
        item.dueDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: r.dueDate)
        item.addAlarm(EKAlarm(absoluteDate: r.dueDate))
        try? store.save(item, commit: true)
        return item.calendarItemIdentifier
    }

    private func createCalendarEvent(_ r: PlantReminder, plant: Plant) async -> String? {
        let granted: Bool
        if #available(iOS 17.0, *) { granted = (try? await store.requestFullAccessToEvents()) ?? false }
        else { granted = (try? await store.requestAccess(to: .event)) ?? false }
        guard granted, let cal = store.defaultCalendarForNewEvents else { return nil }
        let e = EKEvent(eventStore: store)
        e.calendar = cal
        e.title = "\(plant.name): \(r.note)"
        e.startDate = r.dueDate
        e.endDate = r.dueDate.addingTimeInterval(30*60)
        e.addAlarm(EKAlarm(relativeOffset: 0))
        try? store.save(e, span: .thisEvent, commit: true)
        return e.eventIdentifier
    }
}
