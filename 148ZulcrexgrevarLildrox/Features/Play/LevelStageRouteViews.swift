import SwiftUI

// MARK: - Activity styling

extension ActivityKind {
    var routeIconName: String {
        switch self {
        case .cascade: return "square.grid.3x3.fill"
        case .totem: return "square.stack.3d.up.fill"
        case .path: return "point.topleft.down.curvedto.point.bottomright.up"
        }
    }

    var routeAccentPair: (Color, Color) {
        switch self {
        case .cascade: return (Color.appPrimary, Color.appAccent)
        case .totem: return (Color.appAccent, Color.appPrimary)
        case .path: return (Color.appPrimary.opacity(0.85), Color.appAccent.opacity(0.95))
        }
    }
}

// MARK: - Timeline + cell

struct LevelStageRow: View {
    let activity: ActivityKind
    let levelIndex: Int
    let unlocked: Bool
    let stars: Int
    let isNextTarget: Bool
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void

    private var stageNumber: Int { levelIndex + 1 }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timelineRail
            LevelStageCard(
                activity: activity,
                stageNumber: stageNumber,
                unlocked: unlocked,
                stars: stars,
                isNextTarget: isNextTarget,
                onTap: onTap
            )
        }
    }

    private var timelineRail: some View {
        let (c1, c2) = activity.routeAccentPair
        return VStack(spacing: 0) {
            if !isFirst {
                LinearGradient(colors: [c1.opacity(0.35), c2.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    .frame(width: 3, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            } else {
                Color.clear.frame(width: 3, height: 6)
            }

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: unlocked ? [c1.opacity(0.5), c2.opacity(0.25)] : [Color.appSurface, Color.appSurface.opacity(0.4)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 22
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                unlocked
                                    ? AnyShapeStyle(LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(Color.appTextSecondary.opacity(0.28)),
                                lineWidth: unlocked ? 2 : 1
                            )
                    )

                if unlocked {
                    Text("\(stageNumber)")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color.appTextPrimary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            if !isLast {
                LinearGradient(colors: [c2.opacity(0.45), c1.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    .frame(width: 3, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            } else {
                Color.clear.frame(width: 3, height: 6)
            }
        }
        .frame(width: 44)
    }
}

struct LevelStageCard: View {
    let activity: ActivityKind
    let stageNumber: Int
    let unlocked: Bool
    let stars: Int
    let isNextTarget: Bool
    let onTap: () -> Void

    private var subtitle: String {
        if !unlocked {
            return "Clear the previous stage first"
        }
        if stars == 0 { return "Not cleared yet — tap to run" }
        if stars == 3 { return "Perfect run recorded" }
        return "Best: \(stars) of 3 stars — replay for more"
    }

    private var accentA: Color { activity.routeAccentPair.0 }
    private var accentB: Color { activity.routeAccentPair.1 }

    var body: some View {
        Button(action: {
            guard unlocked else { return }
            onTap()
        }) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.appSurface.opacity(0.55))

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentA.opacity(unlocked ? 0.22 : 0.06),
                                accentB.opacity(unlocked ? 0.12 : 0.04),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(accentA.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: activity.routeIconName)
                                    .font(.title3)
                                    .foregroundStyle(
                                        LinearGradient(colors: [accentA, accentB], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Stage \(stageNumber)")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .appSingleLineTitle()
                                if isNextTarget, unlocked {
                                    Text("NEXT")
                                        .font(.caption2.weight(.heavy))
                                        .foregroundStyle(Color.appBackground)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(LinearGradient(colors: [accentA, accentB], startPoint: .leading, endPoint: .trailing))
                                        )
                                        .shadow(color: accentA.opacity(0.4), radius: 8, y: 3)
                                }
                            }
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(Color.appTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 4)
                    }

                    starRail

                    HStack {
                        Spacer(minLength: 0)
                        if unlocked {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(accentB.opacity(0.85))
                        }
                    }
                }
                .padding(14)

                if stars == 3, unlocked {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appBackground)
                        .padding(6)
                        .background(Circle().fill(LinearGradient(colors: [accentA, accentB], startPoint: .top, endPoint: .bottom)))
                        .shadow(color: accentA.opacity(0.45), radius: 10, y: 4)
                        .offset(x: -6, y: 8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(unlocked ? 0.1 : 0.04), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: unlocked
                                ? [accentA.opacity(isNextTarget ? 0.75 : 0.45), accentB.opacity(0.35)]
                                : [Color.appTextSecondary.opacity(0.15), Color.appTextSecondary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: unlocked ? 1.5 : 1
                    )
            )
            .shadow(color: unlocked ? accentA.opacity(isNextTarget ? 0.35 : 0.18) : Color.black.opacity(0.08), radius: unlocked ? 22 : 12, y: 12)
            .shadow(color: Color.black.opacity(0.1), radius: 6, y: 4)
        }
        .buttonStyle(LevelStageButtonStyle(enabled: unlocked))
        .opacity(unlocked ? 1 : 0.62)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stage \(stageNumber), \(unlocked ? "unlocked" : "locked")")
    }

    private var starRail: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(i < stars ? AnyShapeStyle(LinearGradient(colors: [accentA, accentB], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(Color.appSurface.opacity(0.5)))
                    .frame(height: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color.appTextSecondary.opacity(0.12), lineWidth: 0.5)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LevelStageButtonStyle: ButtonStyle {
    let enabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && enabled ? 0.98 : 1)
            .animation(AppDesign.easeInOut(), value: configuration.isPressed)
    }
}
