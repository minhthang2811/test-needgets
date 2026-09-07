import SwiftUI

// MARK: - Public API surface

/// Nee's seven expressions. Expression is carried entirely by eye shape and
/// mouth curve — Nee has no nose and no eyebrows, so the face stays redrawable
/// at any size.
public enum NeeExpression: String, CaseIterable, Sendable {
    case neutral, happy, curious, sleepy, encouraging, thoughtful, celebrating
}

/// Nee's moon phase — the second expressive axis. Full circle reads as present
/// and engaged; a waning crescent reads as calm, resting, night.
public enum NeePhase: String, CaseIterable, Sendable {
    case full, gibbous, half, crescent
}

/// Small props, held by a stub arm and never worn. One at a time.
public enum NeeAccessory: String, CaseIterable, Sendable {
    case none, hourglass, lantern, incense, teacup, envelope, blossom
}

/// Stub-arm poses. `hold` is not offered as an authoring choice in the design
/// file — it is selected automatically whenever Nee carries an accessory.
public enum NeeArms: String, CaseIterable, Sendable {
    case down, oneUp, bothUp, wide, hold
}

// MARK: - Palette

/// Every colour in the character, named. Nee's cream belongs to the character
/// alone and must never be used as a UI surface colour.
public enum NeePalette {
    /// Nee's body. Pale luminous cream.
    public static let cream = Color(red: 1.0, green: 0.964_7, blue: 0.898_0) // #FFF6E5
    /// Warm grey used for the outline, craters, ground shadow and accessory line work.
    public static let outline = Color(red: 0.239_2, green: 0.227_5, blue: 0.274_5) // #3D3A46
    /// Face ink. The darkest value in the character.
    public static let ink = Color(red: 0.164_7, green: 0.153_0, blue: 0.200_0) // #2A2733
    /// The one saturated UI colour, used here for celebration sparkles.
    public static let accent = Color(red: 0.419_6, green: 0.360_8, blue: 0.905_9) // #6B5CE7
    /// Hourglass sand, apricot blossom.
    public static let sand = Color(red: 0.909_8, green: 0.658_8, blue: 0.486_3) // #E8A87C
    /// Lantern paper, red envelope.
    public static let vermilion = Color(red: 0.878_4, green: 0.478_4, blue: 0.419_6) // #E07A6B
    /// Lantern flame, envelope seal.
    public static let gold = Color(red: 0.909_8, green: 0.690_2, blue: 0.294_1) // #E8B04B
    /// Incense holder, teacup.
    public static let mint = Color(red: 0.658_8, green: 0.862_7, blue: 0.784_3) // #A8DCC8
    /// Lantern rib highlight. The app canvas colour, used here as a light line.
    public static let paper = Color(red: 0.980_4, green: 0.972_5, blue: 0.960_8) // #FAF8F5
}

// MARK: - Metrics

/// The design-space geometry Nee is drawn in.
///
/// Every path in this package is expressed in the source SVG's 120 × 138 user
/// space, so coordinates can be read straight off the design file. The drawing
/// surface is padded by `bleed` on all sides because parts of Nee deliberately
/// spill outside the layout box — the `wide` arm pose reaches x = -3.5 and
/// x = 123.5, and accessories and sparkles cross both vertical edges. The
/// source SVG allows this with `overflow: visible`; here the padded canvas is
/// centred inside a smaller layout frame, which reproduces the same effect
/// without SwiftUI clipping anything.
public enum NeeMetrics {
    /// The layout box. Callers size Nee by width; height follows this ratio.
    public static let box = CGSize(width: 120, height: 138)

    /// Slack on every side so overflowing artwork is never clipped.
    public static let bleed: CGFloat = 16

    /// The real drawing surface: the layout box plus bleed on all four sides.
    public static let canvas = CGSize(
        width: box.width + bleed * 2,
        height: box.height + bleed * 2
    )

    /// Height for a given width, preserving the 120:138 ratio.
    public static func height(forWidth width: CGFloat) -> CGFloat {
        width * box.height / box.width
    }

    /// Converts a point in the SVG's 120 × 138 user space into a `UnitPoint`
    /// on the padded canvas, for use as a rotation or scale anchor.
    public static func anchor(x: CGFloat, y: CGFloat) -> UnitPoint {
        UnitPoint(
            x: (x + bleed) / canvas.width,
            y: (y + bleed) / canvas.height
        )
    }

    /// SVG `feGaussianBlur` is specified as a standard deviation; SwiftUI's
    /// `.blur(radius:)` is built on a box-blur approximation whose visible
    /// radius runs to roughly twice sigma. Converting here keeps the one
    /// approximate mapping in the port in a single named place — if the craters
    /// or the ground shadow read too soft or too tight on device, this is the
    /// number to nudge.
    ///
    /// The design brief independently calls for a ground shadow "blurred 16px",
    /// and the SVG uses `stdDeviation="8"`, so a factor of 2 reconciles both.
    public static func blur(sigma: CGFloat) -> CGFloat { sigma * 2 }
}

// MARK: - Design-space shapes

/// A shape authored directly in the source SVG's 120 × 138 user space.
///
/// Conformers implement `designPath()` using raw SVG coordinates; the
/// protocol shifts the result onto the padded canvas so every shape lines up
/// without each one repeating the offset.
protocol NeeDesignShape: Shape {
    func designPath() -> Path
}

extension NeeDesignShape {
    func path(in rect: CGRect) -> Path {
        designPath().offsetBy(dx: NeeMetrics.bleed, dy: NeeMetrics.bleed)
    }
}

// MARK: - Path helpers

extension Path {
    /// Appends an SVG-style cubic Bézier segment written with absolute control points.
    mutating func curve(
        to end: CGPoint,
        _ c1: CGPoint,
        _ c2: CGPoint
    ) {
        addCurve(to: end, control1: c1, control2: c2)
    }

    /// Appends a half-ellipse bulging downward, from `start` to `end`, matching
    /// the SVG arc `a rx,ry 0 0 1` used for the teacup bowl. The two endpoints
    /// are assumed to sit on the ellipse's horizontal axis, `2 * rx` apart.
    mutating func addDownwardHalfEllipse(
        from start: CGPoint,
        to end: CGPoint,
        radiusY: CGFloat
    ) {
        // Circular-arc-to-Bézier constant: the control-point offset that best
        // approximates a quarter arc.
        let k: CGFloat = 0.552_284_749_8
        let centerX = (start.x + end.x) / 2
        let radiusX = abs(start.x - end.x) / 2
        let baseY = start.y
        let bottom = CGPoint(x: centerX, y: baseY + radiusY)
        let direction: CGFloat = end.x < start.x ? -1 : 1

        addCurve(
            to: bottom,
            control1: CGPoint(x: start.x, y: baseY + radiusY * k),
            control2: CGPoint(x: centerX + radiusX * k * direction, y: bottom.y)
        )
        addCurve(
            to: end,
            control1: CGPoint(x: centerX - radiusX * k * direction, y: bottom.y),
            control2: CGPoint(x: end.x, y: baseY + radiusY * k)
        )
    }
}

/// Convenience for writing SVG coordinates inline without `CGPoint(x:y:)` noise.
@inline(__always)
func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
