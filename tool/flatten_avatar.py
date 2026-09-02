#!/usr/bin/env python3
"""Flatten AI-generated avatar art to strict flat colors for the Igboman app.

Reduces subtle gradients/airbrushing (common AI artifact) to hard flat
regions via median-cut quantization plus median smoothing, then removes
speckles (dark, mid-tone, and green-in-white) and snaps near-background
pixels to the exact cream background so the asset blends on app cards.

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


def _clean_green_in_white(img: Image.Image) -> Image.Image:
    """Replace tiny green-dominant specks sitting inside near-white areas.

    Fixes eye-white contamination (a common flattener artifact) without
    touching real green regions (shirt, cap): the local majority color
    decides, so large green surfaces are never altered.
    """
    w, h = img.size
    px = img.load()

    def majority(x: int, y: int, radius: int = 3):
        counts: dict[tuple, int] = {}
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    p = px[nx, ny]
                    counts[p] = counts.get(p, 0) + 1
        return max(counts, key=counts.get)

    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if g > r + 12 and g > b + 12:  # green-dominant pixel
                maj = majority(x, y)
                mr, mg, mb = maj
                if mr > 200 and mg > 200 and mb > 200:  # local area is white
                    px[x, y] = maj
    return img


def _clean_eye_fringing(img: Image.Image) -> Image.Image:
    """Remove green/gray fringing right at the bottom edge of eye whites.

    Finds eye-white components (white blobs of plausible eye size), then,
    within a small dilation of their bbox, recolors any green-dominant
    pixel to the eye white color. Dark pupils and outlines are never
    touched (they are not green-dominant).
    """
    w, h = img.size
    px = img.load()

    def is_white(p) -> bool:
        return p[0] > 225 and p[1] > 225 and p[2] > 225

    seen = [[False] * w for _ in range(h)]
    for y in range(120, 260):  # eyes live in the upper face band
        for x in range(w):
            if seen[y][x] or not is_white(px[x, y]):
                continue
            comp, q = [], deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and is_white(px[nx, ny]):
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if not (80 <= len(comp) <= 6000):
                continue
            xs = [c[0] for c in comp]
            ys = [c[1] for c in comp]
            bw, bh = max(xs) - min(xs), max(ys) - min(ys)
            if not (12 <= bw <= 70 and 12 <= bh <= 70):
                continue
            counts: dict[tuple, int] = {}
            for c in comp:
                counts[px[c]] = counts.get(px[c], 0) + 1
            white = max(counts, key=counts.get)
            for yy in range(max(0, min(ys) - 4), min(h, max(ys) + 5)):
                for xx in range(max(0, min(xs) - 4), min(w, max(xs) + 5)):
                    r, g, b = px[xx, yy]
                    if not is_white(px[xx, yy]) and g >= r + 8 and g >= b + 8:
                        px[xx, yy] = white
            # olive/brown lid tints inside the eye zone: mid-tone pixel with
            # a white neighbor within 2px becomes eye white (flat eye look)
            for yy in range(max(0, min(ys) - 3), min(h, max(ys) + 4)):
                for xx in range(max(0, min(xs) - 3), min(w, max(xs) + 4)):
                    r, g, b = px[xx, yy]
                    if is_white(px[xx, yy]) or min(r, g, b) < 80:
                        continue
                    has_white = any(
                        0 <= nx < w and 0 <= ny < h and is_white(px[nx, ny])
                        for ny in range(yy - 2, yy + 3)
                        for nx in range(xx - 2, xx + 3)
                    )
                    if has_white:
                        px[xx, yy] = white
    # flat sticker eyes: any non-white pixel in the eye zone becomes
            # the dominant outline color (kills olive lid tints cleanly)
            counts2: dict[tuple, int] = {}
            for yy in range(max(0, min(ys) - 3), min(h, max(ys) + 4)):
                for xx in range(max(0, min(xs) - 3), min(w, max(xs) + 4)):
                    if not is_white(px[xx, yy]):
                        counts2[px[xx, yy]] = counts2.get(px[xx, yy], 0) + 1
            if counts2:
                outline = max(counts2, key=counts2.get)
                for yy in range(max(0, min(ys) - 3), min(h, max(ys) + 4)):
                    for xx in range(max(0, min(xs) - 3), min(w, max(xs) + 4)):
                        if not is_white(px[xx, yy]):
                            px[xx, yy] = outline
    return img


def _suppress_mid_tone_outliers(img: Image.Image, max_comp: int = 400) -> Image.Image:
    """Replace small isolated clusters of mid-tone colors with local median.

    Targets gray/tan stipple (beard, tunic) and anti-aliased edge fuzz.
    Excludes whites, near-black, and saturated colors so eyes, catchlights,
    pupils, and outlines are never touched.
    """
    w, h = img.size
    px = img.load()

    def in_zone(p) -> bool:
        r, g, b = p
        return 100 <= min(r, g, b) and max(r, g, b) <= 232

    def median_ring(x: int, y: int):
        samples = []
        for dy in (-2, -1, 0, 1, 2):
            for dx in (-2, -1, 0, 1, 2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    samples.append(px[nx, ny])
        s = sorted(samples)
        return s[len(s) // 2]

    seen = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if seen[y][x] or not in_zone(px[x, y]):
                continue
            comp, q = [], deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and in_zone(px[nx, ny]):
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if 0 < len(comp) <= max_comp:
                fill = median_ring(*comp[0])
                for cx, cy in comp:
                    px[cx, cy] = fill
    return img


def _clean_micro_dots(img: Image.Image, max_size: int = 12) -> Image.Image:
    """Kill isolated non-white micro-dots of ANY color (stray pixels).

    Catches mid-tone specks that fall outside the dark/mid-tone/green
    zones. White pixels are excluded so eye catchlights survive.
    """
    w, h = img.size
    px = img.load()

    def is_white(p) -> bool:
        return p[0] > 225 and p[1] > 225 and p[2] > 225

    def median_ring(x: int, y: int):
        samples = []
        for dy in (-2, -1, 0, 1, 2):
            for dx in (-2, -1, 0, 1, 2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    samples.append(px[nx, ny])
        s = sorted(samples)
        return s[len(s) // 2]

    seen = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if seen[y][x] or is_white(px[x, y]):
                continue
            comp, q = [], deque([(x, y)])
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and not is_white(px[nx, ny]):
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if 0 < len(comp) <= max_size:
                fill = median_ring(*comp[0])
                for cx, cy in comp:
                    px[cx, cy] = fill
    return img


def _flatten_green_zones(img: Image.Image) -> Image.Image:
    """Flatten watercolor speckle inside large green fills.

    Uses a box-blur local mean: a pixel that deviates strongly from its
    neighborhood AND sits in a green-dominant mid-tone region is replaced
    by the local mean. Eye irises are protected because their window mixes
    white sclera and outlines (mean is not green-dominant).
    """
    w, h = img.size
    px = img.load()
    r_img = img.getchannel(0).filter(ImageFilter.BoxBlur(4))
    g_img = img.getchannel(1).filter(ImageFilter.BoxBlur(4))
    b_img = img.getchannel(2).filter(ImageFilter.BoxBlur(4))
    rp, gp, bp = r_img.load(), g_img.load(), b_img.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            mr, mg, mb = rp[x, y], gp[x, y], bp[x, y]
            if mg > mr + 8 and mg > mb + 8 and 60 <= mr <= 220 and 60 <= mg <= 220:
                if abs(r - mr) > 45 or abs(g - mg) > 45 or abs(b - mb) > 45:
                    px[x, y] = (round(mr), round(mg), round(mb))
    return img


def flatten(src: str, dst: str, colors: int = 20, size: int = 512, clean: bool = True) -> None:
    img = Image.open(src).convert("RGB")
    q = img.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)
    img = q.convert("RGB")
    img = img.filter(ImageFilter.MedianFilter(size=5))  # kill quantization speckle
    img = img.filter(ImageFilter.MedianFilter(size=7))  # second pass, heavier smoothing
    if clean:
        img = _flatten_green_zones(img)
        img = _clean_green_in_white(img)
        img = _clean_eye_fringing(img)
        img = _suppress_mid_tone_outliers(img)
        img = _clean_speckles(img, min_y=0, max_size=25)   # micro specks anywhere
        img = _clean_speckles(img, min_y=250, max_size=120)  # bigger specks below face
        img = _clean_micro_dots(img)                        # any-color stray dots
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if abs(r - CREAM[0]) < 60 and abs(g - CREAM[1]) < 60 and abs(b - CREAM[2]) < 60:
                px[x, y] = CREAM
    img = img.resize((size, size), Image.LANCZOS)
    img.save(dst, "PNG")
    px = img.load()
    w, h = img.size
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