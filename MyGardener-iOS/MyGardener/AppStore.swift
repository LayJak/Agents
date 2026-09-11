import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var state = AppState()
    @Published var weather = WeatherSnapshot()
    @Published var alerts: [GardenAlert] = []
    @Published var isRefreshingWeather = false
    @Published var weatherError: String?
    @Published var selectedTab: AppTab = .today

    let weatherService = WeatherService()
    let notificationService = NotificationService.shared
    let eventKit = EventKitService.shared
    let researchService = ResearchService.shared

    private let stateURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MyGardener", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        stateURL = base.appendingPathComponent("garden-state.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: stateURL),
              let loaded = try? JSONDecoder.myg.decode(AppState.self, from: data) else { return }
        state = loaded
    }

    func save() {
        guard let data = try? JSONEncoder.myg.encode(state) else { return }
        try? data.write(to: stateURL, options: [.atomic])
    }

    func addPlant(_ plant: Plant) {
        state.plants.insert(plant, at: 0)
        save()
    }

    func updatePlant(_ plant: Plant) {
        guard let idx = state.plants.firstIndex(where: { $0.id == plant.id }) else { return }
        state.plants[idx] = plant
        save()
    }

    func removePlant(_ plant: Plant) {
        for reminder in plant.reminders { notificationService.cancel(reminderID: reminder.id) }
        state.plants.removeAll { $0.id == plant.id }
        state.waterEvents.removeAll { $0.plantID == plant.id }
        save()
    }

    func recordDeath(_ plant: Plant, date: Date, note: String) {
        var archived = plant
        for reminder in archived.reminders { notificationService.cancel(reminderID: reminder.id) }
        archived.reminders = archived.reminders.map { var r = $0; r.isEnabled = false; return r }
        state.plantHistory.insert(DeceasedPlant(plant: archived, deathDate: date, deathNote: note), at: 0)
        state.plants.removeAll { $0.id == plant.id }
        save()
    }

    func addNote(plantID: UUID, text: String) {
        guard let i = state.plants.firstIndex(where: { $0.id == plantID }) else { return }
        state.plants[i].notes.insert(PlantJournalNote(text: text), at: 0)
        save()
    }

    func updateNote(plantID: UUID, note: PlantJournalNote) {
        guard let i = state.plants.firstIndex(where: { $0.id == plantID }),
              let j = state.plants[i].notes.firstIndex(where: { $0.id == note.id }) else { return }
        var edited = note; edited.editedAt = Date()
        state.plants[i].notes[j] = edited
        save()
    }

    func deleteNote(plantID: UUID, noteID: UUID) {
        guard let i = state.plants.firstIndex(where: { $0.id == plantID }) else { return }
        state.plants[i].notes.removeAll { $0.id == noteID }
        save()
    }

    func upsertReminder(plantID: UUID, reminder: PlantReminder) async {
        guard let i = state.plants.firstIndex(where: { $0.id == plantID }) else { return }
        if let j = state.plants[i].reminders.firstIndex(where: { $0.id == reminder.id }) {
            state.plants[i].reminders[j] = reminder
        } else {
            state.plants[i].reminders.append(reminder)
        }
        save()
        if reminder.isEnabled && !reminder.isResolved {
            let plant = state.plants[i]
            await notificationService.schedule(reminder: reminder, plantName: plant.name)
            await eventKit.sync(reminder: reminder, plant: plant)
        } else {
            notificationService.cancel(reminderID: reminder.id)
        }
    }

    func deleteReminder(plantID: UUID, reminder: PlantReminder) async {
        guard let i = state.plants.firstIndex(where: { $0.id == plantID }) else { return }
        state.plants[i].reminders.removeAll { $0.id == reminder.id }
        save()
        notificationService.cancel(reminderID: reminder.id)
        await eventKit.deleteSynced(reminder: reminder)
    }

    func refreshWeather() async {
        guard !isRefreshingWeather else { return }
        isRefreshingWeather = true
        weatherError = nil
        defer { isRefreshingWeather = false }
        do {
            weather = try await weatherService.fetch(location: state.settings.location)
            alerts = MonitoringEngine.evaluate(plants: state.plants, weather: weather, waterEvents: state.waterEvents)
        } catch {
            weatherError = error.localizedDescription
        }
    }

    func seedDemoGarden() {
        guard state.plants.isEmpty else { return }
        state.plants = DemoGarden.plants
        state.settings.didSeedDemo = true
        save()
    }

    func replaceState(_ newState: AppState) {
        state = newState
        save()
    }
}

enum AppTab: String, CaseIterable, Identifiable {
    case today = "Today", plants = "Plants", calendar = "Calendar", water = "Water", more = "More"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .today: return "sun.max"
        case .plants: return "leaf"
        case .calendar: return "calendar"
        case .water: return "drop"
        case .more: return "ellipsis"
        }
    }
}

extension JSONEncoder {
    static var myg: JSONEncoder {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; e.outputFormatting = [.prettyPrinted, .sortedKeys]; return e
    }
}
extension JSONDecoder {
    static var myg: JSONDecoder { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }
}
