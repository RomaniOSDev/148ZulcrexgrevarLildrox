import SwiftUI

struct ContentView: View {
    @StateObject private var appData = AppData()

    var body: some View {
        Group {
            if appData.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environmentObject(appData)
    }
}

#Preview {
    ContentView()
}
