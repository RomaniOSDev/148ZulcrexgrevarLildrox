import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var appData: AppData
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView(tabSelection: $tab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ActivitySelectionView()
                .tabItem {
                    Label("Play", systemImage: "square.grid.3x3.fill")
                }
                .tag(1)

            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "star.fill")
            }
            .tag(2)

            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.bar.fill")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .tint(SwiftUI.Color.appPrimary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "AppSurface")
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
