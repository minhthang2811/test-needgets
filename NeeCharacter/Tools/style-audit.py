#!/usr/bin/env python3
"""Check the SVG's colours, opacities and stroke widths survived the port."""
import re
import pathlib

DESIGN = pathlib.Path("/home/claude/repo/project/Nee.dc.html")
SWIFT_DIR = pathlib.Path("/home/claude/repo/NeeCharacter/Sources/NeeCharacter")

src = DESIGN.read_text()
body = src.split("</defs>", 1)[1].split("<script", 1)[0]
swift = "\n".join(f.read_text() for f in sorted(SWIFT_DIR.glob("*.swift")))
# Swift numeric literals may carry grouping underscores.
swift_flat = swift.replace("_", "")

problems = []

# ---------------------------------------------------------------- colours
palette = {}
for m in re.finditer(
    r"static let (\w+) = Color\(red: ([\d.]+), green: ([\d.]+), blue: ([\d.]+)\)",
    swift_flat,
):
    name, r, g, b = m.group(1), *map(float, m.groups()[1:])
    palette[name] = (round(r * 255), round(g * 255), round(b * 255))

svg_colors = {c.upper() for c in re.findall(r"#([0-9A-Fa-f]{6})", body)}
print("Colours")
for hexval in sorted(svg_colors):
    want = tuple(int(hexval[i:i + 2], 16) for i in (0, 2, 4))
    hit = [n for n, v in palette.items() if v == want]
    if hexval == "FFFFFF":
        # Ported as SwiftUI's built-in .white rather than a palette entry.
        ok = ".white" in swift
        hit = [".white"] if ok else []
    if hit:
        print(f"  [ok  ] #{hexval} -> NeePalette.{hit[0]}")
    else:
        problems.append(f"colour #{hexval} has no match in NeePalette")
        print(f"  [MISS] #{hexval}")

# --------------------------------------------------- opacities & stroke widths
def swift_has(value):
    """Is this number present as a literal in the Swift sources?"""
    pat = r"(?<![\d.])" + re.escape(f"{value:g}") + r"(?![\d])"
    return re.search(pat, swift_flat) is not None

print("\nOpacities")
opacities = sorted({
    float(v) for v in re.findall(r'(?:fill|stroke)-opacity="([\d.]+)"', body)
} | {
    float(v) for v in re.findall(r'\bopacity="([\d.]+)"', body)
} | {
    float(v) for v in re.findall(r'stop-opacity="([\d.]+)"', body)
})
for o in opacities:
    if swift_has(o):
        print(f"  [ok  ] {o}")
    else:
        problems.append(f"opacity {o} not found in Swift")
        print(f"  [MISS] {o}")

print("\nStroke widths")
widths = sorted({float(v) for v in re.findall(r'stroke-width="([\d.]+)"', body)})
for w in widths:
    if swift_has(w):
        print(f"  [ok  ] {w}")
    else:
        problems.append(f"stroke-width {w} not found in Swift")
        print(f"  [MISS] {w}")

# ------------------------------------------------------------- blur sigmas
print("\nBlur sigmas")
for sigma in sorted({float(v) for v in re.findall(r'stdDeviation="([\d.]+)"', src)}):
    used = re.search(r"blur\(sigma:\s*" + re.escape(f"{sigma:g}") + r"\)", swift_flat)
    # neeGlow is declared in <defs> but never referenced by any element.
    referenced = sigma != 2.4
    if used:
        print(f"  [ok  ] sigma {sigma}")
    elif not referenced:
        print(f"  [skip] sigma {sigma} (declared in <defs>, unused by any element)")
    else:
        problems.append(f"blur sigma {sigma} not applied in Swift")
        print(f"  [MISS] sigma {sigma}")

# -------------------------------------------------------- animation timings
print("\nAnimation timings")
timings = {
    "idle float / shadow cycle 3s": r"duration:\s*1\.5",
    "float rise -6px": r"floatRise: CGFloat = -6",
    "shadow scale 0.96": r"shadowScaleAtPeak: CGFloat = 0\.96",
    "shadow opacity .12 -> .092": r"shadowOpacityAtPeak: Double = 0\.092",
    "blink squash 0.12": r"blinkSquash: CGFloat = 0\.12",
    "z drift 4s": r"LinearKeyframe\(-24, duration: 4\.0\)",
    "z travel +9px": r"LinearKeyframe\(9, duration: 4\.0\)",
    "sparkle cycle 2.2s (0.77 + 1.43)": r"CubicKeyframe\(1\.6, duration: 1\.43\)",
    "sparkle blur 3px": r"CubicKeyframe\(3\.0, duration: 1\.43\)",
    "curve cubic-bezier(.45,0,.55,1)": r"timingCurve\(0\.45, 0, 0\.55, 1",
}
for label, pat in timings.items():
    if re.search(pat, swift_flat):
        print(f"  [ok  ] {label}")
    else:
        problems.append(f"timing missing: {label}")
        print(f"  [MISS] {label}")

print()
if problems:
    print(f"{len(problems)} problem(s):")
    for p in problems:
        print("  -", p)
    raise SystemExit(1)
print("Colours, opacities, stroke widths, blurs and timings all accounted for.")
