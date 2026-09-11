import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack { TodayView() }.tabItem { Label("Today", systemImage: "sun.max") }.tag(AppTab.today)
            NavigationStack { PlantsView() }.tabItem { Label("Plants", systemImage: "leaf") }.tag(AppTab.plants)
            NavigationStack { GardenCalendarView() }.tabItem { Label("Calendar", systemImage: "calendar") }.tag(AppTab.calendar)
            NavigationStack { WaterView() }.tabItem { Label("Water", systemImage: "drop") }.tag(AppTab.water)
            NavigationStack { MoreView() }.tabItem { Label("More", systemImage: "ellipsis") }.tag(AppTab.more)
        }
        .tint(.blue)
        .task { await store.refreshWeather() }
    }
}
