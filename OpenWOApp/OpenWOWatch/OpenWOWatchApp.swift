import SwiftUI
import WatchConnectivity

@main
struct OpenWOWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager()

    var body: some Scene {
        WindowGroup {
            WorkoutSessionView()
                .environmentObject(sessionManager)
        }
    }
}
