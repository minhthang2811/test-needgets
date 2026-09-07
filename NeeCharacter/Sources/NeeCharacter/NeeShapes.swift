import SwiftUI

// MARK: - Body

/// Nee's silhouette: a soft, deliberately irregular circle — never a perfect
/// geometric one. Traced from the source SVG's single closed path.
struct NeeBodyShape: NeeDesignShape {
    func designPath() -> Path {
        var path = Path()
        path.move(to: p(60, 10))
        path.curve(to: p(107, 55), p(87, 10), p(106, 29))
        path.curve(to: p(60, 102), p(108, 81), p(87, 102))
        path.curve(to: p(12, 56), p(33, 102), p(12, 82))
        path.curve(to: p(60, 10), p(12, 30), p(33, 11))
        path.closeSubpath()
        return path
    }
}

/// The barely-visible crater texture: three soft circles, blurred and laid over
/// the cream at 6% opacity. Never hard-edged.
struct NeeCratersShape: NeeDesignShape {
    private static let craters: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (32, 32, 12),
        (90, 44, 8),
        (48, 88, 9.5),
    ]

    func designPath() -> Path {
        var path = Path()
        for c in Self.craters {
            path.addEllipse(in: CGRect(
                x: c.x - c.r, y: c.y - c.r,
                width: c.r * 2, height: c.r * 2
            ))
        }
        return path
    }
}

/// The elliptical ground shadow that keeps Nee reading as floating. Always
/// present, always soft.
struct NeeGroundShadowShape: NeeDesignShape {
    func designPath() -> Path {
        Path(ellipseIn: CGRect(x: 60 - 33, y: 124 - 6.5, width: 66, height: 13))
    }
}

// MARK: - Arms

/// One stub arm: an ellipse rotated about its own centre.
struct NeeArmShape: NeeDesignShape {
    let cx: CGFloat
    let cy: CGFloat
    let rx: CGFloat
    let ry: CGFloat
    let degrees: CGFloat

    func designPath() -> Path {
        let bounds = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
        let transform = CGAffineTransform(translationX: cx, y: cy)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -cx, y: -cy)
        return Path(ellipseIn: bounds).applying(transform)
    }
}

/// Geometry for the five arm poses.
///
/// The right arm carries a lighter outline than the left throughout — light
/// falls away toward the bottom-right of the character, so the stroke thins on
/// that side.
enum NeeArmPose {
    struct Arm {
        let shape: NeeArmShape
        let strokeOpacity: Double
    }

    static func arms(for pose: NeeArms) -> (left: Arm, right: Arm) {
        switch pose {
        case .down:
            return (
                Arm(shape: NeeArmShape(cx: 21, cy: 86, rx: 7.5, ry: 10, degrees: -32), strokeOpacity: 0.42),
                Arm(shape: NeeArmShape(cx: 99, cy: 86, rx: 7.5, ry: 10, degrees: 32), strokeOpacity: 0.26)
            )
        case .hold:
            return (
                Arm(shape: NeeArmShape(cx: 21, cy: 86, rx: 7.5, ry: 10, degrees: -32), strokeOpacity: 0.42),
                Arm(shape: NeeArmShape(cx: 99, cy: 72, rx: 7.5, ry: 10, degrees: 52), strokeOpacity: 0.26)
            )
        case .oneUp:
            return (
                Arm(shape: NeeArmShape(cx: 17, cy: 88, rx: 7.5, ry: 10, degrees: -32), strokeOpacity: 0.42),
                Arm(shape: NeeArmShape(cx: 104, cy: 28, rx: 7.5, ry: 10.5, degrees: -34), strokeOpacity: 0.30)
            )
        case .bothUp:
            return (
                Arm(shape: NeeArmShape(cx: 16, cy: 28, rx: 7.5, ry: 10.5, degrees: 34), strokeOpacity: 0.42),
                Arm(shape: NeeArmShape(cx: 104, cy: 28, rx: 7.5, ry: 10.5, degrees: -34), strokeOpacity: 0.30)
            )
        case .wide:
            return (
                Arm(shape: NeeArmShape(cx: 7, cy: 62, rx: 10.5, ry: 7.5, degrees: -10), strokeOpacity: 0.42),
                Arm(shape: NeeArmShape(cx: 113, cy: 62, rx: 10.5, ry: 7.5, degrees: 10), strokeOpacity: 0.26)
            )
        }
    }
}

// MARK: - Phase mask

/// The moon-phase mask.
///
/// Built as an oversized rectangle with the shadowed region punched out of it.
/// **Must be filled with `FillStyle(eoFill: true)`** for the punch-out to
/// register — see `NeePhaseMask`, which does this.
struct NeePhaseMaskShape: NeeDesignShape {
    let phase: NeePhase

    func designPath() -> Path {
        var path = Path()
        // Generously larger than the canvas so the mask never trims the arms.
        path.addRect(CGRect(x: -12, y: -12, width: 150, height: 170))

        switch phase {
        case .full:
            break // Nothing removed — Nee is whole.
        case .gibbous:
            path.addEllipse(in: CGRect(x: 120 - 47, y: 56 - 47, width: 94, height: 94))
        case .half:
            path.addRect(CGRect(x: 60, y: -12, width: 80, height: 170))
        case .crescent:
            path.addEllipse(in: CGRect(x: 82 - 48, y: 54 - 48, width: 96, height: 96))
        }
        return path
    }
}

/// The phase mask as a ready-to-use view, filled with the even-odd rule so the
/// punched-out region reads as absent rather than doubled.
struct NeePhaseMask: View {
    let phase: NeePhase

    var body: some View {
        NeePhaseMaskShape(phase: phase)
            .fill(style: FillStyle(eoFill: true))
    }
}
