import SwiftUI

@main
struct WaterNowApp: App {
    @State private var iap = IAPManager()
    @State private var store = HydrationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(iap)
                .environment(store)
                .task { await iap.refresh() }
        }
    }
}
