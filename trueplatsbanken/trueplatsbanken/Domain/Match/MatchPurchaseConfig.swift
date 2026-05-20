import Foundation

enum MatchPurchaseConfig {
    // StoreKit product for one paid CV-match run (consumable v1).
    static let productID = "com.tilodelau.jobtrek.cv_match.single_run"
    static let entitlementDays = 7

    // Used until StoreKit product metadata is loaded.
    static let fallbackDisplayPrice = "$1.99"
}
