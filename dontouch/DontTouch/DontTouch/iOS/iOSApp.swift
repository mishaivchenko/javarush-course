import SwiftUI

#if os(iOS)
@main
struct DontTouchApp_iOS: App {
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
    }
}
#endif
