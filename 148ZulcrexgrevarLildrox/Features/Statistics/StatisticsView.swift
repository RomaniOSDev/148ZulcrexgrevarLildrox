import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject private var appData: AppData
    @State private var showResetConfirm = false

    private var stats: GameStatistics {
        appData.statistics
    }

    private var totalSessions: Int {
        stats.cascadeSessions + stats.totemSessions + stats.pathSessions
    }

    private var totalWins: Int {
        stats.cascadeWins + stats.totemWins + stats.pathWins
    }

    private var winRateText: String {
        guard totalSessions > 0 else { return "—" }
        let pct = Int((Double(totalWins) / Double(totalSessions) * 100).rounded())
        return "\(pct)%"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                statisticsHero

                Text("By activity")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                cascadeCard
                totemCard
                pathCard

                Text("Totals")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.top, 4)

                overallCard

                if isEmptySnapshot {
                    emptyCallout
                }

                resetSection
            }
            .appScreenPadding()
        }
        .appRootBackdrop()
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Reset all saved progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                AppData.performResetAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears highlights, stars, and activity history on this device.")
        }
    }

    private var isEmptySnapshot: Bool {
        totalSessions == 0
    }

    private var statisticsHero: some View {
        let (c1, c2) = (Color.appPrimary, Color.appAccent)
        return HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [c1.opacity(0.35), c2.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 44
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your footprint")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        heroChip(title: "Sessions", value: "\(totalSessions)", systemImage: "play.circle.fill")
                        heroChip(title: "Wins", value: "\(totalWins)", systemImage: "checkmark.seal.fill")
                        heroChip(title: "Win rate", value: winRateText, systemImage: "percent")
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background { AppChrome.depthCard(cornerRadius: 24, rimOpacity: 0.42) }
        .shadow(color: c1.opacity(0.16), radius: 20, y: 12)
    }

    private func heroChip(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .labelStyle(.titleAndIcon)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.subheadline.weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(Color.appTextPrimary)
                .appSingleLineTitle()
        }
    }

    private var cascadeCard: some View {
        activityCard(
            title: ActivityKind.cascade.title,
            icon: ActivityKind.cascade.routeIconName,
            accent: ActivityKind.cascade.routeAccentPair,
            rows: [
                ("play.fill", "Sessions", "\(stats.cascadeSessions)"),
                ("checkmark.circle.fill", "Wins", "\(stats.cascadeWins)"),
                ("stopwatch", "Best time", formatOptionalTime(stats.cascadeBestTime))
            ]
        )
    }

    private var totemCard: some View {
        activityCard(
            title: ActivityKind.totem.title,
            icon: ActivityKind.totem.routeIconName,
            accent: ActivityKind.totem.routeAccentPair,
            rows: [
                ("play.fill", "Sessions", "\(stats.totemSessions)"),
                ("checkmark.circle.fill", "Wins", "\(stats.totemWins)"),
                ("arrow.up.and.down.and.arrow.left.and.right", "Tallest stack", "\(stats.totemBestHeight)")
            ]
        )
    }

    private var pathCard: some View {
        activityCard(
            title: ActivityKind.path.title,
            icon: ActivityKind.path.routeIconName,
            accent: ActivityKind.path.routeAccentPair,
            rows: [
                ("play.fill", "Sessions", "\(stats.pathSessions)"),
                ("checkmark.circle.fill", "Wins", "\(stats.pathWins)"),
                ("dice.fill", "Fewest rolls (best)", formatOptionalRolls(stats.pathBestRolls))
            ]
        )
    }

    private var overallCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Color.appAccent, Color.appPrimary], startPoint: .top, endPoint: .bottom)
                    )
                Text("Across everything")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }
            statMetricRow(systemImage: "clock.fill", label: "Time in play", value: formatPlayDuration(stats.totalPlaySeconds))
            statMetricRow(systemImage: "star.fill", label: "Triple-star finishes", value: "\(stats.threeStarFinishes)")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 22, rimOpacity: 0.36) }
    }

    private func activityCard(
        title: String,
        icon: String,
        accent: (Color, Color),
        rows: [(String, String, String)]
    ) -> some View {
        let (c1, c2) = accent
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(colors: [c1.opacity(0.35), c2.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    )
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appSingleLineTitle()
                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    statMetricRow(systemImage: row.0, label: row.1, value: row.2)
                    if index < rows.count - 1 {
                        Divider()
                            .background(Color.appTextSecondary.opacity(0.15))
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 22, rimOpacity: 0.34) }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(colors: [c1.opacity(0.35), c2.opacity(0.1), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: c1.opacity(0.14), radius: 16, y: 10)
    }

    private func statMetricRow(systemImage: String, label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.appAccent.opacity(0.85))
                .frame(width: 26, alignment: .center)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var emptyCallout: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                .frame(width: 44, height: 44)
                .background { AppChrome.depthCard(cornerRadius: 12, rimOpacity: 0.22) }
            VStack(alignment: .leading, spacing: 4) {
                Text("Still quiet")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Run any stage once — this board will light up with sessions, wins, and personal bests.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.22) }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data on this device")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Reset all progress")
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .opacity(0.6)
                }
                .appSingleLineTitle()
                .foregroundStyle(Color.appTextPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: AppDesign.minTap)
                .appSecondaryCTA(cornerRadius: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private func formatOptionalTime(_ value: TimeInterval?) -> String {
        guard let value else { return "—" }
        return "\(Int(value))s"
    }

    private func formatOptionalRolls(_ value: Int?) -> String {
        guard let value else { return "—" }
        return "\(value)"
    }

    private func formatPlayDuration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        if s == 0 { return "0s" }
        if s < 60 { return "\(s)s" }
        let m = s / 60
        let rem = s % 60
        if m < 60 { return "\(m)m \(rem)s" }
        let h = m / 60
        let mm = m % 60
        return "\(h)h \(mm)m"
    }
}
