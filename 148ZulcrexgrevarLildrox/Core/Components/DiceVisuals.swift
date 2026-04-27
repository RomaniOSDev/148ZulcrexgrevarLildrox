import SwiftUI

struct DiceFaceShape: View {
    let value: Int
    var size: CGFloat = 52

    private var safeSize: CGFloat {
        let s = size
        if !s.isFinite || s <= 0 { return 52 }
        return min(240, max(8, s))
    }

    var body: some View {
        let s = safeSize
        let corner = s * 0.18
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface, Color.appSurface.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.75), Color.appPrimary.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.5, s * 0.035)
                        )
                )
                .shadow(color: Color.appPrimary.opacity(0.2), radius: s * 0.06, y: s * 0.04)
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(max(1, s * 0.04))
            pipLayout(safe: s)
        }
        .frame(width: s, height: s)
        .compositingGroup()
    }

    @ViewBuilder
    private func pipLayout(safe: CGFloat) -> some View {
        let dot = max(2, safe * 0.12)
        let inset = max(1, safe * 0.22)
        GeometryReader { geo in
            let w = max(0.1, geo.size.width)
            let h = max(0.1, geo.size.height)
            switch value {
            case 1:
                pip(dot, at: CGPoint(x: w / 2, y: h / 2))
            case 2:
                pip(dot, at: CGPoint(x: inset, y: h - inset))
                pip(dot, at: CGPoint(x: w - inset, y: inset))
            case 3:
                pip(dot, at: CGPoint(x: inset, y: h - inset))
                pip(dot, at: CGPoint(x: w / 2, y: h / 2))
                pip(dot, at: CGPoint(x: w - inset, y: inset))
            case 4:
                pip(dot, at: CGPoint(x: inset, y: inset))
                pip(dot, at: CGPoint(x: w - inset, y: inset))
                pip(dot, at: CGPoint(x: inset, y: h - inset))
                pip(dot, at: CGPoint(x: w - inset, y: h - inset))
            case 5:
                pip(dot, at: CGPoint(x: inset, y: inset))
                pip(dot, at: CGPoint(x: w - inset, y: inset))
                pip(dot, at: CGPoint(x: w / 2, y: h / 2))
                pip(dot, at: CGPoint(x: inset, y: h - inset))
                pip(dot, at: CGPoint(x: w - inset, y: h - inset))
            default:
                pip(dot, at: CGPoint(x: inset, y: inset))
                pip(dot, at: CGPoint(x: w - inset, y: inset))
                pip(dot, at: CGPoint(x: inset, y: h / 2))
                pip(dot, at: CGPoint(x: w - inset, y: h / 2))
                pip(dot, at: CGPoint(x: inset, y: h - inset))
                pip(dot, at: CGPoint(x: w - inset, y: h - inset))
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func pip(_ diameter: CGFloat, at point: CGPoint) -> some View {
        let d = max(1, min(diameter, 200))
        if d.isFinite, point.x.isFinite, point.y.isFinite {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appTextPrimary.opacity(0.95), Color.appTextPrimary.opacity(0.65)],
                        center: .center,
                        startRadius: 0,
                        endRadius: d * 0.6
                    )
                )
                .frame(width: d, height: d)
                .position(point)
        } else {
            EmptyView()
        }
    }
}

struct StarGlyph: View {
    var filled: Bool
    var size: CGFloat = 18

    private var safeSize: CGFloat {
        let s = size
        if !s.isFinite || s <= 0 { return 18 }
        return min(200, max(4, s))
    }

    var body: some View {
        let size = safeSize
        Path { path in
            let center = CGPoint(x: size / 2, y: size / 2)
            let points = 5
            let outer = size * 0.42
            let inner = size * 0.18
            for index in 0..<(points * 2) {
                let radius = index.isMultiple(of: 2) ? outer : inner
                let angle = CGFloat(index) * .pi / CGFloat(points) - .pi / 2
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
        .fill(filled ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
        .frame(width: size, height: size)
    }
}

struct LockGlyph: View {
    var size: CGFloat = 20

    private var safeSize: CGFloat {
        let s = size
        if !s.isFinite || s <= 0 { return 20 }
        return min(200, max(4, s))
    }

    var body: some View {
        let size = safeSize
        ZStack {
            Path { path in
                let w = size
                let h = size
                let shackleWidth = w * 0.55
                let shackleHeight = h * 0.35
                let origin = CGPoint(x: (w - shackleWidth) / 2, y: h * 0.12)
                path.addRoundedRect(
                    in: CGRect(x: origin.x, y: origin.y, width: shackleWidth, height: shackleHeight),
                    cornerSize: CGSize(width: shackleWidth / 2, height: shackleHeight)
                )
            }
            .stroke(Color.appTextSecondary, lineWidth: 2)

            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(Color.appTextSecondary.opacity(0.35))
                .frame(width: size * 0.62, height: size * 0.42)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}
