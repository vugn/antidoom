"""Builds the AntiDoom "Look Up" logo kit from one set of geometry.

Outputs
  brand/svg/        master SVGs (wordmark, symbol, app icon, moods)
  brand/png/        PNG exports (needs Google Chrome for rendering)
  assets/brand/     SVGs used inside the Flutter app
  android/.../res/  adaptive icon, themed icon, notification icon, splash and legacy PNG launcher icons

Run from the repo root:  python3 brand/source/build_brand.py
The wordmark letters are Inter Tight ExtraBold (SIL OFL 1.1) converted to outlines and stored in
wordmark-glyphs.json, so no font is needed at runtime.
"""
import json
import math
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(__file__).resolve().parent
SVG_DIR, PNG_DIR = ROOT / "brand/svg", ROOT / "brand/png"
APP_ASSETS = ROOT / "assets/brand"
RES = ROOT / "android/app/src/main/res"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# ---- Palette ----
INK = "#0A0A0A"       # letters, rings, pupils
PAPER = "#F5F5F2"     # light background
NIGHT = "#0A0A0B"     # dark background
GREEN = "#12B76A"     # brand green (app accent)
WHITE = "#FFFFFF"

LOOK = (0.2, -1.0)    # where the eyes look: up, a touch to the right


def unit(v):
    n = math.hypot(*v)
    return v[0] / n, v[1] / n


def ellipse(cx, cy, rx, ry):
    return (f"M{cx - rx:.2f} {cy:.2f}A{rx:.2f} {ry:.2f} 0 1 0 {cx + rx:.2f} {cy:.2f}"
            f"A{rx:.2f} {ry:.2f} 0 1 0 {cx - rx:.2f} {cy:.2f}Z")


def pupil_centre(cx, cy, rx, ry, pr, gap, look=LOOK):
    """Pupil pushed along `look` until it sits `gap` inside the ellipse (rx, ry)."""
    lx, ly = unit(look)
    edge = 1 / math.sqrt((lx / rx) ** 2 + (ly / ry) ** 2)
    d = edge - pr - gap
    return cx + lx * d, cy + ly * d


# ---- Eye builders -------------------------------------------------------------
# Line eye: ink ring + ink pupil, the white of the eye is the background (light backgrounds).
def eye_line(cx, cy, rx, ry, th, pr):
    ring = ellipse(cx, cy, rx, ry) + ellipse(cx, cy, rx - th, ry - th)
    px, py = pupil_centre(cx, cy, rx - th, ry - th, pr, 0)
    return ring, ellipse(px, py, pr, pr)


# Solid eye: filled eye-white with the pupil as a hole (one colour on dark/colour backgrounds).
def eye_solid(cx, cy, rx, ry, pr, gap):
    px, py = pupil_centre(cx, cy, rx, ry, pr, gap)
    return ellipse(cx, cy, rx, ry) + ellipse(px, py, pr, pr), (px, py)


# Symbol geometry on a 256 canvas
SYM = dict(cy=128, rx=52, ry=53, sep=110, th=24, pr=19)
SOLID = dict(cy=128, rx=48, ry=50, sep=104, pr=21, gap=7)


def symbol_line_paths(cx=128, s=SYM):
    out = []
    for dx in (-s["sep"] / 2, s["sep"] / 2):
        out.append(eye_line(cx + dx, s["cy"], s["rx"], s["ry"], s["th"], s["pr"]))
    return out


def symbol_solid_paths(cx=128, s=SOLID):
    out = []
    for dx in (-s["sep"] / 2, s["sep"] / 2):
        out.append(eye_solid(cx + dx, s["cy"], s["rx"], s["ry"], s["pr"], s["gap"]))
    return out


# ---- Wordmark -----------------------------------------------------------------
WM = json.loads((SRC / "wordmark-glyphs.json").read_text())
WM_PAD = 24
WM_BASE = 200          # baseline inside a 256-high canvas (x-height sits centred)
WM_W = math.ceil(WM["width"]) + WM_PAD * 2
WM_TH, WM_PR = 31, 17  # ring thickness and pupil radius for the "oo" eyes
EYE_GLYPHS = (5, 6)    # the two o's in "antidoom"


