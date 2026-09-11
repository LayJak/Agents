import SwiftUI

@main
struct MyGardenerApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store) }
    }
}
