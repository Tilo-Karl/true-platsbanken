import SwiftUI

enum AppColors {
    static let brandBlue = Color(red: 0.12, green: 0.26, blue: 0.68)
    static let brandBlueDark = Color(red: 0.08, green: 0.20, blue: 0.56)
    static let brandAccent = Color(red: 0.69, green: 0.86, blue: 0.30)
    static let brandGreenDark = Color(red: 0.18, green: 0.60, blue: 0.22)
    static let brandGreen = brandAccent
    static let brandWhite = Color.white
    static let brandBlack = Color.black

    static let backgroundGradient = LinearGradient(
        colors: [brandBlueDark.opacity(0.18), brandWhite],
        startPoint: .top,
        endPoint: .bottom
    )

    static let glassBackground = brandWhite.opacity(0.85)
    static let cardStroke = brandWhite.opacity(0.5)
}
