import SwiftUI

struct EditPlantView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State var plant: Plant

    var body: some View {
        Form {
            Section("Plant") {
                TextField("Name", text: $plant.name)
                TextField("Scientific name", text: $plant.scientificName)
                Picker("Placement", selection: $plant.placement) { ForEach(Placement.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Culture", selection: $plant.culture) { ForEach(Culture.allCases) { Text($0.rawValue).tag($0) } }
                DatePicker("Monitoring since", selection: $plant.monitoringSince, displayedComponents: .date)
                TextField("Image URL", text: $plant.imageURL)
            }
            Section("Actual site") {
                Picker("Soil", selection: $plant.site.soilTexture) { ForEach(SoilTexture.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Drainage", selection: $plant.site.drainage) { ForEach(Drainage.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Exposure", selection: $plant.site.exposure) { ForEach(MicroExposure.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Thermal surroundings", selection: $plant.site.thermalContext) { ForEach(ThermalContext.allCases) { Text($0.rawValue).tag($0) } }
                TextField("Orientation (N/E/S/W)", text: $plant.site.orientation)
                Picker("Wind", selection: $plant.site.windExposure) { ForEach(WindExposure.allCases) { Text($0.rawValue).tag($0) } }
                if plant.culture == .container {
                    Picker("Container size", selection: $plant.site.containerSize) { ForEach(ContainerSize.allCases) { Text($0.rawValue).tag($0) } }
                }
            }
        }
        .navigationTitle("Edit plant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { store.updatePlant(plant); dismiss() } }
        }
    }
}

struct NoteEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let plantID: UUID
    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form { Section("Plant note") { TextEditor(text: $text).frame(minHeight: 160) } }
                .navigationTitle("Add note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            store.addNote(plantID: plantID, text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                            dismiss()
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
    }
}

struct ReminderEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let plantID: UUID
    @State private var reminder = PlantReminder(note: "", dueDate: Date().addingTimeInterval(3600))

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Alert note", text: $reminder.note, axis: .vertical).lineLimit(3...6)
                    DatePicker("Date & time", selection: $reminder.dueDate)
                    Picker("Notify with", selection: $reminder.integration) {
                        ForEach(ReminderIntegration.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section {
                    Text("Plant Watch notifications require app notification permission. Apple Reminders or Calendar create a separate native item after you grant access to those apps.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Plant reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        Task {
                            await store.upsertReminder(plantID: plantID, reminder: reminder)
                            dismiss()
                        }
                    }
                    .disabled(reminder.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct DeathView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let plant: Plant
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Death date", selection: $date, displayedComponents: .date)
                TextField("Optional note", text: $note, axis: .vertical)
            }
            .navigationTitle("Record plant death")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", role: .destructive) {
                        store.recordDeath(plant, date: date, note: note)
                        dismiss()
                    }
                }
            }
        }
    }
}
