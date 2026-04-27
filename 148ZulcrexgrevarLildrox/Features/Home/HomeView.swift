import SwiftUI

struct HomeView: View {
    @Binding var tabSelection: Int
    @EnvironmentObject private var appData: AppData
    @State private var heroPulse = false

    private var difficulty: DifficultyLevel {
        appData.selectedDifficulty
    }

    private var stats: GameStatistics {
        appData.statistics
    }

    private var progress: LevelProgressSnapshot {
        appData.levelProgress
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppDesign.padding) {
                    heroWidget
                    difficultyWidget
                    quickLinksRow
                    starsVaultWidget
                    activityTilesRow
                    sessionPulseWidget
                    highlightsWidget
                }
                .appScreenPadding()
            }
            .appRootBackdrop()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Overview")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .appSingleLineTitle()
                }
            }
        }
        .onAppear {
            withAnimation(AppDesign.easeInOut().repeatForever(autoreverses: true)) {
                heroPulse = true
            }
        }
    }

    private var heroWidget: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.95),
                            Color.appSurface.opacity(0.62),
                            Color.appPrimary.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(1)
                )
                .overlay(
                    HeroGlowShape()
                        .stroke(Color.appAccent.opacity(heroPulse ? 0.55 : 0.25), lineWidth: 2)
                        .animation(AppDesign.easeInOut(), value: heroPulse)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.4), Color.appPrimary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(alignment: .leading, spacing: 10) {
                Text("Session hub")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appSingleLineTitle()
                Text("Jump into activities, tune difficulty, and track highlights from one place.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    tabSelection = 1
                } label: {
                    Label("Open levels", systemImage: "square.grid.3x3.fill")
                        .font(.headline)
                        .appSingleLineTitle()
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                        .appPrimaryCTA(cornerRadius: 14)
                }
                .padding(.top, 4)
            }
            .padding(AppDesign.padding)
        }
        .frame(minHeight: 168)
        .shadow(color: Color.appPrimary.opacity(0.22), radius: 28, y: 16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }

    private var difficultyWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader(title: "Default difficulty", caption: "Used when you open the level grid.")
            Picker("Difficulty", selection: Binding(
                get: { appData.selectedDifficulty },
                set: { appData.selectedDifficulty = $0 }
            )) {
                ForEach(DifficultyLevel.allCases) { level in
                    Text(level.titleKey).tag(level)
                        .appSingleLineTitle()
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { widgetBackground }
    }

    private var quickLinksRow: some View {
        HStack(spacing: AppDesign.padding) {
            quickLinkButton(title: "Levels", systemImage: "square.grid.3x3.fill", tab: 1)
            quickLinkButton(title: "Awards", systemImage: "star.fill", tab: 2)
            quickLinkButton(title: "Stats", systemImage: "chart.bar.fill", tab: 3)
        }
    }

    private func quickLinkButton(title: String, systemImage: String, tab: Int) -> some View {
        Button {
            tabSelection = tab
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.appPrimary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appSingleLineTitle()
            }
            .frame(maxWidth: .infinity, minHeight: AppDesign.minTap + 8)
            .background { AppChrome.depthCard(cornerRadius: 16, rimOpacity: 0.32) }
        }
        .buttonStyle(.plain)
    }

    private var starsVaultWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            widgetHeader(title: "Star vault", caption: "Best stars for \(difficulty.titleKey) across all activities.")
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(ActivityKind.allCases) { activity in
                    starColumn(activity: activity, fill: starFillRatio(for: activity))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { widgetBackground }
    }

    private func starColumn(activity: ActivityKind, fill: CGFloat) -> some View {
        let total = totalStars(for: activity)
        return VStack(spacing: 6) {
            GeometryReader { geo in
                let h = max(4, geo.size.height * fill)
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.appSurface.opacity(0.45))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appPrimary],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: h)
                }
            }
            .frame(height: 96)
            Text(shortActivityLabel(activity))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .appSingleLineTitle()
            Text("\(total)/\(GameConstants.levelsPerActivity * 3)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
        }
        .frame(maxWidth: .infinity)
    }

    private func shortActivityLabel(_ activity: ActivityKind) -> String {
        switch activity {
        case .cascade: return "Cascade"
        case .totem: return "Totem"
        case .path: return "Path"
        }
    }

    private func totalStars(for activity: ActivityKind) -> Int {
        (0..<GameConstants.levelsPerActivity).reduce(0) { partial, idx in
            partial + progress.bestStars(activity: activity, difficulty: difficulty, levelIndex: idx)
        }
    }

    private func starFillRatio(for activity: ActivityKind) -> CGFloat {
        let cap = CGFloat(GameConstants.levelsPerActivity * 3)
        let value = CGFloat(totalStars(for: activity))
        return cap > 0 ? min(1, value / cap) : 0
    }

    private var activityTilesRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader(title: "Activity pulse", caption: "Tap a card to open the level list.")
            VStack(spacing: 10) {
                ForEach(ActivityKind.allCases) { activity in
                    activityRow(activity: activity)
                }
            }
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { widgetBackground }
    }

    private func activityRow(activity: ActivityKind) -> some View {
        let cleared = (0..<GameConstants.levelsPerActivity).filter { idx in
            progress.bestStars(activity: activity, difficulty: difficulty, levelIndex: idx) > 0
        }.count
        return Button {
            tabSelection = 1
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.appPrimary.opacity(0.22))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: iconName(for: activity))
                            .foregroundStyle(Color.appPrimary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .appSingleLineTitle()
                    Text("\(cleared)/\(GameConstants.levelsPerActivity) stages cleared")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .appSingleLineTitle()
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(minHeight: AppDesign.minTap)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appSurface.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func iconName(for activity: ActivityKind) -> String {
        switch activity {
        case .cascade: return "square.grid.3x3.fill"
        case .totem: return "square.stack.3d.up.fill"
        case .path: return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }

    private var sessionPulseWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            widgetHeader(title: "Session pulse", caption: "Live totals from your runs.")
            HStack(spacing: 0) {
                pulseCell(title: "Wins", value: "\(stats.cascadeWins + stats.totemWins + stats.pathWins)")
                pulseDivider
                pulseCell(title: "Runs", value: "\(stats.cascadeSessions + stats.totemSessions + stats.pathSessions)")
                pulseDivider
                pulseCell(title: "3★", value: "\(stats.threeStarFinishes)")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appSurface.opacity(0.45))
            )

            HStack(spacing: AppDesign.padding) {
                miniStat(title: "Cascade best", detail: formatCascadeBest())
                miniStat(title: "Totem height", detail: "\(stats.totemBestHeight)")
            }
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { widgetBackground }
    }

    private var pulseDivider: some View {
        Rectangle()
            .fill(Color.appAccent.opacity(0.25))
            .frame(width: 1, height: 40)
    }

    private func pulseCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .appSingleLineTitle()
        }
        .frame(maxWidth: .infinity)
    }

    private func miniStat(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .appSingleLineTitle()
            Text(detail)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.padding)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSurface.opacity(0.55))
        )
    }

    private func formatCascadeBest() -> String {
        guard let t = stats.cascadeBestTime else { return "—" }
        return "\(Int(t))s"
    }

    private var highlightsWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader(title: "Highlights", caption: "Badges unlocked through real play.")
            HStack {
                Text("\(appData.achievements.count) unlocked")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appSingleLineTitle()
                Spacer()
                Button("View all") {
                    tabSelection = 2
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            }
            if appData.achievements.isEmpty {
                Text("Finish a stage to start the collection.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(appData.achievements.prefix(4))) { item in
                            Text(item.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                                .appSingleLineTitle()
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.appSurface.opacity(0.85))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                                )
                                .shadow(color: Color.appPrimary.opacity(0.15), radius: 8, y: 4)
                        }
                    }
                }
            }
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { widgetBackground }
    }

    private func widgetHeader(title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
            Text(caption)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var widgetBackground: some View {
        AppChrome.depthCard(cornerRadius: 18, rimOpacity: 0.34)
    }
}

private struct HeroGlowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.insetBy(dx: 14, dy: 14)
        path.addRoundedRect(in: inset, cornerSize: CGSize(width: 18, height: 18), style: .continuous)
        return path
    }
}
