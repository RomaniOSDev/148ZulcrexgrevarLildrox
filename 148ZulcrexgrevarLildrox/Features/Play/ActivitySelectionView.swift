import SwiftUI

struct ActivitySelectionView: View {
    @EnvironmentObject private var appData: AppData
    @State private var path = NavigationPath()
    @State private var resultPayload: ActivityResultPayload?
    @State private var selectedActivity: ActivityKind = .cascade

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 12) {
                        Picker("Activity", selection: $selectedActivity) {
                            ForEach(ActivityKind.allCases) { activity in
                                Text(activity.title)
                                    .tag(activity)
                                    .appSingleLineTitle()
                            }
                        }
                        .pickerStyle(.segmented)

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
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background { AppChrome.depthCard(cornerRadius: 18, rimOpacity: 0.28) }

                    levelRouteHero

                    if allLevelsCleared {
                        completionBanner
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your route")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Stages unlock in order. Chase three-star clears on every stop.")
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        ForEach(0..<GameConstants.levelsPerActivity, id: \.self) { index in
                            LevelStageRow(
                                activity: selectedActivity,
                                levelIndex: index,
                                unlocked: isUnlocked(index),
                                stars: stars(for: index),
                                isNextTarget: nextTargetLevelIndex == index,
                                isFirst: index == 0,
                                isLast: index == GameConstants.levelsPerActivity - 1,
                                onTap: {
                                    let session = GameSession(
                                        activity: selectedActivity,
                                        levelIndex: index,
                                        difficulty: appData.selectedDifficulty
                                    )
                                    path.append(session)
                                }
                            )
                        }
                    }
                }
                .appScreenPadding()
            }
            .appRootBackdrop()
            .navigationTitle("Levels")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: GameSession.self) { session in
                activityDestination(for: session)
            }
            .sheet(item: $resultPayload) { payload in
                ActivityResultView(
                    payload: payload,
                    onNextLevel: { handleNextLevel(from: payload) },
                    onRetry: { handleRetry(from: payload) },
                    onBackToLevels: { handleBackToLevels() }
                )
                .presentationDetents([.large])
            }
        }
    }

    private var allLevelsCleared: Bool {
        appData.levelProgress.allLevelsCleared(activity: selectedActivity, difficulty: appData.selectedDifficulty)
    }

    private var nextTargetLevelIndex: Int? {
        let p = appData.levelProgress
        let a = selectedActivity
        let d = appData.selectedDifficulty
        for i in 0..<GameConstants.levelsPerActivity {
            guard p.isUnlocked(activity: a, difficulty: d, levelIndex: i) else { return nil }
            if p.bestStars(activity: a, difficulty: d, levelIndex: i) < 3 {
                return i
            }
        }
        return nil
    }

    private var stagesClearedCount: Int {
        (0..<GameConstants.levelsPerActivity).filter { stars(for: $0) > 0 }.count
    }

    private var starTotal: Int {
        (0..<GameConstants.levelsPerActivity).reduce(0) { partial, idx in partial + stars(for: idx) }
    }

    private func isUnlocked(_ index: Int) -> Bool {
        appData.levelProgress.isUnlocked(
            activity: selectedActivity,
            difficulty: appData.selectedDifficulty,
            levelIndex: index
        )
    }

    private func stars(for index: Int) -> Int {
        appData.levelProgress.bestStars(
            activity: selectedActivity,
            difficulty: appData.selectedDifficulty,
            levelIndex: index
        )
    }

    private var levelRouteHero: some View {
        let (c1, c2) = selectedActivity.routeAccentPair
        return HStack(alignment: .center, spacing: 16) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [c1.opacity(0.35), c2.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: selectedActivity.routeIconName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appAccent.opacity(0.25), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedActivity.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appSingleLineTitle()
                Text(selectedActivity.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Label("\(stagesClearedCount)/\(GameConstants.levelsPerActivity) cleared", systemImage: "flag.checkered")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Label("\(starTotal)★", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(c2)
                }
                .labelStyle(.titleAndIcon)
                .symbolRenderingMode(.hierarchical)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background { AppChrome.depthCard(cornerRadius: 22, rimOpacity: 0.45) }
        .shadow(color: c1.opacity(0.2), radius: 22, y: 12)
    }

    private var completionBanner: some View {
        HStack(alignment: .center, spacing: AppDesign.padding) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color.appAccent, Color.appPrimary], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 4, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("Route complete")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .appSingleLineTitle()
                Text("Try another difficulty or activity for a new climb.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.4) }
        .shadow(color: Color.appAccent.opacity(0.18), radius: 18, y: 10)
    }

    @ViewBuilder
    private func activityDestination(for session: GameSession) -> some View {
        switch session.activity {
        case .cascade:
            DiceCascadeView(session: session) { payload in
                resultPayload = payload
            }
        case .totem:
            TotemTowerView(session: session) { payload in
                resultPayload = payload
            }
        case .path:
            PathOfChanceView(session: session) { payload in
                resultPayload = payload
            }
        }
    }

    private func handleNextLevel(from payload: ActivityResultPayload) {
        guard payload.won, payload.levelIndex + 1 < GameConstants.levelsPerActivity else {
            resultPayload = nil
            return
        }
        let next = GameSession(activity: payload.activity, levelIndex: payload.levelIndex + 1, difficulty: payload.difficulty)
        resultPayload = nil
        DispatchQueue.main.async {
            if !path.isEmpty {
                path.removeLast()
            }
            path.append(next)
        }
    }

    private func handleRetry(from payload: ActivityResultPayload) {
        let session = GameSession(activity: payload.activity, levelIndex: payload.levelIndex, difficulty: payload.difficulty)
        resultPayload = nil
        DispatchQueue.main.async {
            if !path.isEmpty {
                path.removeLast()
            }
            path.append(session)
        }
    }

    private func handleBackToLevels() {
        resultPayload = nil
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
