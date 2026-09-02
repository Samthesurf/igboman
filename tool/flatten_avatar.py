#!/usr/bin/env python3
"""Flatten AI-generated avatar art to strict flat colors for the Igboman app.

Reduces subtle gradients/airbrushing (common AI artifact) to hard flat
regions via median-cut quantization, then snaps near-background pixels to
the exact cream background so the asset blends perfectly on app cards.

Usage: flatten_avatar.py <input.png> <output.png> [--colors N] [--size S]
"""
import sys
from collections import deque
from PIL import Image, ImageFilter

CREAM = (251, 246, 239)  # #FBF6EF app background


def _clean_speckles(img: Image.Image, min_y: int = 250, max_size: int = 60) -> Image.Image:
    """Fill small dark components below min_y with local median color.

    Kills stray outline-color speckles (quantization/median artifacts) in
    the neck/shoulders zone while leaving the real outline network intact.
    """
    w, h = img.size
    px = img.load()

    def is_dark(p) -> bool:
        return p[0] < 90 and p[1] < 90 and p[2] < 90

    def non_dark_median(x: int, y: int):
        samples = []
        for dy in (-2, -1, 0, 1, 2):
            for dx in (-2, -1, 0, 1, 2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and not is_dark(px[nx, ny]):
                    samples.append(px[nx, ny])
        if not samples:
            return px[x, y]
        s = sorted(samples)
        return s[len(s) // 2]

    seen = [[False] * w for _ in range(h)]
    for y in range(min_y, h):
        for x in range(w):
            if seen[y][x] or not is_dark(px[x, y]):
                continue
            comp, q = [], deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and is_dark(px[nx, ny]):
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if 0 < len(comp) <= max_size:
                fill = non_dark_median(*comp[0])
                for cx, cy in comp:
                    px[cx, cy] = fill
    return img


def flatten(src: str, dst: str, colors: int = 20, size: int = 512, clean: bool = True) -> None:
    img = Image.open(src).convert("RGB")
    q = img.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)
    img = q.convert("RGB")
    img = img.filter(ImageFilter.MedianFilter(size=5))  # kill quantization speckle
    if clean:
        img = _clean_speckles(img)
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if abs(r - CREAM[0]) < 34 and abs(g - CREAM[1]) < 34 and abs(b - CREAM[2]) < 34:
                px[x, y] = CREAM
    img = img.resize((size, size), Image.LANCZOS)
    img.save(dst, "PNG")
    snap = sum(1 for c in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)] if px[c] == CREAM)
    print(f"flattened: {src} -> {dst} ({w}x{h} -> {size}x{size}, bg corners exact cream: {snap}/4)")


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    kw = {}
    if "--colors" in sys.argv:
        kw["colors"] = int(sys.argv[sys.argv.index("--colors") + 1])
    if "--size" in sys.argv:
        kw["size"] = int(sys.argv[sys.argv.index("--size") + 1])
    flatten(src, dst, **kw)