import SwiftUI

/// Nee — the Needgets mascot.
///
/// A small moon creature: a soft, slightly irregular circle whose body *is* its
/// head, with two stub arms, no legs, and a permanent float. Expression comes
/// entirely from eye shape and mouth curve, and a second expressive axis comes
/// from the moon phase, which ties the character to the app's lunar calendar.
///
/// ```swift
/// Nee(expression: .celebrating, phase: .full, accessory: .envelope)
///     .frame(width: 120)
/// ```
///
/// **Sizing.** Nee keeps a 120:138 ratio. Leave `width` unset and size it from
/// outside with `.frame(width:)`, or pass `width:` for a fixed size that does
/// not depend on the surrounding layout.
///
/// **Widgets.** WidgetKit renders static snapshots and cannot run the idle
/// float or blink loops, so pass `animated: false` in a widget to get a
/// correct still pose rather than a half-started animation:
///
/// ```swift
/// Nee(expression: .sleepy, phase: .crescent, animated: false, width: 44)
/// ```
///
/// Motion is also suppressed automatically when the system's Reduce Motion
/// setting is on.
public struct Nee: View {
    /// Which of the seven faces to wear.
    public var expression: NeeExpression
    /// How much of Nee is lit — full through waning crescent.
    public var phase: NeePhase
    /// An optional prop, held in a raised stub arm.
    public var accessory: NeeAccessory
    /// Overrides the arm pose. When `nil`, the pose follows the accessory and
    /// then the expression.
    public var arms: NeeArms?
    /// Whether the idle float, blink and effect loops run.
    public var animated: Bool
    /// A fixed width. When `nil`, Nee fills the width offered by its container.
    public var width: CGFloat?

