#!/usr/bin/env python3
"""Audit the SwiftUI port of Nee.dc.html against the source SVG geometry.

Parses every <path>/<ellipse>/<circle>/<rect> in the design file, converts all
relative path commands to absolute coordinates, then checks that each resulting
point exists in the Swift sources.  Relative->absolute conversion is exactly
where a hand transcription goes wrong, so this is the check that matters.
"""
import re
import sys
import pathlib

DESIGN = pathlib.Path("/home/claude/repo/project/Nee.dc.html")
SWIFT_DIR = pathlib.Path("/home/claude/repo/NeeCharacter/Sources/NeeCharacter")
TOL = 1e-9

NUM = r"[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?"


def nums(s):
    return [float(x) for x in re.findall(NUM, s)]


# ---------------------------------------------------------------- SVG parsing

def parse_path(d):
    """Return the absolute points (anchors AND control points) of a path."""
    tokens = re.findall(r"([MmLlHhVvCcSsQqTtAaZz])|(" + NUM + r")", d)
    items = []
    for cmd, num in tokens:
        items.append(cmd if cmd else float(num))

    pts = []
    cur = (0.0, 0.0)
    start = (0.0, 0.0)
    i = 0
    cmd = None
    while i < len(items):
        if isinstance(items[i], str):
            cmd = items[i]
            i += 1
            if cmd in "Zz":
                cur = start
                continue
        if cmd is None:
            break

        def take(n):
            nonlocal i
            vals = items[i:i + n]
            i += n
            return vals

        if cmd in "Mm":
            x, y = take(2)
            cur = (cur[0] + x, cur[1] + y) if cmd == "m" else (x, y)
            start = cur
            pts.append(cur)
            cmd = "l" if cmd == "m" else "L"
        elif cmd in "Ll":
            x, y = take(2)
            cur = (cur[0] + x, cur[1] + y) if cmd == "l" else (x, y)
            pts.append(cur)
        elif cmd in "Hh":
            (x,) = take(1)
            cur = (cur[0] + x, cur[1]) if cmd == "h" else (x, cur[1])
            pts.append(cur)
        elif cmd in "Vv":
            (y,) = take(1)
            cur = (cur[0], cur[1] + y) if cmd == "v" else (cur[0], y)
            pts.append(cur)
        elif cmd in "Cc":
            x1, y1, x2, y2, x, y = take(6)
            if cmd == "c":
                c1 = (cur[0] + x1, cur[1] + y1)
                c2 = (cur[0] + x2, cur[1] + y2)
                end = (cur[0] + x, cur[1] + y)
            else:
                c1, c2, end = (x1, y1), (x2, y2), (x, y)
            pts += [c1, c2, end]
            cur = end
        elif cmd in "Qq":
            x1, y1, x, y = take(4)
            if cmd == "q":
                c1 = (cur[0] + x1, cur[1] + y1)
                end = (cur[0] + x, cur[1] + y)
            else:
                c1, end = (x1, y1), (x, y)
            pts += [c1, end]
            cur = end
        elif cmd in "Aa":
            rx, ry, rot, laf, sf, x, y = take(7)
            end = (cur[0] + x, cur[1] + y) if cmd == "a" else (x, y)
            # Control geometry is reconstructed in Swift; only the endpoint is
            # a literal, so that is all we require.
            pts.append(end)
            cur = end
        else:
            i += 1
    return pts


def svg_elements(src):
    """Yield (kind, label, required_points) for every drawn element."""
    # Strip the <defs> block: masks and filters are ported structurally, not
    # as literal coordinates.
    body = src.split("</defs>", 1)[1] if "</defs>" in src else src

    out = []
    for m in re.finditer(r"<(path|ellipse|circle|rect)\b([^>]*)>", body):
        tag, attrs = m.group(1), m.group(2)
        ctx = body[max(0, m.start() - 320):m.start()]
        labels = re.findall(r"\{\{\s*(\w+)\s*\}\}", ctx)
        label = labels[-1] if labels else "-"

        if tag == "path":
            d = re.search(r'\bd="([^"]+)"', attrs)
            if not d:
                continue
            out.append(("path", label, d.group(1)[:46], parse_path(d.group(1))))
        elif tag in ("ellipse", "circle"):
            cx = float(re.search(r'\bcx="(%s)"' % NUM, attrs).group(1))
            cy = float(re.search(r'\bcy="(%s)"' % NUM, attrs).group(1))
            if tag == "circle":
                r = float(re.search(r'\br="(%s)"' % NUM, attrs).group(1))
                rx = ry = r
            else:
                rx = float(re.search(r'\brx="(%s)"' % NUM, attrs).group(1))
                ry = float(re.search(r'\bry="(%s)"' % NUM, attrs).group(1))
            out.append((tag, label, f"{tag} {cx},{cy} r{rx},{ry}",
                        [(cx, cy), (rx, ry)]))
        elif tag == "rect":
            x = float(re.search(r'\bx="(%s)"' % NUM, attrs).group(1))
            y = float(re.search(r'\by="(%s)"' % NUM, attrs).group(1))
            w = float(re.search(r'\bwidth="(%s)"' % NUM, attrs).group(1))
            h = float(re.search(r'\bheight="(%s)"' % NUM, attrs).group(1))
            out.append(("rect", label, f"rect {x},{y} {w}x{h}",
                        [(x, y), (w, h)]))
    return out


# -------------------------------------------------------------- Swift parsing

