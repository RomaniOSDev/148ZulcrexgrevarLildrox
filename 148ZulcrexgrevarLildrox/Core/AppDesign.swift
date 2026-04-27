import SwiftUI

enum AppDesign {
    static let padding: CGFloat = 16
    static let minTap: CGFloat = 44
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static func easeInOut() -> Animation {
        Animation.easeInOut(duration: 0.3)
    }

    /// Shared card corner for elevated surfaces.
    static let cardCorner: CGFloat = 20
}

// MARK: - Depth, shadows, gradients (shared chrome)

enum AppChrome {
    /// Full-screen backdrop: base color + soft vignettes for depth.
    @ViewBuilder
    static func rootBackdrop() -> some View {
        ZStack {
            Color.appBackground
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.14),
                    Color.appBackground,
                    Color.appAccent.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.08), Color.clear],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            RadialGradient(
                colors: [Color.appAccent.opacity(0.06), Color.clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 360
            )
        }
    }

    /// Raised card: gradient fill, top gloss, rim light, stacked shadows.
    @ViewBuilder
    static func depthCard(cornerRadius: CGFloat = AppDesign.cardCorner, rimOpacity: Double = 0.38) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.88),
                            Color.appSurface.opacity(0.52),
                            Color.appSurface.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.55)
                    )
                )
                .padding(1)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(rimOpacity),
                            Color.appPrimary.opacity(0.14),
                            Color.appAccent.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.appPrimary.opacity(0.18), radius: 18, y: 12)
        .shadow(color: Color.black.opacity(0.14), radius: 6, y: 3)
    }

    /// Primary call-to-action plate (gradient + volume shadow).
    @ViewBuilder
    static func primaryButtonPlate(cornerRadius: CGFloat = 16) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.appPrimary, Color.appAccent.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    .padding(0.5)
            )
            .shadow(color: Color.appPrimary.opacity(0.45), radius: 16, y: 10)
            .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
    }

    /// Secondary / outline control with slight lift.
    @ViewBuilder
    static func secondaryButtonPlate(cornerRadius: CGFloat = 16) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.85), Color.appSurface.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: Color.appPrimary.opacity(0.1), radius: 10, y: 6)
        .shadow(color: Color.black.opacity(0.08), radius: 3, y: 2)
    }
}

extension View {
    func appScreenPadding() -> some View {
        padding(AppDesign.padding)
    }

    func appSingleLineTitle() -> some View {
        lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    /// Applies `AppChrome.rootBackdrop()` behind this view (safe area).
    func appRootBackdrop() -> some View {
        background {
            AppChrome.rootBackdrop()
                .ignoresSafeArea()
        }
    }

    /// Primary CTA styling: use on label that already has frame + foreground.
    func appPrimaryCTA(cornerRadius: CGFloat = 16) -> some View {
        background {
            AppChrome.primaryButtonPlate(cornerRadius: cornerRadius)
        }
    }

    /// Secondary filled / outlined control.
    func appSecondaryCTA(cornerRadius: CGFloat = 16) -> some View {
        background {
            AppChrome.secondaryButtonPlate(cornerRadius: cornerRadius)
        }
    }
}