def wordmark(ink, eye_mode="line", eye_white=None, pupil=None):
    """eye_mode 'line' = ring + pupil (light bg); 'solid' = white eye with pupil (dark bg)."""
    parts = []
    for i, g in enumerate(WM["glyphs"]):
        if i not in EYE_GLYPHS:
            parts.append(f'<path fill="{ink}" d="{g["d"]}"/>')
            continue
        x1, y1, x2, y2 = g["bbox"]
        cx, cy, rx, ry = (x1 + x2) / 2, (y1 + y2) / 2, (x2 - x1) / 2, (y2 - y1) / 2
        if eye_mode == "line":
            ring, p = eye_line(cx, cy, rx, ry, WM_TH, WM_PR)
            parts.append(f'<path fill="{ink}" fill-rule="evenodd" d="{ring}"/><path fill="{ink}" d="{p}"/>')
        else:
            white = eye_white or ink
            px, py = pupil_centre(cx, cy, rx, ry, WM_PR + 2, 9)
            if pupil:
                parts.append(f'<path fill="{white}" d="{ellipse(cx, cy, rx, ry)}"/>'
                             f'<path fill="{pupil}" d="{ellipse(px, py, WM_PR + 2, WM_PR + 2)}"/>')
            else:
                parts.append(f'<path fill="{white}" fill-rule="evenodd" '
                             f'd="{ellipse(cx, cy, rx, ry)}{ellipse(px, py, WM_PR + 2, WM_PR + 2)}"/>')
    return f'<g transform="translate({WM_PAD} {WM_BASE})">{"".join(parts)}</g>'


# ---- SVG writing --------------------------------------------------------------
def svg(body, w=256, h=256, title="AntiDoom logo"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'role="img" aria-labelledby="t"><title id="t">{title}</title>{body}</svg>\n')


def symbol_line(ink=INK):
    return "".join(f'<path fill="{ink}" fill-rule="evenodd" d="{r}"/><path fill="{ink}" d="{p}"/>'
                   for r, p in symbol_line_paths())


def symbol_solid(white=WHITE, pupil=None):
    out = []
    for d, (px, py) in symbol_solid_paths():
        if pupil:
            # coloured pupil: eye-white without the hole + a pupil disc
            e = d.split("Z")[0] + "Z"
            out.append(f'<path fill="{white}" d="{e}"/><path fill="{pupil}" d="{ellipse(px, py, SOLID["pr"], SOLID["pr"])}"/>')
        else:
            out.append(f'<path fill="{white}" fill-rule="evenodd" d="{d}"/>')
    return "".join(out)


def tile(bg, inner, scale=0.86, radius=58):
    off = 128 - 128 * scale
    return (f'<rect width="256" height="256" rx="{radius}" fill="{bg}"/>'
            f'<g transform="translate({off:.2f} {off:.2f}) scale({scale})">{inner}</g>')


# ---- Moods (for the counter and illustrations) --------------------------------
def mood_tired(ink=INK):
    s = SYM
    out = []
    for dx in (-s["sep"] / 2, s["sep"] / 2):
        cx, cy = 128 + dx, s["cy"]
        ri, rj = s["rx"] - s["th"], s["ry"] - s["th"]
        ring = ellipse(cx, cy, s["rx"], s["ry"]) + ellipse(cx, cy, ri, rj)
        # heavy lid: the top 55% of the eye is closed
        lid_y = cy + rj * 0.1
        t = math.asin((lid_y - cy) / rj)
        xl, xr = cx - ri * math.cos(t), cx + ri * math.cos(t)
        lid = f"M{xl:.2f} {lid_y:.2f}A{ri:.2f} {rj:.2f} 0 1 1 {xr:.2f} {lid_y:.2f}Z"
        pupil = ellipse(cx, cy + rj - s["pr"] - 2, s["pr"], s["pr"])
        out.append(f'<path fill="{ink}" fill-rule="evenodd" d="{ring}"/><path fill="{ink}" d="{lid}"/>'
                   f'<path fill="{ink}" d="{pupil}"/>')
    return "".join(out)


