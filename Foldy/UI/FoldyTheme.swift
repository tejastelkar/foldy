import SwiftUI

enum FoldyTheme {
    static let blue = Color(red: 0.04, green: 0.52, blue: 1.0)
    static let cyan = Color(red: 0.39, green: 0.82, blue: 1.0)
    static let indigo = Color(red: 0.37, green: 0.36, blue: 0.90)
    static let mint = Color(red: 0.38, green: 0.92, blue: 0.80)

    static let duoGradient = LinearGradient(
        colors: [blue, cyan, indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
