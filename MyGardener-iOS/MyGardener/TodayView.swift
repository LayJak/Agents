import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack { VStack(alignment: .leading) { Text("Today").font(.system(size: 46, weight: .bold)); Text(store.state.settings.location.label).foregroundStyle(.secondary) }; Spacer(); Button { Task { await store.refreshWeather() } } label: { Image(systemName: "arrow.clockwise").font(.title2).padding(14).background(.thinMaterial, in: Circle()) } }
                hero
                if !store.alerts.isEmpty { sectionTitle("Priority alerts"); ForEach(store.alerts) { alert in alertCard(alert) } }
                sectionTitle("Hourly forecast")
                hourly
                sectionTitle("7-day outlook")
                daily
            }.padding()
        }.background(LinearGradient(colors: [Color.green.opacity(0.08), Color(uiColor: .systemGroupedBackground)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
    private var hero: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(Date().formatted(.dateTime.month(.wide).day().weekday())).textCase(.uppercase).font(.caption.bold()).foregroundStyle(.green)
                Text(store.weather.currentTemperatureF.map { "\(Int($0.rounded()))°" } ?? "—°").font(.system(size: 64, weight: .semibold))
                Text(store.state.settings.location.label).font(.title2.bold())
                HStack { MetricPill(title: "Today", value: highLow); MetricPill(title: "Rain", value: store.weather.dailyPrecipitationIn.map { String(format: "%.2f in", $0) } ?? "—") }
                HStack { MetricPill(title: "Humidity", value: store.weather.currentHumidity.map { "\(Int($0))%" } ?? "—"); MetricPill(title: "ET₀", value: store.weather.dailyET0In.map { String(format: "%.2f in", $0) } ?? "—") }
                if let e = store.weatherError { Text(e).font(.footnote).foregroundStyle(.red) }
            }
        }
    }
    private var highLow: String { guard let h=store.weather.dailyHighF, let l=store.weather.dailyLowF else { return "— / —" }; return "\(Int(h.rounded()))° / \(Int(l.rounded()))°" }
    private var hourly: some View { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(store.weather.hourly.prefix(18)) { h in VStack(spacing:8){ Text(h.time.formatted(.dateTime.hour())).font(.caption); Image(systemName:"sun.max"); Text(h.temperatureF.map{"\(Int($0))°"} ?? "—").bold() }.frame(width:68).padding(.vertical,12).background(.thinMaterial,in:RoundedRectangle(cornerRadius:18)) } } } }
    private var daily: some View { VStack { ForEach(store.weather.daily.prefix(7)) { d in HStack { Text(d.date.formatted(.dateTime.weekday(.abbreviated))).frame(width:50,alignment:.leading); Spacer(); Text(d.precipitationIn.map{String(format:"%.2f\"",$0)} ?? "").foregroundStyle(.blue); Spacer(); Text("\(d.highF.map{String(Int($0))} ?? "—")°  \(d.lowF.map{String(Int($0))} ?? "—")°") }.padding(.vertical,8); Divider() } } }
    private func sectionTitle(_ t:String)->some View { Text(t).font(.system(size:30,weight:.bold)) }
    private func alertCard(_ a: GardenAlert)->some View { GlassCard { VStack(alignment:.leading,spacing:6){ Text(a.title).font(.headline); Text(a.message).foregroundStyle(.secondary) } } }
}
