import SwiftUI

struct GardenCalendarView: View {
    @EnvironmentObject var store: AppStore
    @State private var mode: CalendarMode = .month
    @State private var selectedKind: CalendarEvent.Kind? = nil
    @State private var selectedEvent: CalendarEvent?

    private var allEvents: [CalendarEvent] { CalendarEngine.events(plants: store.state.plants) }
    private var filtered: [CalendarEvent] {
        let period = CalendarEngine.visible(allEvents, mode: mode, date: Date())
        return selectedKind == nil ? period : period.filter { $0.kind == selectedKind }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Range", selection: $mode) {
                    ForEach(CalendarMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterButton("All", nil)
                        ForEach(relevantKinds) { kind in
                            filterButton(kind.rawValue, kind)
                        }
                    }
                }

                if filtered.isEmpty {
                    ContentUnavailableView("No scheduled plant actions", systemImage: "calendar", description: Text("Try another period or event filter."))
                }

                ForEach(filtered) { event in
                    Button {
                        selectedEvent = event
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: event.kind.symbol)
                                .frame(width: 44, height: 44)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(event.title) · \(event.plantName)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(range(event)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .sheet(item: $selectedEvent) { event in
            NavigationStack { CalendarEventDetailView(event: event) }
        }
    }

    private var relevantKinds: [CalendarEvent.Kind] {
        CalendarEvent.Kind.allCases.filter { kind in allEvents.contains { $0.kind == kind } }
    }

    private func filterButton(_ text: String, _ kind: CalendarEvent.Kind?) -> some View {
        let isSelected = selectedKind == kind || (kind == nil && selectedKind == nil)
        return Button {
            selectedKind = kind
        } label: {
            Text(text)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.primary : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
                .foregroundStyle(isSelected ? Color(uiColor: .systemBackground) : .secondary)
        }
    }

    private func range(_ event: CalendarEvent) -> String {
        event.start == event.end ? event.start.shortDate : "\(event.start.shortDate) – \(event.end.shortDate)"
    }
}

struct CalendarEventDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let event: CalendarEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(event.title).font(.largeTitle.bold())
                Text(event.plantName).font(.title3)
                Label("\(event.start.shortDate) – \(event.end.shortDate)", systemImage: "calendar")
                    .foregroundStyle(.secondary)
                if !event.details.isEmpty { GlassCard { Text(event.details) } }
                if let plant = store.state.plants.first(where: { $0.id == event.plantID }) {
                    NavigationLink("View plant") { PlantDetailView(plantID: plant.id) }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
    }
}
