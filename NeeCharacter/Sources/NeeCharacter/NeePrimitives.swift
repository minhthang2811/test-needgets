import SwiftUI

/// An inline shape authored in SVG user space, for one-off artwork that does
/// not warrant its own named type.
struct NeePath: NeeDesignShape {
    let build: (inout Path) -> Void

    init(_ build: @escaping (inout Path) -> Void) {
        self.build = build
    }

    func designPath() -> Path {
        var path = Path()
        build(&path)
        return path
    }
}

/// A rounded rectangle in SVG user space. Uses circular corners to match SVG's
/// `rx`, which draws elliptical arcs rather than SwiftUI's default squircle.
struct NeeRoundedRect: NeeDesignShape {
    let rect: CGRect
    let radius: CGFloat

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, radius: CGFloat) {
        self.rect = CGRect(x: x, y: y, width: width, height: height)
        self.radius = radius
    }

    func designPath() -> Path {
        Path(roundedRect: rect, cornerRadius: radius, style: .circular)
    }
}

/// An ellipse in SVG user space, given as centre and radii.
struct NeeEllipse: NeeDesignShape {
    let cx: CGFloat
    let cy: CGFloat
    let rx: CGFloat
    let ry: CGFloat

    init(cx: CGFloat, cy: CGFloat, r: CGFloat) {
        self.init(cx: cx, cy: cy, rx: r, ry: r)
    }

    init(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) {
        self.cx = cx
        self.cy = cy
        self.rx = rx
        self.ry = ry
    }

    func designPath() -> Path {
        Path(ellipseIn: CGRect(
            x: cx - rx, y: cy - ry,
            width: rx * 2, height: ry * 2
        ))
    }
}

extension Shape {
    /// Strokes with the round caps and joins the illustration system uses
    /// everywhere — no sharp corners anywhere in Nee's world.
    func roundStroke(_ color: Color, width: CGFloat) -> some View {
        stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }
}
