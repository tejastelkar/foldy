import SwiftUI

struct PreviewView: View {
    @State private var angle = 110.0
    var appearance: FoldAppearance = .silk
    private let mapper = FoldStateMapper()

    private var state: FoldState {
        mapper.state(for: angle, previousVisible: angle < 113)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fold Preview")
                    .font(.title2.bold())
                Text("Drag the angle to test the effect without closing your MacBook.")
                    .foregroundStyle(.secondary)
            }

            FoldMetalView(state: state, appearance: appearance)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .frame(width: 640, height: 400)

            HStack {
                Image(systemName: "laptopcomputer")
                Slider(value: $angle, in: 8...120)
                Text("\(angle, format: .number.precision(.fractionLength(0)))°")
                    .monospacedDigit()
                    .frame(width: 46, alignment: .trailing)
            }
        }
        .padding(24)
        .frame(minWidth: 688, minHeight: 500)
        .tint(FoldyTheme.blue)
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                FoldyTheme.duoGradient.opacity(0.07)
            }
        }
    }
}
