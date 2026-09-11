import SwiftUI

struct AddPlantView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var plant = Plant(name: "")
    var body: some View {
        Form {
            Section("Plant") {
                TextField("Common name", text:$plant.name)
                TextField("Scientific name (optional)", text:$plant.scientificName)
                Picker("Placement", selection:$plant.placement){ForEach(Placement.allCases){Text($0.rawValue).tag($0)}}
                Picker("Culture", selection:$plant.culture){ForEach(Culture.allCases){Text($0.rawValue).tag($0)}}
                DatePicker("Monitoring since", selection:$plant.monitoringSince, displayedComponents:.date)
            }
            Section("Actual site") {
                Picker("Soil", selection:$plant.site.soilTexture){ForEach(SoilTexture.allCases){Text($0.rawValue).tag($0)}}
                Picker("Drainage", selection:$plant.site.drainage){ForEach(Drainage.allCases){Text($0.rawValue).tag($0)}}
                Picker("Exposure", selection:$plant.site.exposure){ForEach(MicroExposure.allCases){Text($0.rawValue).tag($0)}}
                Picker("Thermal surroundings", selection:$plant.site.thermalContext){ForEach(ThermalContext.allCases){Text($0.rawValue).tag($0)}}
                Picker("Wind", selection:$plant.site.windExposure){ForEach(WindExposure.allCases){Text($0.rawValue).tag($0)}}
                if plant.culture == .container { Picker("Container size", selection:$plant.site.containerSize){ForEach(ContainerSize.allCases){Text($0.rawValue).tag($0)}} }
            }
        }
        .navigationTitle("Add plant").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement:.cancellationAction){Button("Cancel"){dismiss()}}; ToolbarItem(placement:.confirmationAction){Button("Add"){ store.addPlant(plant); dismiss() }.disabled(plant.name.trimmingCharacters(in:.whitespaces).isEmpty)} }
    }
}
