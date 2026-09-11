import Foundation

enum CalendarEngine {
    static func events(plants: [Plant], year: Int = Calendar.current.component(.year, from: Date())) -> [CalendarEvent] {
        plants.flatMap { events(for: $0, year: year) }.sorted { $0.start < $1.start }
    }

    static func events(for plant: Plant, year: Int) -> [CalendarEvent] {
        guard let s = plant.profile?.seasonal else { return [] }
        var out: [CalendarEvent] = []
        func add(_ kind: CalendarEvent.Kind, _ label: String, _ start: String?, _ end: String?, _ details: String = "") {
            guard let start, let end, let sd = date(mmdd: start, year: year) else { return }
            var endYear = year
            if let sm = Int(start.prefix(2)), let em = Int(end.prefix(2)), em < sm { endYear += 1 }
            guard let ed = date(mmdd: end, year: endYear) else { return }
            out.append(.init(id: "\(plant.id)-\(kind.rawValue)-\(start)-\(end)", plantID: plant.id, plantName: plant.name, kind: kind, title: label, start: sd, end: ed, details: details))
        }
        add(.seedSow, "Seed sow", s.directSowStart, s.directSowEnd)
        add(.transplant, "Transplant outside", s.transplantOutsideStart, s.transplantOutsideEnd)
        add(.flowering, "Blooming", s.floweringStart, s.floweringEnd)
        if plant.profile?.biology.harvestRelevant == true { add(.harvest, "Harvest", s.harvestStart, s.harvestEnd) }
        add(.pruning, "Prune / maintenance", s.pruneStart, s.pruneEnd, plant.profile?.care.pruningNotes ?? "")
        add(.fertilize, "Fertilize", s.fertilizeStart, s.fertilizeEnd, plant.profile?.care.fertilizerNotes ?? "")
        add(.moveProtect, "Move outside", s.moveOutsideStart, s.moveOutsideEnd)
        add(.moveProtect, "Move / protect", s.moveInsideStart, s.moveInsideEnd, plant.profile?.winterNotes ?? "")
        return out
    }

    static func visible(_ events: [CalendarEvent], mode: CalendarMode, date: Date) -> [CalendarEvent] {
        let cal = Calendar.current
        let interval: DateInterval
        switch mode {
        case .today:
            interval = DateInterval(start: cal.startOfDay(for: date), end: cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: date))!)
        case .week:
            interval = cal.dateInterval(of: .weekOfYear, for: date)!
        case .month:
            interval = cal.dateInterval(of: .month, for: date)!
        case .season:
            return events
        }
        return events.filter { $0.end >= interval.start && $0.start < interval.end }
    }

    private static func date(mmdd: String, year: Int) -> Date? {
        let parts = mmdd.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(from: DateComponents(year: year, month: parts[0], day: parts[1]))
    }
}

enum CalendarMode: String, CaseIterable, Identifiable { case today = "Today", week = "Week", month = "Month", season = "Season"; var id: String { rawValue } }
