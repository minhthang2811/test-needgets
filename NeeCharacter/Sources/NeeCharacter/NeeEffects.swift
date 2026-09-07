import SwiftUI

// MARK: - Sleep

/// The single "z" that drifts up and away while Nee sleeps.
///
/// Positioned by its text baseline rather than by estimated font metrics: the
/// `.top` alignment guide is redefined to the first text baseline, so the glyph
/// lands exactly where the source SVG's `<text x="96" y="26">` puts it.
struct NeeSleepZ: View {
    let animated: Bool

    private struct Drift {
        var opacity: Double = 0
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var scale: CGFloat = 0.7
    }

    var body: some View {
        if animated {
            KeyframeAnimator(initialValue: Drift(), repeating: true) { drift in
                glyph
                    .scaleEffect(drift.scale)
                    .offset(x: drift.dx, y: drift.dy)
                    .opacity(drift.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    CubicKeyframe(0.65, duration: 1.0)
                    CubicKeyframe(0.0, duration: 3.0)
                }
                KeyframeTrack(\.dx) { LinearKeyframe(9, duration: 4.0) }
                KeyframeTrack(\.dy) { LinearKeyframe(-24, duration: 4.0) }
                KeyframeTrack(\.scale) { LinearKeyframe(1.05, duration: 4.0) }
            }
        } else {
            // A still frame needs a visible "z", so hold the pose the loop
            // reaches at its most legible moment rather than its empty start.
            glyph
                .scaleEffect(0.79)
                .offset(x: 2.25, y: -6)
                .opacity(0.65)
        }
    }

    private var glyph: some View {
        Text("z")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(NeePalette.outline.opacity(0.5))
            .alignmentGuide(.top) { $0[.firstTextBaseline] }
            .offset(x: 96 + NeeMetrics.bleed, y: 26 + NeeMetrics.bleed)
            .frame(
                width: NeeMetrics.canvas.width,
                height: NeeMetrics.canvas.height,
                alignment: .topLeading
            )
    }
}

// MARK: - Celebration

/// The four sparkles that scale up and dissolve when Nee celebrates. Soft and
/// blurred at the end, never hard confetti.
struct NeeSparkles: View {
    let animated: Bool

    /// Each sparkle as its centre, arm length, and start delay. All four share
    /// a 2.2s period and are phase-offset, matching the source's staggered
    /// `animation-delay`.
    private static let sparkles: [(center: CGPoint, arm: CGFloat, delay: Double)] = [
        (p(8, 24.5), 4.5, 0.0),
        (p(110, 20), 4.0, 0.5),
        (p(14, 107.5), 3.5, 1.0),
        (p(104, 103.5), 3.5, 1.5),
    ]

    private struct Twinkle {
        var opacity: Double = 0
        var scale: CGFloat = 0.35
        var blur: CGFloat = 0
    }

    var body: some View {
        ZStack {
            ForEach(Array(Self.sparkles.enumerated()), id: \.offset) { _, sparkle in
                let cross = crossShape(center: sparkle.center, arm: sparkle.arm)

                if animated {
                    NeeDelayedLoop(delay: sparkle.delay) {
                        KeyframeAnimator(initialValue: Twinkle(), repeating: true) { twinkle in
                            cross
                                .scaleEffect(
                                    twinkle.scale,
                                    anchor: NeeMetrics.anchor(x: sparkle.center.x, y: sparkle.center.y)
                                )
                                .blur(radius: twinkle.blur)
                                .opacity(twinkle.opacity)
                        } keyframes: { _ in
                            KeyframeTrack(\.opacity) {
                                CubicKeyframe(1.0, duration: 0.77)
                                CubicKeyframe(0.0, duration: 1.43)
                            }
                            KeyframeTrack(\.scale) {
                                CubicKeyframe(1.0, duration: 0.77)
                                CubicKeyframe(1.6, duration: 1.43)
                            }
                            KeyframeTrack(\.blur) {
                                CubicKeyframe(0.0, duration: 0.77)
                                CubicKeyframe(3.0, duration: 1.43)
                            }
                        }
                    }
                } else {
                    // Still frame: every sparkle at its brightest.
                    cross
                }
            }
        }
        .opacity(0.85)
    }

