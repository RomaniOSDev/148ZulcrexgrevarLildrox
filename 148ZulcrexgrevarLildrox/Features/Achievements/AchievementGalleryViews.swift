import SwiftUI

extension AchievementDefinition {
    var galleryIconName: String {
        switch self {
        case .firstWin: return "flag.checkered.circle.fill"
        case .cascadeMaster: return "square.grid.3x3.fill"
        case .totemBuilder: return "square.stack.3d.up.fill"
        case .pathNavigator: return "map.circle.fill"
        case .harmonyTriple: return "sparkles"
        case .allActivities: return "circle.hexagongrid.fill"
        }
    }

    /// Accent pair for medal chrome (distinct per award).
    var galleryAccentPair: (Color, Color) {
        switch self {
        case .firstWin: return (Color.appAccent, Color.appPrimary)
        case .cascadeMaster: return (Color.appPrimary, Color.appAccent.opacity(0.9))
        case .totemBuilder: return (Color.appAccent.opacity(0.95), Color.appPrimary.opacity(0.75))
        case .pathNavigator: return (Color.appPrimary.opacity(0.85), Color.appAccent)
        case .harmonyTriple: return (Color.appAccent, Color.appAccent.opacity(0.55))
        case .allActivities: return (Color.appPrimary, Color.appPrimary.opacity(0.55))
        }
    }
}

struct AchievementMedalCard: View {
    let definition: AchievementDefinition
    let unlocked: Bool

    private var accent: (Color, Color) { definition.galleryAccentPair }

    var body: some View {
        let (c1, c2) = accent
        return HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: unlocked
                                ? [c1.opacity(0.55), c2.opacity(0.2), Color.appSurface.opacity(0.3)]
                                : [Color.appSurface, Color.appSurface.opacity(0.4)],
                            center: .topLeading,
                            startRadius: 4,
                            endRadius: 42
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                unlocked
                                    ? AnyShapeStyle(LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(Color.appTextSecondary.opacity(0.22)),
                                lineWidth: unlocked ? 2 : 1
                            )
                    )
                    .overlay(
                        Image(systemName: definition.galleryIconName)
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(
                                unlocked
                                    ? AnyShapeStyle(LinearGradient(colors: [c1, c2], startPoint: .top, endPoint: .bottom))
                                    : AnyShapeStyle(Color.appTextSecondary.opacity(0.45))
                            )
                    )
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appBackground.opacity(0.9))
                        .padding(5)
                        .background(Circle().fill(Color.appTextSecondary.opacity(0.55)))
                        .offset(x: 20, y: -20)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(definition.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .appSingleLineTitle()
                    Spacer(minLength: 8)
                    if unlocked {
                        Text("Earned")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(Color.appBackground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [c1, c2], startPoint: .leading, endPoint: .trailing))
                            )
                            .shadow(color: c1.opacity(0.35), radius: 8, y: 4)
                    }
                }
                Text(definition.detail)
                    .font(.caption)
                    .foregroundStyle(unlocked ? Color.appTextSecondary : Color.appTextSecondary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background { AppChrome.depthCard(cornerRadius: 22, rimOpacity: unlocked ? 0.4 : 0.2) }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: unlocked
                            ? [c1.opacity(0.32), c2.opacity(0.12), Color.clear]
                            : [Color.appTextSecondary.opacity(0.1), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: unlocked ? c1.opacity(0.2) : Color.black.opacity(0.08), radius: unlocked ? 20 : 10, y: 10)
    }
}

struct AchievementsHeroHeader: View {
    let unlockedCount: Int
    let totalCount: Int

    private var ratio: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(unlockedCount) / CGFloat(totalCount)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.appSurface.opacity(0.6), lineWidth: 8)
                    .frame(width: 76, height: 76)
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(
                        AngularGradient(
                            colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.appAccent, Color.appPrimary], startPoint: .top, endPoint: .bottom)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Trophy case")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("\(unlockedCount) of \(totalCount) highlights unlocked")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
                if unlockedCount < totalCount {
                    Text("Keep playing — new seals appear as you hit real milestones.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("You have opened every highlight. Legendary run.")
                        .font(.caption)
                        .foregroundStyle(Color.appAccent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background { AppChrome.depthCard(cornerRadius: 24, rimOpacity: 0.4) }
        .shadow(color: Color.appPrimary.opacity(0.14), radius: 22, y: 12)
    }
}
