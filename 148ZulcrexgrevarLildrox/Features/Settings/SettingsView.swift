import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Support & legal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Rate the app or open documents in your browser.")
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        settingsRow(
                            title: "Rate us",
                            subtitle: "Tell us what you think on the App Store",
                            systemImage: "star.fill",
                            tint: Color.appAccent
                        ) {
                            SettingsLinkLauncher.rateApp()
                        }

                        settingsRow(
                            title: "Privacy policy",
                            subtitle: "How data is handled",
                            systemImage: "hand.raised.fill",
                            tint: Color.appPrimary
                        ) {
                            SettingsLinkLauncher.open(.privacyPolicy)
                        }

                        settingsRow(
                            title: "Terms of use",
                            subtitle: "Conditions for using the app",
                            systemImage: "doc.text.fill",
                            tint: Color.appPrimary
                        ) {
                            SettingsLinkLauncher.open(.termsOfUse)
                        }
                    }
                }
                .appScreenPadding()
            }
            .appRootBackdrop()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func settingsRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.35), tint.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { AppChrome.depthCard(cornerRadius: 20, rimOpacity: 0.32) }
        }
        .buttonStyle(.plain)
    }
}