    private func crossShape(center: CGPoint, arm: CGFloat) -> some View {
        NeePath { path in
            path.move(to: p(center.x, center.y - arm))
            path.addLine(to: p(center.x, center.y + arm))
            path.move(to: p(center.x - arm, center.y))
            path.addLine(to: p(center.x + arm, center.y))
        }
        .roundStroke(NeePalette.accent, width: 2)
    }
}

// MARK: - Timing helpers

/// Mounts its content after a delay, so a repeating animation inside starts
/// phase-offset while keeping its own period — the SwiftUI equivalent of CSS
/// `animation-delay` on an infinite animation.
struct NeeDelayedLoop<Content: View>: View {
    let delay: Double
    let content: () -> Content

    @State private var started = false

    init(delay: Double, @ViewBuilder content: @escaping () -> Content) {
        self.delay = delay
        self.content = content
    }

    var body: some View {
        ZStack {
            if started {
                content()
            }
        }
        .task {
            guard delay > 0 else {
                started = true
                return
            }
            try? await Task.sleep(for: .seconds(delay))
            started = true
        }
    }
}

// MARK: - Nee's animation library

/// The reusable motion set the design specifies for Nee.
///
/// `float` and `shadow` share a period so they stay locked together; drive both
/// from a single piece of state.
public enum NeeAnimation {
    /// The base curve for Nee's idle motion, matching the source's
    /// `cubic-bezier(.45, 0, .55, 1)`.
    public static let idleCurve = Animation.timingCurve(0.45, 0, 0.55, 1, duration: 1.5)

    /// Continuous vertical bob: 6px amplitude over a 3s cycle, forever.
    public static let float = idleCurve.repeatForever(autoreverses: true)

    /// How far Nee rises at the top of the bob.
    public static let floatRise: CGFloat = -6

    /// The ground shadow tightens as Nee rises.
    public static let shadowScaleAtPeak: CGFloat = 0.96
    public static let shadowOpacityAtRest: Double = 0.12
    public static let shadowOpacityAtPeak: Double = 0.092

    /// Both eyes squash shut for 90ms, at random intervals in this range.
    public static let blinkInterval: ClosedRange<Double> = 4...8
    public static let blinkDuration: Double = 0.09
    public static let blinkSquash: CGFloat = 0.12

    /// Two quick hops with alternating 10° rotation.
    ///
    /// The design file defines this keyframe but does not attach it to any
    /// element, so it is offered here as opt-in rather than applied by default.
    /// Use `.neeHop(trigger:)` to run it.
    public static let hopDuration: Double = 0.9
}

private struct NeeHopModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content.keyframeAnimator(
            initialValue: HopState(),
            trigger: trigger
        ) { view, state in
            view
                .rotationEffect(.degrees(state.rotation))
                .offset(y: state.lift)
        } keyframes: { _ in
            KeyframeTrack(\.lift) {
                CubicKeyframe(-10, duration: 0.225)
                CubicKeyframe(0, duration: 0.225)
                CubicKeyframe(-8, duration: 0.225)
                CubicKeyframe(0, duration: 0.225)
            }
            KeyframeTrack(\.rotation) {
                CubicKeyframe(10, duration: 0.225)
                CubicKeyframe(0, duration: 0.225)
                CubicKeyframe(-10, duration: 0.225)
                CubicKeyframe(0, duration: 0.225)
            }
        }
    }

    struct HopState {
        var lift: CGFloat = 0
        var rotation: Double = 0
    }
}

extension View {
    /// Runs Nee's celebrate hop each time `trigger` changes.
    public func neeHop(trigger: Bool) -> some View {
        modifier(NeeHopModifier(trigger: trigger))
    }
}