    public init(
        expression: NeeExpression = .neutral,
        phase: NeePhase = .full,
        accessory: NeeAccessory = .none,
        arms: NeeArms? = nil,
        animated: Bool = true,
        width: CGFloat? = nil
    ) {
        self.expression = expression
        self.phase = phase
        self.accessory = accessory
        self.arms = arms
        self.animated = animated
        self.width = width
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the idle float and the ground shadow together, so the two stay
    /// locked to one another the way two CSS animations of equal duration do.
    @State private var isBobbing = false
    /// Vertical squash on the dot eyes. 1 when open.
    @State private var eyeScale: CGFloat = 1

    private var motionEnabled: Bool { animated && !reduceMotion }

    // MARK: Derived state

    /// An explicit pose wins; otherwise carrying something forces `hold`, and
    /// failing that the expression picks its own natural pose.
    private var resolvedArms: NeeArms {
        if let arms { return arms }
        if accessory != .none { return .hold }
        switch expression {
        case .encouraging: return .bothUp
        case .celebrating: return .wide
        case .happy:       return .oneUp
        default:           return .down
        }
    }

    /// Curious tilts its whole head.
    private var tiltDegrees: Double {
        expression == .curious ? 8 : 0
    }

    /// As Nee wanes, the face shrinks and slides left to stay on the lit part.
    private var faceScale: CGFloat {
        switch phase {
        case .crescent: return 0.52
        case .half:     return 0.8
        default:        return 1
        }
    }

    private var faceOffsetX: CGFloat {
        switch phase {
        case .crescent: return -30
        case .half:     return -13
        default:        return 0
        }
    }

    private var blinks: Bool {
        expression == .neutral || expression == .curious || expression == .thoughtful
    }

    private var armPair: (left: NeeArmPose.Arm, right: NeeArmPose.Arm) {
        NeeArmPose.arms(for: resolvedArms)
    }

    /// The outline fades to nothing toward the bottom-right, where light falls
    /// away. Mapped onto the body path's own bounding box, matching the source
    /// gradient's object-bounding-box coordinates.
    private var edgeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: NeePalette.outline.opacity(0.6), location: 0),
                .init(color: NeePalette.outline.opacity(0.46), location: 0.55),
                .init(color: NeePalette.outline.opacity(0), location: 1),
            ],
            startPoint: NeeMetrics.anchor(x: 12, y: 10),
            endPoint: NeeMetrics.anchor(x: 107, y: 102)
        )
    }

    // MARK: Body

    public var body: some View {
        Group {
            if let width {
                character.neeScaled(toWidth: width)
            } else {
                GeometryReader { proxy in
                    character.neeScaled(toWidth: proxy.size.width)
                }
                .aspectRatio(
                    NeeMetrics.box.width / NeeMetrics.box.height,
                    contentMode: .fit
                )
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Nee"))
        .onAppear {
            guard motionEnabled else { return }
            withAnimation(NeeAnimation.float) { isBobbing = true }
        }
        .task(id: blinkTaskID) { await runBlinkLoop() }
    }

    private var blinkTaskID: String {
        "\(expression.rawValue)-\(motionEnabled)"
    }

    /// Blinks at random intervals rather than on a fixed beat, so repeated
    /// instances of Nee on one screen never blink in unison.
    private func runBlinkLoop() async {
        guard motionEnabled, blinks else {
            eyeScale = 1
            return
        }
        let half = NeeAnimation.blinkDuration / 2
        while !Task.isCancelled {
            let wait = Double.random(in: NeeAnimation.blinkInterval)
            try? await Task.sleep(for: .seconds(wait))
            if Task.isCancelled { return }

            withAnimation(.easeInOut(duration: half)) {
                eyeScale = NeeAnimation.blinkSquash
            }
            try? await Task.sleep(for: .seconds(half))
            if Task.isCancelled { return }

            withAnimation(.easeInOut(duration: half)) {
                eyeScale = 1
            }
        }
    }

    // MARK: Assembly

    /// Layer order follows the source drawing exactly: the ground shadow sits
    /// outside both the tilt and the phase mask; the z, sparkles and accessory
    /// sit inside the tilt but outside the mask, so a waning Nee still shows
    /// what it is carrying.
    private var character: some View {
        ZStack {
            groundShadow

            ZStack {
                maskedCharacter

                if expression == .sleepy {
                    NeeSleepZ(animated: motionEnabled)
                }
                if expression == .celebrating {
                    NeeSparkles(animated: motionEnabled)
                }
                NeeAccessoryView(accessory: accessory)
            }
            .rotationEffect(
                .degrees(tiltDegrees),
                anchor: NeeMetrics.anchor(x: 60, y: 56)
            )
        }
        .frame(width: NeeMetrics.canvas.width, height: NeeMetrics.canvas.height)
        .offset(y: isBobbing ? NeeAnimation.floatRise : 0)
    }

    /// Always present, so Nee reads as floating rather than resting.
    private var groundShadow: some View {
        NeeGroundShadowShape()
            .fill(NeePalette.outline)
            .opacity(
                isBobbing
                    ? NeeAnimation.shadowOpacityAtPeak
                    : NeeAnimation.shadowOpacityAtRest
            )
            .scaleEffect(
                x: isBobbing ? NeeAnimation.shadowScaleAtPeak : 1,
                y: 1,
                anchor: NeeMetrics.anchor(x: 60, y: 124)
            )
            .blur(radius: NeeMetrics.blur(sigma: 8))
    }

    /// Arms, body, craters, outline and face — everything the moon phase eats into.
    private var maskedCharacter: some View {
        ZStack {
            stubArm(armPair.left)
            stubArm(armPair.right)

            NeeBodyShape().fill(NeePalette.cream)

            NeeCratersShape()
                .fill(NeePalette.outline)
                .opacity(0.06)
                .blur(radius: NeeMetrics.blur(sigma: 3.2))

            NeeBodyShape().stroke(edgeGradient, lineWidth: 2)

            NeeFace(expression: expression, eyeScale: eyeScale)
                .scaleEffect(faceScale, anchor: NeeMetrics.anchor(x: 60, y: 56))
                .offset(x: faceOffsetX)
        }
        .frame(width: NeeMetrics.canvas.width, height: NeeMetrics.canvas.height)
        .compositingGroup()
        .mask { NeePhaseMask(phase: phase) }
    }

    private func stubArm(_ pose: NeeArmPose.Arm) -> some View {
        ZStack {
            pose.shape.fill(NeePalette.cream)
            pose.shape.stroke(
                NeePalette.outline.opacity(pose.strokeOpacity),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Scaling

extension View {
    /// Scales artwork authored on the padded design canvas down to a layout box
    /// of the requested width, leaving the overflow visible rather than clipped.
    fileprivate func neeScaled(toWidth width: CGFloat) -> some View {
        frame(width: NeeMetrics.canvas.width, height: NeeMetrics.canvas.height)
            .scaleEffect(width / NeeMetrics.box.width)
            .frame(width: width, height: NeeMetrics.height(forWidth: width))
    }
}
