import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var appData: AppData

    private var earnedSet: Set<String> {
        Set(appData.achievements.map(\.rawValue))
    }

    private var orderedDefinitions: [AchievementDefinition] {
        AchievementDefinition.allCases.sorted { a, b in
            let ea = earnedSet.contains(a.rawValue)
            let eb = earnedSet.contains(b.rawValue)
            if ea != eb { return ea && !eb }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    private var totalCount: Int { AchievementDefinition.allCases.count }
    private var unlockedCount: Int { earnedSet.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                AchievementsHeroHeader(unlockedCount: unlockedCount, totalCount: totalCount)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Every highlight is earned from your sessions — nothing is bought or faked.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if unlockedCount == 0 {
                    emptyCollectionCallout
                }

                LazyVStack(spacing: 14) {
                    ForEach(orderedDefinitions) { def in
                        AchievementMedalCard(
                            definition: def,
                            unlocked: earnedSet.contains(def.rawValue)
                        )
                    }
                }
            }
            .appScreenPadding()
        }
        .appRootBackdrop()
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyCollectionCallout: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "star.leadinghalf.filled")
                .font(.title2)
                .foregroundStyle(Color.appAccent.opacity(0.85))
                .frame(width: 48, height: 48)
                .background { AppChrome.depthCard(cornerRadius: 14, rimOpacity: 0.3) }
            VStack(alignment: .leading, spacing: 4) {
                Text("Start the collection")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Win any stage once to unlock your first highlight, then chase the rest across all three activities.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.32) }
    }
}
