import Foundation
import StoreKit
import UIKit

/// Central place for legal / policy URLs. Replace hosts with your production endpoints before release.
enum SettingsExternalURL {
    case privacyPolicy
    case termsOfUse

    var url: URL? {
        switch self {
        case .privacyPolicy:
            return URL(string: "https://zulcrexgrevarlildrox148.site/privacy/124")
        case .termsOfUse:
            return URL(string: "https://zulcrexgrevarlildrox148.site/terms/124")
        }
    }
}

enum SettingsLinkLauncher {
    static func open(_ kind: SettingsExternalURL) {
        if let url = kind.url {
            UIApplication.shared.open(url)
        }
    }

    static func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
