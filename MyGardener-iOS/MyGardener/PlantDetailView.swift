import SwiftUI

struct PlantDetailView: View {
    @EnvironmentObject var store: AppStore
    let plantID: UUID
    @State private var showEdit = false
    @State private var showNote = false
    @State private var showReminder = false
    @State private var showDeath = false
    @State private var researching = false
    @State private var researchMessage: String?

    private var plant: Plant? { store.state.plants.first { $0.id == plantID } }

    var body: some View {
        Group {
            if let p = plant {
                ScrollView {
                    VStack(alignment:.leading,spacing:20) {
                        VStack(alignment:.leading,spacing:5){ Text(p.name).font(.largeTitle.bold()); if !p.scientificName.isEmpty {Text(p.scientificName).italic().foregroundStyle(.secondary)}; Text("\(p.placement.rawValue) · \(p.culture.rawValue) · monitoring since \(p.monitoringSince.shortDate)").font(.footnote).foregroundStyle(.secondary) }
                        HStack { Button("Edit details"){showEdit=true}.buttonStyle(.bordered); NavigationLink("Thrive Zone"){ThriveView(plant:p)}.buttonStyle(.bordered); Button(researching ? "Researching…" : "Research plant"){Task{await research(p)}}.buttonStyle(.borderedProminent).disabled(researching) }
                        if let researchMessage { Text(researchMessage).font(.footnote).foregroundStyle(.secondary) }
                        notesSection(p)
                        remindersSection(p)
                        siteSection(p)
                        if let r=p.profile { researchSections(r,p:p) }
                        destructiveSection(p)
                    }.padding()
                }
                .sheet(isPresented:$showEdit){NavigationStack{EditPlantView(plant:p)}}
                .sheet(isPresented:$showNote){NoteEditorView(plantID:p.id)}
                .sheet(isPresented:$showReminder){ReminderEditorView(plantID:p.id)}
                .sheet(isPresented:$showDeath){DeathView(plant:p)}
            } else { ContentUnavailableView("Plant not found", systemImage:"leaf") }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func notesSection(_ p:Plant)->some View { section("Plant notes") { VStack(spacing:10){ HStack{Text("Private dated notes for this plant.").font(.subheadline).foregroundStyle(.secondary);Spacer();Button("Add note"){showNote=true}}; if p.notes.isEmpty {empty("No notes yet.")} else {ForEach(p.notes){n in VStack(alignment:.leading,spacing:5){Text(n.text);Text(n.createdAt.shortDateTime).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18))}} } } }
    private func remindersSection(_ p:Plant)->some View { section("Custom reminders") { VStack(spacing:10){ HStack{Text("Exact native notifications and optional Apple Reminders/Calendar sync.").font(.subheadline).foregroundStyle(.secondary);Spacer();Button("Add reminder"){showReminder=true}}; if p.reminders.isEmpty {empty("No reminders scheduled.")} else {ForEach(p.reminders){r in HStack{VStack(alignment:.leading){Text(r.note).font(.headline);Text(r.dueDate.shortDateTime).font(.caption).foregroundStyle(.secondary)};Spacer();Image(systemName:r.isEnabled ? "bell.fill":"bell.slash").foregroundStyle(r.isEnabled ? .blue:.secondary)}.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18))}} } } }
    private func siteSection(_ p:Plant)->some View { section("Actual site") { row("Soil",p.site.soilTexture.rawValue);row("Drainage",p.site.drainage.rawValue);row("Exposure",p.site.exposure.rawValue);row("Thermal surroundings",p.site.thermalContext.rawValue);row("Wind",p.site.windExposure.rawValue);if p.culture == .container {row("Container",p.site.containerSize.rawValue)} } }
    @ViewBuilder private func researchSections(_ r:ResearchProfile,p:Plant)->some View {
        section("Climate & placement") { optionalRow("USDA hardiness", r.climate.usdaHardinessZoneMin.map{"\($0)–\(r.climate.usdaHardinessZoneMax ?? $0)"});optionalRow("AHS heat", r.climate.ahsHeatZoneMin.map{"\($0)–\(r.climate.ahsHeatZoneMax ?? $0)"});optionalRow("Protect below",r.climate.protectBelowF.map{"\(Int($0))°F"}); if !r.sun.preferredExposure.isEmpty {row("Preferred exposure",r.sun.preferredExposure.joined(separator:", "))} }
        section("Water") { optionalRow("Baseline weekly water",r.water.weeklyWaterInches.map{String(format:"%.2f in",$0)});optionalRow("ET₀ coefficient",r.water.referenceEtCoefficient.map{String(format:"%.2f",$0)});optionalRow("Drought tolerance",r.water.droughtTolerance);optionalRow("Waterlogging tolerance",r.water.waterloggingTolerance);optionalText(r.wateringNotes) }
        section("Care") { optionalRow("Fertilizer",r.care.fertilizerType);optionalRow("Frequency",r.care.fertilizerFrequency);optionalText(r.care.fertilizerNotes);optionalRow("Pruning",r.care.pruningMethod);optionalText(r.care.pruningNotes) }
        if !r.care.pests.isEmpty || !r.care.diseases.isEmpty { section("Pests & diseases") { ForEach(r.care.pests){item in pestCard(item,prefix:"Pest")};ForEach(r.care.diseases){item in pestCard(item,prefix:"Disease")} } }
        section("Local guidance") { optionalText(r.locationSummary);optionalText(r.summerNotes);optionalText(r.winterNotes);optionalText(r.microclimateNotes) }
        DisclosureGroup("Advanced research & model data") { VStack(alignment:.leading,spacing:8){ optionalRow("Research date",r.researchDate);optionalRow("Confidence",r.confidence); if let raw=r.rawJSON { Text(raw).font(.caption.monospaced()).textSelection(.enabled).foregroundStyle(.secondary) } } }.padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18))
    }
    private func destructiveSection(_ p:Plant)->some View { section("Plant lifecycle") { Button("Record plant death",role:.destructive){showDeath=true}; Button("Remove from collection",role:.destructive){store.removePlant(p)} } }
    private func pestCard(_ i:PestDiseaseItem,prefix:String)->some View { VStack(alignment:.leading,spacing:4){Text(i.name).font(.headline);Text([i.risk,i.season,i.regionalRelevance].filter{!$0.isEmpty}.joined(separator:" · ")).font(.caption).foregroundStyle(.secondary);if !i.monitorFor.isEmpty{Text("Monitor for: \(i.monitorFor)")}}.padding().frame(maxWidth:.infinity,alignment:.leading).background(.thinMaterial,in:RoundedRectangle(cornerRadius:16)) }
    private func section<C:View>(_ title:String,@ViewBuilder content:()->C)->some View { VStack(alignment:.leading,spacing:10){Text(title).font(.title3.bold());content()}.frame(maxWidth:.infinity,alignment:.leading) }
    private func row(_ k:String,_ v:String)->some View { HStack(alignment:.top){Text(k).foregroundStyle(.secondary);Spacer();Text(v).multilineTextAlignment(.trailing).bold()} }
    @ViewBuilder private func optionalRow(_ k:String,_ v:String?)->some View { if let v,!v.isEmpty{row(k,v)} }
    @ViewBuilder private func optionalText(_ t:String?)->some View { if let t,!t.isEmpty{Text(t).foregroundStyle(.secondary)} }
    private func empty(_ t:String)->some View { Text(t).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:18)) }
    private func research(_ p:Plant) async { researching=true;defer{researching=false};do{var x=p;x.profile=try await store.researchService.research(plant:p,location:store.state.settings.location);if x.scientificName.isEmpty{x.scientificName=x.profile?.scientificName ?? ""};store.updatePlant(x);researchMessage="Research updated."}catch{researchMessage=error.localizedDescription} }
}
