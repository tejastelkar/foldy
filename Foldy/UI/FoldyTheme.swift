import SwiftUI

enum FoldyTheme {
    static let blue = Color.accentColor
    static let cyan = Color.cyan
    static let indigo = Color.indigo
    static let mint = Color(red: 0.18, green: 0.82, blue: 0.55)

    // Refined subtle glass sheen replacing generic neon gradient
    static let duoGradient = LinearGradient(
        colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
