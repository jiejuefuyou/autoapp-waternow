"""
WaterNow App Icon Generator
Design: sky blue -> deep blue gradient + water droplet silhouette + 75% fill arc
Output: icon.png @ 1024x1024 into WaterNow/Resources/Assets.xcassets/AppIcon.appiconset/
"""
from __future__ import annotations

import ast
import math
import os
import sys


def _verify_syntax() -> None:
    with open(__file__, "r", encoding="utf-8") as fh:
        source = fh.read()
    ast.parse(source)


def _lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gen_icon(size: int = 1024) -> "Image":
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("ERROR: Pillow not installed. Run: pip install Pillow", file=sys.stderr)
        sys.exit(1)

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background: vertical sky-blue (#7DD3FC) -> deep-blue (#1E40AF) gradient
    for y in range(size):
        t = y / float(size)
        r = _lerp(0x7D, 0x1E, t)
        g = _lerp(0xD3, 0x40, t)
        b = _lerp(0xFC, 0xAF, t)
        for x in range(size):
            draw.point((x, y), fill=(r, g, b, 255))

    cx, cy = size // 2, size // 2

    # Outer ring (white bezel, 68% radius, 5% line width) - represents the cup rim
    r_outer = int(size * 0.34)
    ring_w = max(int(size * 0.05), 6)
    draw.ellipse(
        [cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer],
        outline=(255, 255, 255, 220),
        width=ring_w,
    )

    # 75% fill arc (cyan #67E8F9) - represents 75% of daily hydration goal
    arc_r = int(size * 0.34)
    arc_w = ring_w
    draw.arc(
        [cx - arc_r, cy - arc_r, cx + arc_r, cy + arc_r],
        start=-90,
        end=180,  # 270 deg sweep = 75% of full ring
        fill=(0x67, 0xE8, 0xF9, 255),
        width=arc_w,
    )

    # Water droplet silhouette in center (white, classic teardrop shape)
    drop_w = int(size * 0.30)
    drop_h = int(size * 0.42)
    drop_cx = cx
    drop_top = cy - drop_h // 2 + int(size * 0.02)
    drop_bot = cy + drop_h // 2 + int(size * 0.02)

    # Bottom circle of droplet
    circle_r = drop_w // 2
    circle_cy = drop_bot - circle_r
    draw.ellipse(
        [drop_cx - circle_r, circle_cy - circle_r,
         drop_cx + circle_r, circle_cy + circle_r],
        fill=(255, 255, 255, 245),
    )

    # Top triangle of droplet (pointing up)
    tri_left = drop_cx - circle_r
    tri_right = drop_cx + circle_r
    tri_top_y = drop_top
    tri_base_y = circle_cy
    draw.polygon(
        [
            (drop_cx, tri_top_y),
            (tri_left, tri_base_y),
            (tri_right, tri_base_y),
        ],
        fill=(255, 255, 255, 245),
    )

    # Highlight on droplet (small white spot - gives 3D feel)
    hl_r = int(circle_r * 0.18)
    hl_cx = drop_cx - int(circle_r * 0.35)
    hl_cy = circle_cy - int(circle_r * 0.30)
    draw.ellipse(
        [hl_cx - hl_r, hl_cy - hl_r, hl_cx + hl_r, hl_cy + hl_r],
        fill=(0xBA, 0xE6, 0xFD, 230),
    )

    # Tick marks at 12 o'clock and 75% mark (visual anchors)
    tick_len = int(size * 0.06)
    tick_w = max(int(size * 0.012), 3)
    tick_r = int(size * 0.34)

    def _draw_tick(angle_deg: float) -> None:
        rad = math.radians(angle_deg - 90)
        ox = cx + tick_r * math.cos(rad)
        oy = cy + tick_r * math.sin(rad)
        ix = cx + (tick_r - tick_len) * math.cos(rad)
        iy = cy + (tick_r - tick_len) * math.sin(rad)
        draw.line([ix, iy, ox, oy], fill=(255, 255, 255, 230), width=tick_w)

    _draw_tick(0)    # 12 o'clock (start of fill)
    _draw_tick(270)  # 9 o'clock (end of 75% fill)

    return img


def main() -> None:
    _verify_syntax()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    output_dir = os.path.join(
        repo_root,
        "WaterNow", "Resources", "Assets.xcassets",
        "AppIcon.appiconset",
    )
    os.makedirs(output_dir, exist_ok=True)

    img = gen_icon(1024)
    output_path = os.path.join(output_dir, "icon.png")
    img.save(output_path, "PNG")
    print(f"[OK] 1024x1024 icon saved -> {output_path}")


if __name__ == "__main__":
    main()
