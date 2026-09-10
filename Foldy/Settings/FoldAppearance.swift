import Foundation

enum FoldStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case silk
    case shade
    case frost

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var preset: FoldAppearance {
        switch self {
        case .silk:
            .silk
        case .shade:
            .shade
        case .frost:
            .frost
        }
    }
}

struct FoldAppearance: Equatable, Sendable {
    var style: FoldStyle
    var perspective: Double
    var variableBlur: Double
    var shadow: Double

    static let silk = FoldAppearance(style: .silk, perspective: 1, variableBlur: 0.65, shadow: 0.55)
    static let shade = FoldAppearance(style: .shade, perspective: 1, variableBlur: 0.28, shadow: 0.9)
    static let frost = FoldAppearance(style: .frost, perspective: 0.82, variableBlur: 0.9, shadow: 0.35)
}
