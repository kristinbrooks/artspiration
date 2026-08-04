"""Regenerate the launcher icons from the in-app die logo's geometry.

    python3 tool/make_icons.py

The header die (`_DieLogo` in lib/screens/roll_screen.dart) is a 26x26 rounded
square of radius 6 in ink, with three 5px paper pips whose centres sit at 0.25,
0.5 and 0.75 along the main diagonal. Those proportions are reproduced here so
the icon and the header stay the same mark — change one and rerun this.

Pure stdlib, no image library: zlib for the pixel stream, struct for the PNG
chunk headers.
"""

import struct
import zlib
from pathlib import Path

INK = (0x24, 0x1C, 0x14)
PAPER = (0xF7, 0xF1, 0xE4)

CORNER = 6 / 26      # die corner radius, as a fraction of the side
PIP_R = 2.5 / 26     # pip radius, same
PIPS = (0.25, 0.5, 0.75)

# The die sits inside the canvas rather than bleeding to the edge: iOS masks
# icons to its own squircle, which would otherwise shave the die's corners and
# crowd the outer pips. Android launchers differ in whether they mask at all,
# and a paper square crops to a paper circle without losing the die.
INSET = 0.72

# Both platforms get fully opaque icons — iOS requires it, and on Android it
# keeps the mark identical across launchers that do and don't mask.
IOS_SIZES = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}


def _in_rounded_square(x, y, origin, side, radius):
    """Is (x, y) inside a rounded square at `origin` with the given side?"""
    half = side / 2
    centre = origin + half
    qx = abs(x - centre) - (half - radius)
    qy = abs(y - centre) - (half - radius)
    if qx <= 0 and qy <= 0:
        return True  # the straight interior
    # Past the inner rect on at least one axis: clamp, then measure against the
    # corner arc. Clamping is what keeps the flat edges flat — without it the
    # sides get eaten away along with the corners.
    qx = max(qx, 0.0)
    qy = max(qy, 0.0)
    return qx * qx + qy * qy <= radius * radius


def _in_pip(x, y, origin, side):
    r = PIP_R * side
    return any(
        (x - (origin + t * side)) ** 2 + (y - (origin + t * side)) ** 2 <= r * r
        for t in PIPS
    )


def _sample(x, y, size):
    """The colour at a point on a `size`-square canvas."""
    side = INSET * size
    origin = (size - side) / 2
    if not _in_rounded_square(x, y, origin, side, CORNER * side):
        return PAPER
    return PAPER if _in_pip(x, y, origin, side) else INK


def render(size):
    """Rows of RGB tuples, antialiased along the die's edges and pips."""
    ss = 4
    rows = []
    for py in range(size):
        row = []
        for px in range(size):
            centre = _sample(px + 0.5, py + 0.5, size)
            # Flat almost everywhere, so supersample only where a pixel's
            # corners disagree with its centre — that's the handful of pixels
            # actually on an edge.
            if all(
                _sample(px + ox, py + oy, size) == centre
                for ox, oy in ((0.08, 0.08), (0.92, 0.08),
                               (0.08, 0.92), (0.92, 0.92))
            ):
                row.append(centre)
                continue

            totals = [0, 0, 0]
            for sy in range(ss):
                for sx in range(ss):
                    s = _sample(
                        px + (sx + 0.5) / ss, py + (sy + 0.5) / ss, size
                    )
                    for i in range(3):
                        totals[i] += s[i]
            row.append(tuple(round(t / (ss * ss)) for t in totals))
        rows.append(row)
    return rows


def _chunk(tag, data):
    return (
        struct.pack('>I', len(data))
        + tag
        + data
        + struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path, rows):
    size = len(rows)
    raw = bytearray()
    for row in rows:
        raw.append(0)  # filter: none
        for pixel in row:
            raw.extend(pixel)

    png = b'\x89PNG\r\n\x1a\n'
    # Colour type 2 is RGB with no alpha channel, which is what iOS demands.
    png += _chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
    png += _chunk(b'IDAT', zlib.compress(bytes(raw), 9))
    png += _chunk(b'IEND', b'')
    Path(path).write_bytes(png)


def main():
    root = Path(__file__).resolve().parent.parent

    ios_dir = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for name, size in IOS_SIZES.items():
        write_png(ios_dir / name, render(size))
        print(f'ios      {size:>4}  {name}')

    android_res = root / 'android/app/src/main/res'
    for folder, size in ANDROID_SIZES.items():
        write_png(android_res / folder / 'ic_launcher.png', render(size))
        print(f'android  {size:>4}  {folder}/ic_launcher.png')


if __name__ == '__main__':
    main()
