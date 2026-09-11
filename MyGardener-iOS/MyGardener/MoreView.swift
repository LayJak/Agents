import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    @EnvironmentObject var store: AppStore
    @State private var apiKey = KeychainStore.get(ResearchService.keychainKey) ?? ""
    @State private var importPresented = false
    @State private var exportURL: URL?
    var body: some View {
        Form {
            Section("Location") {
                TextField("Label",text:Binding(get:{store.state.settings.location.label},set:{store.state.settings.location.label=$0;store.save()}))
                TextField("ZIP",text:Binding(get:{store.state.settings.location.zip},set:{store.state.settings.location.zip=$0;store.save()}))
                TextField("Latitude",value:Binding(get:{store.state.settings.location.latitude},set:{store.state.settings.location.latitude=$0;store.save()}),format:.number)
                TextField("Longitude",value:Binding(get:{store.state.settings.location.longitude},set:{store.state.settings.location.longitude=$0;store.save()}),format:.number)
                Button("Refresh weather") { Task { await store.refreshWeather() } }
            }
            Section("Plant research") {
                SecureField("Gemini API key",text:$apiKey)
                Button("Save API key") { if apiKey.isEmpty {KeychainStore.remove(ResearchService.keychainKey)} else {KeychainStore.set(apiKey,key:ResearchService.keychainKey)} }
                Text("Stored in the iOS Keychain, not the garden JSON file.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Data") {
                Button("Import garden JSON") { importPresented = true }
                Button("Prepare export") { exportURL = prepareExport() }
                if let exportURL { ShareLink(item: exportURL) { Label("Share garden backup",systemImage:"square.and.arrow.up") } }
                if store.state.plants.isEmpty { Button("Load demo garden") { store.seedDemoGarden() } }
            }
            if !store.state.plantHistory.isEmpty { Section("Plant history") { ForEach(store.state.plantHistory){h in VStack(alignment:.leading){Text(h.plant.name).font(.headline);Text("Died \(h.deathDate.shortDate)").font(.caption).foregroundStyle(.secondary);if !h.deathNote.isEmpty{Text(h.deathNote)}}} } }
            Section("Native build") { Text("SwiftUI conversion baseline · iOS 17+").foregroundStyle(.secondary);Text("Native notifications and EventKit integration are enabled. National Thrive raster rendering is intentionally not approximated in this first device-test build.").font(.footnote).foregroundStyle(.secondary) }
        }.navigationTitle("More").fileImporter(isPresented:$importPresented,allowedContentTypes:[.json]){result in if case .success(let url)=result { importState(url) }}
    }
    private func prepareExport()->URL?{let url=FileManager.default.temporaryDirectory.appendingPathComponent("MyGardener-Backup.json");guard let d=try? JSONEncoder.myg.encode(store.state)else{return nil};try? d.write(to:url);return url}
    private func importState(_ url:URL){guard url.startAccessingSecurityScopedResource() else{return};defer{url.stopAccessingSecurityScopedResource()};if let d=try? Data(contentsOf:url),let s=try? JSONDecoder.myg.decode(AppState.self,from:d){store.replaceState(s)}}
}