def mood_fried(ink=INK):
    s = SYM
    out = []
    for dx in (-s["sep"] / 2, s["sep"] / 2):
        cx, cy = 128 + dx, s["cy"]
        ring = ellipse(cx, cy, s["rx"], s["ry"]) + ellipse(cx, cy, s["rx"] - s["th"], s["ry"] - s["th"])
        arm, w = 15, 6  # an X made of two bars at exactly 45 degrees
        bars = []
        for a in (45, -45):
            t = math.radians(a)
            ux, uy, nx, ny = math.cos(t), math.sin(t), -math.sin(t), math.cos(t)
            pts = [(cx + ux * arm + nx * w, cy + uy * arm + ny * w), (cx - ux * arm + nx * w, cy - uy * arm + ny * w),
                   (cx - ux * arm - nx * w, cy - uy * arm - ny * w), (cx + ux * arm - nx * w, cy + uy * arm - ny * w)]
            bars.append("M" + "L".join(f"{x:.2f} {y:.2f}" for x, y in pts) + "Z")
        out.append(f'<path fill="{ink}" fill-rule="evenodd" d="{ring}"/><path fill="{ink}" d="{"".join(bars)}"/>')
    return "".join(out)


# ---- Android vector drawables -------------------------------------------------
def vector(paths, size_dp, viewport=256, tx=0.0, ty=0.0, scale=1.0, tint=None):
    """paths: list of (pathData, fillColor, evenOdd)."""
    items = "".join(
        f'\n        <path android:fillColor="{c}" android:pathData="{d}"'
        f'{" android:fillType=\"evenOdd\"" if eo else ""} />' for d, c, eo in paths)
    tint_attr = f'\n    android:tint="{tint}"' if tint else ""
    return (f'<?xml version="1.0" encoding="utf-8"?>\n<!-- Generated by brand/source/build_brand.py -->\n'
            f'<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            f'    android:width="{size_dp}dp"\n    android:height="{size_dp}dp"\n'
            f'    android:viewportWidth="{viewport}"\n    android:viewportHeight="{viewport}"{tint_attr}>\n'
            f'    <group android:translateX="{tx:.2f}" android:translateY="{ty:.2f}" '
            f'android:scaleX="{scale}" android:scaleY="{scale}">{items}\n    </group>\n</vector>\n')


def solid_paths(white, pupil=None):
    out = []
    for d, (px, py) in symbol_solid_paths():
        if pupil:
            out.append((d.split("Z")[0] + "Z", white, False))
            out.append((ellipse(px, py, SOLID["pr"], SOLID["pr"]), pupil, False))
        else:
            out.append((d, white, True))
    return out


def line_paths(ink):
    out = []
    for r, p in symbol_line_paths():
        out += [(r, ink, True), (p, ink, False)]
    return out


def fit(viewport, target_w):
    """Scale + offset that centres the eyes group (bbox of the solid symbol) in `viewport`."""
    gx1 = 128 - SOLID["sep"] / 2 - SOLID["rx"]
    gw, gh = SOLID["sep"] + 2 * SOLID["rx"], 2 * SOLID["ry"]
    s = target_w / gw
    tx = (viewport - gw * s) / 2 - gx1 * s
    ty = (viewport - gh * s) / 2 - (SOLID["cy"] - SOLID["ry"]) * s
    return round(s, 4), tx, ty


# ---- PNG rendering (Chrome) ---------------------------------------------------
def render_png(svg_text, out, w, h=None, bg="00000000"):
    h = h or w
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "p.html"
        page.write_text(f"<html><body style='margin:0;background:transparent'>"
                        f"<img style='display:block;width:{w}px;height:{h}px' src='data:image/svg+xml;utf8,"
                        f"{svg_text.replace(chr(39), chr(34)).replace('#', '%23')}'></body></html>")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        f"--default-background-color={bg}", "--force-device-scale-factor=1",
                        f"--window-size={w},{h}", f"--screenshot={out}", page.as_uri()],
                       check=True, capture_output=True)


