import SwiftUI

/// The small props Nee carries. Each sits to Nee's right, held by the raised
/// stub arm — accessories are never worn.
///
/// All line work is 2px warm grey with round caps and joins, and each piece
/// stays within three colours plus Nee's cream, per the illustration system.
struct NeeAccessoryView: View {
    let accessory: NeeAccessory

    var body: some View {
        switch accessory {
        case .none:      EmptyView()
        case .hourglass: hourglass
        case .lantern:   lantern
        case .incense:   incense
        case .teacup:    teacup
        case .envelope:  envelope
        case .blossom:   blossom
        }
    }

    // MARK: Hourglass — for the 1440 concept

    private var hourglass: some View {
        ZStack {
            // Cap and base rails.
            NeePath { path in
                path.move(to: p(100, 64)); path.addLine(to: p(118, 64))
                path.move(to: p(100, 92)); path.addLine(to: p(118, 92))
            }
            .roundStroke(NeePalette.outline, width: 2)

            // Left wall of the glass, filled so the vessel reads as solid.
            let leftWall = NeePath { path in
                path.move(to: p(102, 64))
                path.curve(to: p(116, 78), p(102, 72), p(116, 74))
                path.curve(to: p(102, 92), p(116, 82), p(102, 84))
            }
            leftWall.fill(.white.opacity(0.5))
            leftWall.roundStroke(NeePalette.outline, width: 2)

            // Right wall — outline only.
            NeePath { path in
                path.move(to: p(116, 64))
                path.curve(to: p(102, 78), p(116, 72), p(102, 74))
                path.curve(to: p(116, 92), p(102, 82), p(116, 84))
            }
            .roundStroke(NeePalette.outline, width: 2)

            // Sand still to fall, and a single grain mid-drop.
            NeePath { path in
                path.move(to: p(103.5, 66))
                path.addLine(to: p(114.5, 66))
                path.addLine(to: p(109, 76))
                path.closeSubpath()
            }
            .fill(NeePalette.sand)

            NeePath { path in
                path.move(to: p(109, 80)); path.addLine(to: p(109, 85))
            }
            .roundStroke(NeePalette.sand, width: 2)
        }
    }

    // MARK: Folded paper lantern

    private var lantern: some View {
        ZStack {
            NeePath { path in
                path.move(to: p(108, 58)); path.addLine(to: p(108, 64))
            }
            .roundStroke(NeePalette.outline, width: 2)

            let body = NeeRoundedRect(x: 96, y: 64, width: 24, height: 26, radius: 7)
            body.fill(NeePalette.vermilion.opacity(0.85))
            body.roundStroke(NeePalette.outline, width: 2)

            // Centre rib.
            NeePath { path in
                path.move(to: p(108, 66)); path.addLine(to: p(108, 88))
            }
            .roundStroke(NeePalette.paper.opacity(0.5), width: 1.5)

            // Tassels.
            NeePath { path in
                path.move(to: p(104, 90)); path.addLine(to: p(104, 95))
                path.move(to: p(112, 90)); path.addLine(to: p(112, 95))
            }
            .roundStroke(NeePalette.gold, width: 2)
        }
    }

    // MARK: Incense stick with a wisp of smoke

    private var incense: some View {
        ZStack {
            NeePath { path in
                path.move(to: p(108, 94)); path.addLine(to: p(108, 64))
            }
            .roundStroke(NeePalette.outline, width: 2)

            // Smoke — two stacked S-curves, drawn faint.
            NeePath { path in
                path.move(to: p(108, 60))
                path.curve(to: p(108, 46), p(102, 55), p(114, 51))
                path.curve(to: p(108, 34), p(103, 42), p(112, 38))
            }
            .roundStroke(NeePalette.outline.opacity(0.35), width: 2)

            let holder = NeeEllipse(cx: 108, cy: 96, rx: 9, ry: 3.5)
            holder.fill(NeePalette.mint)
            holder.roundStroke(NeePalette.outline, width: 2)
        }
    }

    // MARK: Small ceramic teacup

    private var teacup: some View {
        ZStack {
            let bowl = NeePath { path in
                path.move(to: p(96, 72))
                path.addLine(to: p(118, 72))
                path.addLine(to: p(118, 81))
                path.addDownwardHalfEllipse(from: p(118, 81), to: p(96, 81), radiusY: 9)
                path.closeSubpath()
            }
            bowl.fill(NeePalette.mint.opacity(0.7))
            bowl.roundStroke(NeePalette.outline, width: 2)

            // Handle.
            NeePath { path in
                path.move(to: p(118, 74))
                path.curve(to: p(118, 81), p(124, 74), p(124, 81))
            }
            .roundStroke(NeePalette.outline, width: 2)

            // A curl of steam.
            NeePath { path in
                path.move(to: p(104, 64))
                path.curve(to: p(104, 54), p(100, 60), p(108, 58))
            }
            .roundStroke(NeePalette.outline.opacity(0.3), width: 2)
        }
    }

    // MARK: Red envelope — for the Fortune widget

    private var envelope: some View {
        ZStack {
            let body = NeeRoundedRect(x: 94, y: 62, width: 26, height: 34, radius: 6)
            body.fill(NeePalette.vermilion)
            body.roundStroke(NeePalette.outline, width: 2)

            let seal = NeeEllipse(cx: 107, cy: 79, r: 6)
            seal.fill(NeePalette.gold)
            seal.roundStroke(NeePalette.outline, width: 1.6)

            // Flap crease.
            NeePath { path in
                path.move(to: p(94, 72)); path.addLine(to: p(120, 72))
            }
            .roundStroke(NeePalette.outline.opacity(0.5), width: 1.6)
        }
    }

    // MARK: Apricot blossom branch — for Tết

    private var blossom: some View {
        ZStack {
            NeePath { path in
                path.move(to: p(98, 96))
                path.curve(to: p(112, 64), p(106, 88), p(110, 76))
            }
            .roundStroke(NeePalette.outline, width: 2)

            ForEach(Array(Self.flowers.enumerated()), id: \.offset) { _, flower in
                let petal = NeeEllipse(cx: flower.x, cy: flower.y, r: flower.r)
                ZStack {
                    petal.fill(NeePalette.sand)
                    petal.roundStroke(NeePalette.outline, width: 1.4)
                }
            }
        }
    }

    private static let flowers: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (113, 60, 4.5),
        (105, 72, 4),
        (117, 72, 3.4),
    ]
}
