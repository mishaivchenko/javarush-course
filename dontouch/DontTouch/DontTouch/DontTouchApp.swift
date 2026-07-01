import SwiftUI

@main
struct DontTouchApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView {
                    withAnimation {
                        hasSeenOnboarding = true
                    }
                }
            }
        }
        .windowResizability(.contentSize)
    }
}