def main():
    for d in (SVG_DIR, PNG_DIR, APP_ASSETS):
        d.mkdir(parents=True, exist_ok=True)

    files = {
        # wordmark
        "antidoom-wordmark.svg": svg(wordmark(INK), WM_W, 256, "AntiDoom"),
        "antidoom-wordmark-white.svg": svg(wordmark(WHITE, "solid"), WM_W, 256, "AntiDoom"),
        "antidoom-wordmark-green.svg": svg(wordmark(GREEN), WM_W, 256, "AntiDoom"),
        # symbol (the eyes)
        "antidoom-symbol.svg": svg(symbol_line(INK), title="AntiDoom symbol"),
        "antidoom-symbol-white.svg": svg(symbol_solid(WHITE), title="AntiDoom symbol"),
        # app icon
        "antidoom-icon.svg": svg(tile(GREEN, symbol_solid(WHITE, INK)), title="AntiDoom app icon"),
        "antidoom-icon-dark.svg": svg(tile(NIGHT, symbol_solid(WHITE, NIGHT)), title="AntiDoom app icon"),
        "antidoom-icon-round.svg": svg(tile(GREEN, symbol_solid(WHITE, INK), radius=128), title="AntiDoom app icon"),
        # moods
        "antidoom-mood-calm.svg": svg(symbol_line(INK), title="AntiDoom mood: calm"),
        "antidoom-mood-tired.svg": svg(mood_tired(INK), title="AntiDoom mood: tired"),
        "antidoom-mood-fried.svg": svg(mood_fried(INK), title="AntiDoom mood: fried"),
    }
    for name, text in files.items():
        (SVG_DIR / name).write_text(text)
    for name in ("antidoom-symbol.svg", "antidoom-symbol-white.svg", "antidoom-icon.svg"):
        shutil.copy(SVG_DIR / name, APP_ASSETS / name)
    # In-app wordmarks are cropped tight to the letters (the masters keep a 256-high canvas).
    ys = [g["bbox"][1] for g in WM["glyphs"]] + [g["bbox"][3] for g in WM["glyphs"]]
    xs = [g["bbox"][0] for g in WM["glyphs"]] + [g["bbox"][2] for g in WM["glyphs"]]
    vx, vy = WM_PAD + min(xs) - 2, WM_BASE + min(ys) - 2
    vw, vh = max(xs) - min(xs) + 4, max(ys) - min(ys) + 4
    for name in ("antidoom-wordmark.svg", "antidoom-wordmark-white.svg"):
        text = files[name].replace(f'viewBox="0 0 {WM_W} 256" width="{WM_W}" height="256"',
                                   f'viewBox="{vx:.1f} {vy:.1f} {vw:.1f} {vh:.1f}" width="{vw:.0f}" height="{vh:.0f}"')
        (APP_ASSETS / name).write_text(text)

    # ---- Android: adaptive icon (vector), themed icon, notification icon, splash
    draw = RES / "drawable"
    s, tx, ty = fit(108, 62)          # eyes span 62dp of the 108dp canvas: inside the 66dp safe zone
    (draw / "ic_launcher_foreground.xml").write_text(
        vector(solid_paths(WHITE, INK), 108, 108, tx, ty, s))
    (draw / "ic_launcher_monochrome.xml").write_text(
        vector(solid_paths("#FFFFFFFF"), 108, 108, tx, ty, s))
    s, tx, ty = fit(24, 22)
    (draw / "ic_stat_antidoom.xml").write_text(vector(solid_paths("#FFFFFFFF"), 24, 24, tx, ty, s))
    s, tx, ty = fit(160, 132)
    (draw / "ic_splash_eyes.xml").write_text(vector(line_paths(INK), 160, 160, tx, ty, s))
    night = RES / "drawable-night"
    night.mkdir(exist_ok=True)
    (night / "ic_splash_eyes.xml").write_text(vector(solid_paths(WHITE), 160, 160, tx, ty, s))

    # legacy launcher PNGs (API 24-25) + store icon
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for dens, px in sizes.items():
        mip = RES / f"mipmap-{dens}"
        render_png(files["antidoom-icon.svg"], mip / "ic_launcher.png", px)
        render_png(files["antidoom-icon-round.svg"], mip / "ic_launcher_round.png", px)
        for old in ("ic_launcher_foreground.png", "ic_launcher_monochrome.png"):
            (mip / old).unlink(missing_ok=True)

    # PNG exports
    render_png(svg(tile(GREEN, symbol_solid(WHITE, INK), radius=0)), PNG_DIR / "antidoom-icon-playstore-512.png", 512)
    render_png(files["antidoom-icon.svg"], PNG_DIR / "antidoom-icon-1024.png", 1024)
    render_png(files["antidoom-symbol.svg"], PNG_DIR / "antidoom-symbol-512.png", 512)
    render_png(files["antidoom-symbol-white.svg"], PNG_DIR / "antidoom-symbol-white-512.png", 512)
    for name in ("antidoom-wordmark", "antidoom-wordmark-white", "antidoom-wordmark-green"):
        render_png(files[f"{name}.svg"], PNG_DIR / f"{name}-1200.png", 1200, round(1200 * 256 / WM_W))
    print("brand kit written:", len(files), "SVGs")


if __name__ == "__main__":
    main()
