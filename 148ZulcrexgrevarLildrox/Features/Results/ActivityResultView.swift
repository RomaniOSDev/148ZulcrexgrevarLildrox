import SwiftUI

struct ActivityResultView: View {
    let payload: ActivityResultPayload
    let onNextLevel: () -> Void
    let onRetry: () -> Void
    let onBackToLevels: () -> Void

    @State private var revealStars = 0
    @State private var bannerOffset: CGFloat = -200
    @State private var bannerOpacity: Double = 0

    private var canAdvance: Bool {
        payload.won && payload.levelIndex + 1 < GameConstants.levelsPerActivity
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppDesign.padding) {
                headerBlock

                starsSection

                metaBlock

                VStack(spacing: 14) {
                    Button(action: onNextLevel) {
                        Text("Next Level")
                            .font(.headline.weight(.semibold))
                            .appSingleLineTitle()
                            .foregroundStyle(canAdvance ? Color.appBackground : Color.appTextSecondary)
                            .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                            .background {
                                if canAdvance {
                                    AppChrome.primaryButtonPlate(cornerRadius: 16)
                                } else {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.appSurface.opacity(0.42))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(Color.appTextSecondary.opacity(0.14), lineWidth: 1)
                                        )
                                }
                            }
                    }
                    .disabled(!canAdvance)

                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.headline.weight(.semibold))
                            .appSingleLineTitle()
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                            .appSecondaryCTA(cornerRadius: 16)
                    }

                    Button(action: onBackToLevels) {
                        Text("Back to Levels")
                            .font(.headline.weight(.semibold))
                            .appSingleLineTitle()
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                            .background { AppChrome.depthCard(cornerRadius: 16, rimOpacity: 0.22) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .appScreenPadding()
        }
        .appRootBackdrop()
        .overlay(alignment: .top) {
            if !payload.newAchievements.isEmpty {
                achievementBanner
                    .padding(.top, AppDesign.padding)
                    .offset(y: bannerOffset)
                    .opacity(bannerOpacity)
            }
        }
        .onAppear {
            animateStars()
            animateBanner()
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(payload.won ? "Stage complete" : "Keep going")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
            Text(payload.won ? "Great rhythm on this layout." : "Adjust the plan and try again.")
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background { AppChrome.depthCard(cornerRadius: 22, rimOpacity: 0.38) }
    }

    private var metaBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Run details")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text("Time: \(Int(payload.duration))s")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
            Text("Difficulty: \(payload.difficulty.titleKey)")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .appSingleLineTitle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.28) }
    }

    private var starsSection: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                let filled = index < payload.stars
                StarGlyph(filled: filled, size: 36)
                    .shadow(color: filled ? Color.appAccent.opacity(0.9) : .clear, radius: filled ? 12 : 0)
                    .shadow(color: filled ? Color.appPrimary.opacity(0.45) : .clear, radius: filled ? 20 : 0)
                    .scaleEffect(revealStars > index ? 1 : 0.2)
                    .opacity(revealStars > index ? 1 : 0)
                    .animation(AppDesign.spring.delay(Double(index) * 0.15), value: revealStars)
                    .transition(.scale)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.32) }
        .accessibilityElement(children: .combine)
    }

    private var achievementBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New highlight unlocked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .appSingleLineTitle()
            ForEach(payload.newAchievements) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .appSingleLineTitle()
                    Text(item.detail)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppDesign.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.42) }
        .shadow(color: Color.appAccent.opacity(0.25), radius: 20, y: 12)
        .padding(.horizontal, AppDesign.padding)
    }

    private func animateStars() {
        revealStars = 0
        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(AppDesign.spring) {
                    revealStars = index + 1
                }
            }
        }
    }

    private func animateBanner() {
        guard !payload.newAchievements.isEmpty else { return }
        bannerOffset = -200
        bannerOpacity = 0
        withAnimation(.easeInOut(duration: 2)) {
            bannerOffset = 0
            bannerOpacity = 1
        }
    }
}
