# NeeCharacter

A SwiftUI port of `Nee.dc.html` — the Needgets mascot — as a reusable, WidgetKit-ready component.

Nee is a small moon creature whose body *is* its head: a soft, deliberately irregular circle in
pale cream, two stub arms, no legs, and a permanent float. Expression comes entirely from eye
shape and mouth curve, which is what keeps Nee redrawable from 44px inline up to 200px on the
splash screen.

```swift
import NeeCharacter

Nee(expression: .celebrating, phase: .full, accessory: .envelope)
    .frame(width: 120)
```

## API

| Parameter | Values | Default |
|---|---|---|
| `expression` | `.neutral` `.happy` `.curious` `.sleepy` `.encouraging` `.thoughtful` `.celebrating` | `.neutral` |
| `phase` | `.full` `.gibbous` `.half` `.crescent` | `.full` |
| `accessory` | `.none` `.hourglass` `.lantern` `.incense` `.teacup` `.envelope` `.blossom` | `.none` |
| `arms` | `.down` `.oneUp` `.bothUp` `.wide` `.hold`, or `nil` to derive | `nil` |
| `animated` | `Bool` | `true` |
| `width` | `CGFloat?` — `nil` fills the container | `nil` |

**Arms resolve in three steps**, matching the design file: an explicit `arms:` wins; otherwise
carrying an accessory forces `.hold`; otherwise the expression picks its own pose
(`encouraging` → `.bothUp`, `celebrating` → `.wide`, `happy` → `.oneUp`, everything else `.down`).

**Phase is not just a mask.** As Nee wanes, the face also shrinks and slides left to stay on the
lit crescent — 0.8× and −13pt at half, 0.52× and −30pt at crescent.

## Sizing

Nee keeps a 120:138 ratio. Either let the container drive it:

```swift
Nee(expression: .curious).frame(width: 96)
```

…or pass a fixed `width:` when you do not want the surrounding layout to have a say:

```swift
Nee(expression: .curious, width: 96)
```

Parts of Nee deliberately spill outside that box — the `wide` arm pose reaches past both vertical
edges, as do the accessories and sparkles. The source SVG allows this with `overflow: visible`;
here the artwork is drawn on a canvas padded by `NeeMetrics.bleed` and centred inside the smaller
layout frame, so nothing is clipped. Do not add `.clipped()`.

## Widgets

WidgetKit renders static snapshots and cannot run repeating animations. Pass `animated: false`
so Nee renders a deliberate still pose rather than whatever frame a stalled animation starts on —
this matters most for `.sleepy` and `.celebrating`, whose effects begin at zero opacity:

```swift
Nee(expression: .sleepy, phase: .crescent, animated: false, width: 44)
```

Motion is also suppressed automatically when Reduce Motion is enabled.

## Motion

`NeeAnimation` holds the reusable motion set. Idle float and the ground shadow are driven from a
single piece of state so they stay locked together, exactly as two CSS animations of equal
duration would be.

| | |
|---|---|
| Idle float | 6pt rise, 3s cycle, `cubic-bezier(0.45, 0, 0.55, 1)` |
| Ground shadow | scales to 0.96 and fades 0.12 → 0.092, in step with the float |
| Blink | 90ms squash to 0.12, at random 4–8s intervals |
| Sleep "z" | 4s drift up and right, fading in then out |
| Celebrate sparkles | 2.2s each, staggered 0/0.5/1/1.5s, dissolving with blur |

Blink intervals are randomised per instance, so several Nees on one screen never blink in unison.

`neeHop(trigger:)` is available but not applied by default — the design file defines the keyframe
but never attaches it to an element, so it is offered as opt-in rather than inferred.

## Fidelity notes

Three things could not be carried across exactly, all isolated behind named constants:

1. **Blur.** SVG specifies Gaussian blur as a standard deviation; SwiftUI's `.blur(radius:)` is a
   box-blur approximation. `NeeMetrics.blur(sigma:)` converts with a factor of 2, which also
   reconciles the design brief's "blurred 16px" ground shadow with the SVG's `stdDeviation="8"`.
   If the craters or shadow read too soft or too tight on device, that one function is the knob.

2. **The edge gradient.** SVG resolves gradient coordinates against the *path's* bounding box;
   SwiftUI resolves them against the *view's* frame. The start and end points are mapped through
   `NeeMetrics.anchor(x:y:)` onto the body path's real bounds so the fade lands in the same place.

3. **Baseline of the sleep "z".** Positioned by redefining the `.top` alignment guide to the text
   baseline, rather than by estimating font metrics, so it lands where `<text y="26">` puts it.

One faithful-to-source oddity worth flagging: the design file animates the **whole** drawing with
the float, ground shadow included, so the shadow rises with Nee rather than staying planted. The
character brief describes the shadow only scaling inversely. This port matches the design file,
since that is the artefact that was reviewed and approved — if you would rather have the brief's
behaviour, move the `.offset(y:)` in `Nee.character` inside the tilt group.

## Verification

SwiftUI does not exist on Linux, so this package was written without a compiler. Three checks were
run against the source design instead:

- **Geometry** — every `<path>`, `<ellipse>`, `<circle>` and `<rect>` parsed, relative commands
  converted to absolute, and each resulting coordinate matched against the Swift sources:
  **207 coordinates across 63 elements, exact to 1e-9.**
- **Logic** — the design file's actual `renderVals()` executed in Node and diffed against the
  Swift port's derived state across **980 prop combinations / 7,844 values: no mismatches.**
- **Style** — all 10 colours, 9 opacities, 6 stroke widths, both blur sigmas and 10 animation
  timings confirmed present.

The audit scripts live alongside this package's history; re-run them if the design file changes.

**Not yet verified:** it has never been compiled, and no pixel comparison against a rendered
reference has been done. Build it in Xcode and open `NeeGallery` — the character sheet renders all
seven expressions, four phases and six accessories on one page — before trusting it in a screen.
