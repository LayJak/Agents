import SwiftUI

struct PlantsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if store.state.plants.isEmpty {
                    GlassCard {
                        VStack(spacing: 14) {
                            Image(systemName: "leaf.circle").font(.system(size: 54)).foregroundStyle(.green)
                            Text("Your garden is empty").font(.title2.bold())
                            Text("Add your plants, or load the demo garden to test MyGardener immediately.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                            HStack { Button("Add plant") { showAdd = true }.buttonStyle(.borderedProminent); Button("Load demo") { store.seedDemoGarden() }.buttonStyle(.bordered) }
                        }.frame(maxWidth: .infinity)
                    }
                }
                ForEach(store.state.plants) { plant in
                    NavigationLink(value: plant.id) { PlantCard(plant: plant) }.buttonStyle(.plain)
                }
            }.padding()
        }
        .navigationTitle("Plants")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showAdd = true } label: { Image(systemName: "plus") } } }
        .navigationDestination(for: UUID.self) { id in if let p = store.state.plants.first(where:{$0.id==id}) { PlantDetailView(plantID:p.id) } }
        .sheet(isPresented: $showAdd) { NavigationStack { AddPlantView() } }
    }
}

struct PlantCard: View {
    let plant: Plant
    var body: some View {
        HStack(spacing: 14) {
            ZStack { RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.12)); Image(systemName: "leaf.fill").foregroundStyle(.green).font(.title2) }.frame(width:56,height:56)
            VStack(alignment:.leading,spacing:4){ Text(plant.name).font(.headline); if !plant.scientificName.isEmpty { Text(plant.scientificName).font(.subheadline).italic().foregroundStyle(.secondary) }; Text("\(plant.placement.rawValue) · \(plant.culture.rawValue)").font(.caption).foregroundStyle(.secondary) }
            Spacer(); Image(systemName:"chevron.right").foregroundStyle(.tertiary)
        }.padding(16).background(.regularMaterial,in:RoundedRectangle(cornerRadius:24,style:.continuous))
    }
}
