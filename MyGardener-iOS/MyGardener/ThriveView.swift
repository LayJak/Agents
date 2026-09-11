import SwiftUI
import MapKit

struct ThriveView: View {
    @EnvironmentObject var store: AppStore
    let plant: Plant
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Text("\(plant.name) Thrive Zone").font(.largeTitle.bold())
                if let r = ThriveEngine.evaluate(plant: plant, location: store.state.settings.location) {
                    GlassCard { HStack { VStack(alignment:.leading,spacing:6){Text(r.code).font(.system(size:42,weight:.bold));Text(r.label).font(.title3.bold());Text("Primary constraint: \(r.limiter)").foregroundStyle(.secondary)};Spacer();ZStack{Circle().stroke(.yellow,lineWidth:5);Text(r.code).font(.title2.bold())}.frame(width:80,height:80)} }
                    Map(initialPosition:.region(.init(center:.init(latitude:store.state.settings.location.latitude,longitude:store.state.settings.location.longitude),span:.init(latitudeDelta:8,longitudeDelta:8)))) { Marker(store.state.settings.location.label,coordinate:.init(latitude:store.state.settings.location.latitude,longitude:store.state.settings.location.longitude)) }.frame(height:300).clipShape(RoundedRectangle(cornerRadius:26))
                    GlassCard { Text(r.summary) }
                    if r.seasonal { Text("S = seasonal/protected outdoor suitability. The plant's warm-season rating is shown separately from year-round winter survival.").font(.footnote).foregroundStyle(.secondary) }
                } else {
                    ContentUnavailableView("Native Thrive climate layer not available here yet",systemImage:"map",description:Text("The first native build includes the calibrated McKinney vector. The national PRISM/AHS raster should be bundled after device validation rather than approximated from live weather."))
                }
            }.padding()
        }
    }
}
