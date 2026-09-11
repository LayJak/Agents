import SwiftUI

struct WaterView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Water").font(.system(size: 44, weight: .bold))

                if let et0 = store.weather.dailyET0In {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Reference ET₀ today").foregroundStyle(.secondary)
                            Text(String(format: "%.2f in", et0)).font(.largeTitle.bold())
                            Text("Plant demand is adjusted from this value using each plant's coefficient and site conditions.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }

                ForEach(store.state.plants) { plant in
                    let capacity = MonitoringEngine.rootZoneCapacityIn(plant)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(plant.name).font(.headline)
                            Text("Estimated root-zone storage \(String(format: "%.2f", capacity)) in")
                                .foregroundStyle(.secondary)
                            if let et0 = store.weather.dailyET0In {
                                let demand = MonitoringEngine.plantDemandET0(plant, et0In: et0)
                                Text("Today's estimated demand \(String(format: "%.2f", demand)) in")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
    }
}
