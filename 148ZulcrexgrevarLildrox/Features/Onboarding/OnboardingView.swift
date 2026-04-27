import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appData: AppData
    @State private var page = 0

    var body: some View {
        ZStack {
            AppChrome.rootBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Welcome")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .tracking(0.6)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                TabView(selection: $page) {
                    OnboardingHarmonyPage()
                        .tag(0)
                    OnboardingRhythmPage()
                        .tag(1)
                    OnboardingFocusPage()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 540)

                bottomChrome
            }
        }
    }

    private var bottomChrome: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(
                            index == page
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.appPrimary, Color.appAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color.appSurface.opacity(0.55))
                        )
                        .frame(width: index == page ? 32 : 9, height: 9)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.appAccent.opacity(index == page ? 0 : 0.2), lineWidth: 1)
                        )
                        .shadow(color: index == page ? Color.appPrimary.opacity(0.35) : .clear, radius: 8, y: 3)
                        .animation(AppDesign.spring, value: page)
                }
            }

            Button(action: advance) {
                HStack(spacing: 10) {
                    Text(page < 2 ? "Continue" : "Get started")
                        .font(.headline.weight(.semibold))
                    Image(systemName: page < 2 ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                }
                .appSingleLineTitle()
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .frame(minHeight: AppDesign.minTap)
                .appPrimaryCTA(cornerRadius: 18)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background { AppChrome.depthCard(cornerRadius: 26, rimOpacity: 0.36) }
        .padding(.horizontal, AppDesign.padding)
        .padding(.bottom, 20)
    }

    private func advance() {
        if page < 2 {
            withAnimation(AppDesign.spring) {
                page += 1
            }
        } else {
            appData.hasSeenOnboarding = true
        }
    }
}

// MARK: - Page shell

private struct OnboardingPageShell<Illustration: View>: View {
    let step: Int
    let title: String
    let subtitle: String
    @ViewBuilder let illustration: () -> Illustration

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                Text("STEP \(step) OF 3")
                    .font(.caption2.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.appAccent, Color.appPrimary], startPoint: .leading, endPoint: .trailing)
                    )
                Spacer(minLength: 0)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.appPrimary.opacity(0.8), Color.appAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .symbolRenderingMode(.hierarchical)
            }

            illustration()
                .frame(maxWidth: .infinity)
                .frame(height: 228)
                .padding(.vertical, 4)

            VStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background { AppChrome.depthCard(cornerRadius: 26, rimOpacity: 0.38) }
        .padding(.horizontal, AppDesign.padding)
    }
}

// MARK: - Pages

private struct OnboardingHarmonyPage: View {
    @State private var intro = false

    var body: some View {
        OnboardingPageShell(step: 1, title: "Dice harmony", subtitle: "Blend careful planning with the roll of the dice across focused challenges.") {
            HarmonyDiceIllustration()
                .scaleEffect(intro ? 1 : 0.86)
                .opacity(intro ? 1 : 0.5)
        }
        .onAppear {
            withAnimation(AppDesign.spring) {
                intro = true
            }
        }
    }
}

private struct OnboardingRhythmPage: View {
    @State private var wave = false
    @State private var intro = false

    var body: some View {
        OnboardingPageShell(step: 2, title: "Rhythmic flow", subtitle: "Each activity tunes timing, balance, and branching choices for a crisp mental workout.") {
            RhythmWaveIllustration(animate: wave)
                .scaleEffect(intro ? 1 : 0.86)
                .opacity(intro ? 1 : 0.5)
        }
        .onAppear {
            withAnimation(AppDesign.spring) {
                intro = true
            }
            withAnimation(AppDesign.easeInOut().repeatForever(autoreverses: true)) {
                wave = true
            }
        }
    }
}

private struct OnboardingFocusPage: View {
    @State private var glow = false
    @State private var intro = false

    var body: some View {
        OnboardingPageShell(step: 3, title: "Earn your stars", subtitle: "Stars unlock new levels and celebrate speed, accuracy, and smart branching.") {
            StarTrailIllustration(active: glow)
                .scaleEffect(intro ? 1 : 0.86)
                .opacity(intro ? 1 : 0.5)
        }
        .onAppear {
            withAnimation(AppDesign.spring) {
                intro = true
            }
            withAnimation(AppDesign.spring.repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Illustrations

private struct HarmonyDiceIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Color.appSurface.opacity(0.9), Color.appBackground.opacity(0.35)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 160
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.appPrimary.opacity(0.12), radius: 16, y: 8)

            Path { path in
                let w: CGFloat = 220
                let h: CGFloat = 200
                path.move(to: CGPoint(x: 20, y: h * 0.55))
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: 20), control: CGPoint(x: w * 0.2, y: h * 0.1))
                path.addQuadCurve(to: CGPoint(x: w - 20, y: h * 0.55), control: CGPoint(x: w * 0.82, y: h * 0.12))
                path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h - 20), control: CGPoint(x: w * 0.78, y: h * 0.9))
                path.addQuadCurve(to: CGPoint(x: 20, y: h * 0.55), control: CGPoint(x: w * 0.18, y: h * 0.88))
            }
            .stroke(
                LinearGradient(
                    colors: [Color.appAccent, Color.appPrimary.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 3.5, lineJoin: .round)
            )
            .shadow(color: Color.appAccent.opacity(0.25), radius: 8, y: 0)

            DiceFaceShape(value: 2, size: 72)
                .offset(x: -36, y: 10)
                .shadow(color: Color.appPrimary.opacity(0.25), radius: 12, y: 6)

            DiceFaceShape(value: 5, size: 72)
                .offset(x: 40, y: -16)
                .shadow(color: Color.appAccent.opacity(0.22), radius: 12, y: 6)
        }
    }
}

private struct RhythmWaveIllustration: View {
    var animate: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.55), Color.appBackground.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.appPrimary.opacity(0.15), lineWidth: 1)
                )

            Path { path in
                let width: CGFloat = 260
                let height: CGFloat = 200
                path.move(to: CGPoint(x: 0, y: height * 0.55))
                for step in stride(from: 0.0, through: 1.0, by: 0.05) {
                    let x = CGFloat(step) * width
                    let wave = sin((Double(step) * .pi * 4) + (animate ? .pi / 6 : 0)) * 24
                    let y = height * 0.55 + CGFloat(wave)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.appPrimary, Color.appAccent.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: Color.appPrimary.opacity(0.2), radius: 10, y: 4)
            .padding(.horizontal, 8)
        }
    }
}

private struct StarTrailIllustration: View {
    var active: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent.opacity(0.2), Color.clear],
                        center: UnitPoint(x: 0.55, y: 0.45),
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 200)

            ForEach(0..<4, id: \.self) { index in
                Path { path in
                    let size: CGFloat = 34 + CGFloat(index) * 10
                    let center = CGPoint(x: 140 + CGFloat(index) * 28, y: 110)
                    let points = 5
                    let outer = size * 0.45
                    let inner = size * 0.18
                    for starIndex in 0..<(points * 2) {
                        let radius = starIndex.isMultiple(of: 2) ? outer : inner
                        let angle = CGFloat(starIndex) * .pi / CGFloat(points) - .pi / 2
                        let point = CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        )
                        if starIndex == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appAccent.opacity(0.45 + Double(index) * 0.12),
                            Color.appPrimary.opacity(0.35 + Double(index) * 0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.appAccent.opacity(0.25), radius: active ? 6 + CGFloat(index) : 2, y: 2)
                .scaleEffect(active ? 1.05 : 0.9)
                .animation(AppDesign.spring.delay(Double(index) * 0.08), value: active)
            }
        }
    }
}
