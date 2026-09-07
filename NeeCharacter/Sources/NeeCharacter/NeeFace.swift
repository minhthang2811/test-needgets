import SwiftUI

// MARK: - Eye geometry

/// Round dot eyes — the pair used by `neutral`, `curious` and `thoughtful`.
/// These are the only expressions that blink; the others have no open eye to close.
struct NeeDotEyesShape: NeeDesignShape {
    let expression: NeeExpression

    /// Left and right eye as (centre x, centre y, radius). `curious` is
    /// deliberately asymmetric — one eye slightly larger.
    private var eyes: [(x: CGFloat, y: CGFloat, r: CGFloat)] {
        switch expression {
        case .curious:    return [(46, 49, 5.2), (75, 49, 3.6)]
        case .thoughtful: return [(49, 46, 4), (77, 46, 4)]
        default:          return [(46, 49, 4), (74, 49, 4)]
        }
    }

    func designPath() -> Path {
        var path = Path()
        for e in eyes {
            path.addEllipse(in: CGRect(
                x: e.x - e.r, y: e.y - e.r,
                width: e.r * 2, height: e.r * 2
            ))
        }
        return path
    }
}

/// Arc eyes — happy and encouraging curve upward, sleepy curves downward into
/// half-lids.
struct NeeArcEyesShape: NeeDesignShape {
    let expression: NeeExpression

    /// Each arc as (start, control, end) in SVG user space.
    private var arcs: [(CGPoint, CGPoint, CGPoint)] {
        switch expression {
        case .happy:
            return [
                (p(41, 50), p(46, 43), p(51, 50)),
                (p(69, 50), p(74, 43), p(79, 50)),
            ]
        case .encouraging:
            return [
                (p(41, 51), p(46, 44.5), p(51, 51)),
                (p(69, 51), p(74, 44.5), p(79, 51)),
            ]
        case .sleepy:
            return [
                (p(40, 48), p(46, 53.5), p(52, 48)),
                (p(68, 48), p(74, 53.5), p(80, 48)),
            ]
        default:
            return []
        }
    }

    var lineWidth: CGFloat {
        expression == .sleepy ? 2.4 : 2.6
    }

    func designPath() -> Path {
        var path = Path()
        for (start, control, end) in arcs {
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        return path
    }
}

/// Star eyes, for celebrating. Eight-point outline traced from the source
/// SVG's relative line segments.
struct NeeStarEyesShape: NeeDesignShape {
    /// Offsets from each star's top point, walked in order and closed.
    private static let steps: [CGPoint] = [
        p(2.2, 5.1), p(5.1, 1.9), p(-5.1, 1.9), p(-2.2, 5.1),
        p(-2.2, -5.1), p(-5.1, -1.9), p(5.1, -1.9),
    ]

    private static let origins: [CGPoint] = [p(46, 42), p(74, 42)]

    func designPath() -> Path {
        var path = Path()
        for origin in Self.origins {
            path.move(to: origin)
            var cursor = origin
            for step in Self.steps {
                cursor = CGPoint(x: cursor.x + step.x, y: cursor.y + step.y)
                path.addLine(to: cursor)
            }
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Mouth geometry

/// The single-stroke mouths: a gentle curve for neutral, an asymmetric tick for
/// curious, and flat lines for sleepy and thoughtful.
struct NeeStrokedMouthShape: NeeDesignShape {
    let expression: NeeExpression

    func designPath() -> Path {
        var path = Path()
        switch expression {
        case .neutral:
            path.move(to: p(53, 66))
            path.addQuadCurve(to: p(67, 66), control: p(60, 69.5))
        case .curious:
            path.move(to: p(55, 66))
            path.addQuadCurve(to: p(64, 65), control: p(60, 70.5))
        case .sleepy:
            path.move(to: p(56, 66))
            path.addLine(to: p(64, 66))
        case .thoughtful:
            path.move(to: p(54, 67))
            path.addLine(to: p(65, 67))
        default:
            break
        }
        return path
    }
}

/// The open smiles — a filled wedge closed along the top lip.
struct NeeFilledMouthShape: NeeDesignShape {
    let expression: NeeExpression

    /// Each mouth as (left corner, control, right corner).
    private var wedge: (CGPoint, CGPoint, CGPoint)? {
        switch expression {
        case .happy:       return (p(52, 63), p(60, 74), p(68, 63))
        case .encouraging: return (p(53, 63), p(60, 72.5), p(67, 63))
        case .celebrating: return (p(51, 63), p(60, 75), p(69, 63))
        default:           return nil
        }
    }

    func designPath() -> Path {
        var path = Path()
        guard let (start, control, end) = wedge else { return path }
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        path.closeSubpath()
        return path
    }
}

// MARK: - Face

/// Nee's face: two eyes and a mouth, and nothing else. No nose, no eyebrows.
struct NeeFace: View {
    let expression: NeeExpression
    /// Vertical squash applied to dot eyes while blinking. 1 when open.
    let eyeScale: CGFloat

    /// The point the eyes squash toward, matching the source SVG's
    /// `transform-origin` for each blinking expression.
    private var blinkAnchor: UnitPoint {
        expression == .thoughtful
            ? NeeMetrics.anchor(x: 60, y: 46)
            : NeeMetrics.anchor(x: 60, y: 49)
    }

    private var hasDotEyes: Bool {
        expression == .neutral || expression == .curious || expression == .thoughtful
    }

    private var arcEyes: NeeArcEyesShape {
        NeeArcEyesShape(expression: expression)
    }

    var body: some View {
        ZStack {
            if hasDotEyes {
                NeeDotEyesShape(expression: expression)
                    .fill(NeePalette.ink)
                    .scaleEffect(x: 1, y: eyeScale, anchor: blinkAnchor)
            }

            if expression == .celebrating {
                NeeStarEyesShape()
                    .fill(NeePalette.ink)
            }

            arcEyes.stroke(
                NeePalette.ink,
                style: StrokeStyle(lineWidth: arcEyes.lineWidth, lineCap: .round)
            )

            NeeStrokedMouthShape(expression: expression)
                .stroke(
                    NeePalette.ink,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )

            NeeFilledMouthShape(expression: expression)
                .fill(NeePalette.ink)
        }
    }
}