def swift_points():
    """Every geometric point the Swift port names, however it names it."""
    pts = set()
    pairs = set()
    src = "\n".join(f.read_text() for f in sorted(SWIFT_DIR.glob("*.swift")))

    # p(x, y)
    for m in re.finditer(r"\bp\(\s*(%s)\s*,\s*(%s)\s*\)" % (NUM, NUM), src):
        pts.add((float(m.group(1)), float(m.group(2))))

    # NeeEllipse(cx:cy:rx:ry:) and (cx:cy:r:)
    for m in re.finditer(
        r"NeeEllipse\(cx:\s*(%s),\s*cy:\s*(%s),\s*rx:\s*(%s),\s*ry:\s*(%s)\)"
        % (NUM, NUM, NUM, NUM), src
    ):
        cx, cy, rx, ry = map(float, m.groups())
        pts.add((cx, cy)); pairs.add((rx, ry))
    for m in re.finditer(
        r"NeeEllipse\(cx:\s*(%s),\s*cy:\s*(%s),\s*r:\s*(%s)\)" % (NUM, NUM, NUM), src
    ):
        cx, cy, r = map(float, m.groups())
        pts.add((cx, cy)); pairs.add((r, r))

    # NeeRoundedRect(x:y:width:height:radius:)
    for m in re.finditer(
        r"NeeRoundedRect\(x:\s*(%s),\s*y:\s*(%s),\s*width:\s*(%s),\s*height:\s*(%s)"
        % (NUM, NUM, NUM, NUM), src
    ):
        x, y, w, h = map(float, m.groups())
        pts.add((x, y)); pairs.add((w, h))

    # NeeArmShape(cx:cy:rx:ry:degrees:)
    for m in re.finditer(
        r"NeeArmShape\(cx:\s*(%s),\s*cy:\s*(%s),\s*rx:\s*(%s),\s*ry:\s*(%s)"
        % (NUM, NUM, NUM, NUM), src
    ):
        cx, cy, rx, ry = map(float, m.groups())
        pts.add((cx, cy)); pairs.add((rx, ry))

    # Bare (x, y, r) tuple tables: craters, dot eyes, blossom flowers.
    for m in re.finditer(r"\(\s*(%s),\s*(%s),\s*(%s)\s*\)" % (NUM, NUM, NUM), src):
        x, y, r = map(float, m.groups())
        pts.add((x, y)); pairs.add((r, r))

    # CGRect(x:y:width:height:) written with arithmetic, e.g. 60 - 33.
    for m in re.finditer(
        r"CGRect\(\s*x:\s*([^,]+),\s*y:\s*([^,]+),\s*width:\s*([^,]+),\s*height:\s*([^)]+)\)",
        src,
    ):
        try:
            x, y, w, h = (eval(g.strip(), {"__builtins__": {}}) for g in m.groups())
        except Exception:
            continue
        pts.add((float(x), float(y))); pairs.add((float(w), float(h)))
        pts.add((float(x) + float(w) / 2, float(y) + float(h) / 2))
        pairs.add((float(w) / 2, float(h) / 2))

    # Star eyes: Swift walks a table of deltas from each origin, so replay that
    # walk here and add the absolute vertices it produces.
    steps_m = re.search(r"steps:\s*\[CGPoint\]\s*=\s*\[(.*?)\]", src, re.S)
    origins_m = re.search(r"origins:\s*\[CGPoint\]\s*=\s*\[(.*?)\]", src, re.S)
    if steps_m and origins_m:
        steps = re.findall(r"p\(\s*(%s),\s*(%s)\s*\)" % (NUM, NUM), steps_m.group(1))
        origins = re.findall(r"p\(\s*(%s),\s*(%s)\s*\)" % (NUM, NUM), origins_m.group(1))
        for ox, oy in origins:
            cx, cy = float(ox), float(oy)
            pts.add((cx, cy))
            for dx, dy in steps:
                cx += float(dx)
                cy += float(dy)
                pts.add((round(cx, 9), round(cy, 9)))

    # Sparkle table: (p(cx, cy), arm, delay) -> the four cross endpoints.
    for m in re.finditer(
        r"\(p\(\s*(%s),\s*(%s)\s*\),\s*(%s),\s*(%s)\)" % (NUM, NUM, NUM, NUM), src
    ):
        cx, cy, arm = float(m.group(1)), float(m.group(2)), float(m.group(3))
        pts |= {(cx, cy - arm), (cx, cy + arm), (cx - arm, cy), (cx + arm, cy)}

    return pts, pairs


def near(target, pool):
    return any(abs(target[0] - q[0]) < TOL and abs(target[1] - q[1]) < TOL
               for q in pool)


# ------------------------------------------------------------------ main

def main():
    src = DESIGN.read_text()
    elements = svg_elements(src)
    pts, pairs = swift_points()
    pool = pts | pairs

    total = missing_total = 0
    failures = []

    for kind, label, desc, required in elements:
        miss = [q for q in required if not near(q, pool)]
        total += len(required)
        missing_total += len(miss)
        status = "ok  " if not miss else "MISS"
        if miss:
            failures.append((label, desc, miss))
        print(f"  [{status}] {label:<14} {desc:<48} {len(required) - len(miss)}/{len(required)}")

    print()
    print(f"SVG elements checked : {len(elements)}")
    print(f"Coordinates checked  : {total}")
    print(f"Coordinates missing  : {missing_total}")

    if failures:
        print("\nMISSING COORDINATES")
        for label, desc, miss in failures:
            print(f"  {label} :: {desc}")
            for q in miss:
                print(f"      {q}")
        return 1
    print("\nAll SVG geometry accounted for in the Swift port.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
