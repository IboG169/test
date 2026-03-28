import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let speed: Double
    let wobble: Double
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var animating = false
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.6)
                        .rotationEffect(.degrees(animating ? piece.rotation + 360 : piece.rotation))
                        .position(
                            x: piece.x + (animating ? CGFloat(piece.wobble) * 30 : 0),
                            y: animating ? geo.size.height + 50 : piece.y
                        )
                        .opacity(animating ? 0 : 1)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    startConfetti(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        let colors: [Color] = [
            Theme.accentBlue, Theme.gold, .green, .orange, .pink, .purple, .red, .yellow
        ]

        pieces = (0..<60).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...(-10)),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 2...4),
                wobble: Double.random(in: -1...1)
            )
        }

        withAnimation(.easeIn(duration: 3.0)) {
            animating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            pieces = []
            animating = false
        }
    }
}

struct ConfettiModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content.overlay(ConfettiView(isActive: isActive))
    }
}

extension View {
    func confetti(isActive: Bool) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }
}
