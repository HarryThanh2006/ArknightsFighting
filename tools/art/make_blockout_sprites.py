"""PLACEHOLDER blockout sprite generator (design/art/sprite-spec-2d.md).

Draws a generic Guard-class melee fighter as flat geometric shapes, one strip per
animation, plus a draw-over template sheet per animation (frame grid, feet anchor,
hurtboxes, hitboxes on active drawings). No character design: scaffolding for hand
drawing only. Reads data/moves/tier_minus_one.cfg and the character's frames.cfg.

    python tools/art/make_blockout_sprites.py
"""
import configparser
import json
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CHAR = "guard_blockout"
CHAR_DIR = os.path.join(ROOT, "assets", "characters", CHAR)
MOVES = os.path.join(ROOT, "data", "moves", "tier_minus_one.cfg")
SU_PER_M = 10_000

BODY = (110, 116, 128, 255)      # neutral grey
OUTLINE = (30, 34, 40, 255)      # Graphite-family outline
BLADE = (255, 198, 26, 255)      # Guard accent #FFC61A (art bible §4.2)
HURT = (60, 200, 90, 255)
HIT = (255, 198, 26, 255)


def read_cfg(path):
    cp = configparser.ConfigParser(inline_comment_prefixes=None, comment_prefixes=(";",))
    cp.read(path, encoding="utf-8")
    out = {}
    for sec in cp.sections():
        out[sec] = {}
        for k, v in cp[sec].items():
            try:
                out[sec][k] = json.loads(v)
            except json.JSONDecodeError:
                out[sec][k] = v.strip('"')
    return out


FR = read_cfg(os.path.join(CHAR_DIR, "frames.cfg"))
MV = read_cfg(MOVES)
W, H = FR["canvas"]["width"], FR["canvas"]["height"]
AX, AY = FR["canvas"]["anchor_x"], FR["canvas"]["anchor_y"]
PX_PER_SU = FR["canvas"]["px_per_m"] / SU_PER_M


def to_canvas(x, y):
    """Facing-local px (x forward, y up from the feet anchor) -> canvas px."""
    return (AX + x, AY - y)


def su_rect(box):
    """[cx, cy, hw, hh] in su -> canvas rectangle."""
    cx, cy, hw, hh = box
    x0, y0 = to_canvas((cx - hw) * PX_PER_SU, (cy + hh) * PX_PER_SU)
    x1, y1 = to_canvas((cx + hw) * PX_PER_SU, (cy - hh) * PX_PER_SU)
    return [x0, y0, x1, y1]


def boxes(move, track, first, last):
    """Boxes of `track` active on any tick in [first, last] for a move section."""
    if move not in MV:
        return []
    out = []
    for row in MV[move][track]:
        if row[0] <= last and row[1] >= first:
            out.append(row[2:])
    return out


def blade(d, hand, angle_deg, length=230, width=22):
    """A long straight-then-curved blade from the hand (Guard 'blade arc')."""
    pts_l, pts_r = [], []
    for i in range(7):
        t = i / 6
        a = math.radians(angle_deg + 25 * t)  # curve toward the tip
        hx, hy = hand
        px = hx + math.cos(math.radians(angle_deg)) * length * t * 0.6 + math.cos(a) * length * t * 0.4
        py = hy + math.sin(math.radians(angle_deg)) * length * t * 0.6 + math.sin(a) * length * t * 0.4
        nx, ny = -math.sin(a), math.cos(a)
        w = width * (1 - 0.7 * t)
        pts_l.append(to_canvas(px + nx * w / 2, py + ny * w / 2))
        pts_r.append(to_canvas(px - nx * w / 2, py - ny * w / 2))
    d.polygon(pts_l + pts_r[::-1], fill=BLADE, outline=OUTLINE, width=3)


def figure(d, lean=0, stride=0, crouch=0, hand=(40, 190), arm_box=None, lying=False):
    """Generic 3-head-tall body. Units: px forward / up from the feet anchor."""
    if lying:
        d.rounded_rectangle([*to_canvas(-120, 70), *to_canvas(200, 0)], 18, fill=BODY, outline=OUTLINE, width=3)
        d.ellipse([*to_canvas(200, 80), *to_canvas(280, 0)], fill=BODY, outline=OUTLINE, width=3)
        return
    hip = 130 - crouch
    for side in (-1, 1):
        fx = side * 22 + side * stride
        d.polygon([to_canvas(fx - 14, 0), to_canvas(fx + 14, 0), to_canvas(lean * 0.3 + side * 16 + 14, hip),
                   to_canvas(lean * 0.3 + side * 16 - 14, hip)], fill=BODY, outline=OUTLINE, width=3)
    sh = 215 - crouch
    d.polygon([to_canvas(lean * 0.3 - 40, hip), to_canvas(lean * 0.3 + 40, hip), to_canvas(lean + 46, sh),
               to_canvas(lean - 46, sh)], fill=BODY, outline=OUTLINE, width=3)
    hx, hy = lean, sh + 46
    d.ellipse([*to_canvas(hx - 46, hy + 46), *to_canvas(hx + 46, hy - 46)], fill=BODY, outline=OUTLINE, width=3)
    shoulder = (lean + 30, sh - 10)
    if arm_box is not None:
        r = su_rect(arm_box)  # arm reaching into its hurtbox (Heavy active + recovery)
        d.line([to_canvas(*shoulder), (r[0] + 4, (r[1] + r[3]) / 2)], fill=OUTLINE, width=24)
        d.line([to_canvas(*shoulder), (r[0] + 4, (r[1] + r[3]) / 2)], fill=BODY, width=18)
        d.rectangle(r, fill=BODY, outline=OUTLINE, width=3)
    else:
        d.line([to_canvas(*shoulder), to_canvas(*hand)], fill=OUTLINE, width=18)
        d.line([to_canvas(*shoulder), to_canvas(*hand)], fill=BODY, width=12)


def draw_pose(anim, i, first, last):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    hits = boxes(anim, "hitboxes", first, last)
    arms = [b for b in boxes(anim, "hurtboxes", first, last) if b[0] != 0]
    arm = arms[0] if arms else None
    if anim == "idle":
        bob = [0, 3, 6, 3][i]
        figure(d, crouch=bob, hand=(40, 185 - bob))
        blade(d, (40, 185 - bob), 70, length=170)
    elif anim == "walk":
        s = [-24, -12, 0, 12, 24, 12][i]
        figure(d, stride=s, hand=(42, 185))
        blade(d, (42, 185), 68, length=170)
    elif anim in ("light", "heavy"):
        if hits:
            figure(d, lean=18, hand=(70, 200), arm_box=arm)
            for hb in hits:  # the active drawing covers the hitbox exactly
                d.rectangle(su_rect(hb), fill=BLADE, outline=OUTLINE, width=3)
        else:
            active = MV[anim]["hitboxes"][0][0]
            if last < active:
                ang = ([110, 140] if anim == "light" else [120, 150, 170])[i]
                figure(d, lean=-10 - 6 * i, hand=(10, 205), arm_box=arm)
                blade(d, (10, 205), ang, length=150)
            else:
                k = i - (len(FR[anim]["ranges"]) - 3)
                ang = [-25, -10, 30][k]
                figure(d, lean=14 - 6 * k, hand=(60, 170), arm_box=arm)
                blade(d, (60, 170), ang, length=190)
    elif anim == "block":
        figure(d, lean=-8, crouch=10, hand=(55, 175))
        blade(d, (55, 175), [65, 90][i], length=170)
    elif anim == "hit":
        lean = [-22, -32, -14][i]
        figure(d, lean=lean, crouch=8, hand=(lean, 170))
        blade(d, (lean, 170), 125, length=160)
    elif anim == "ko":
        if i < 3:
            figure(d, lean=[-30, -40, -50][i], crouch=[10, 50, 90][i], hand=(-20, 120 - 30 * i))
            blade(d, (-20, 120 - 30 * i), [140, 170, 185][i], length=200)
        else:
            figure(d, lying=True)
            blade(d, (-60, 15), 180, length=200)
    font = ImageFont.load_default(size=16)
    d.text((6, 4), "PLACEHOLDER", fill=(255, 64, 64, 255), font=font)
    d.text((6, 22), "%s %d/%d  t%d-%d" % (anim, i + 1, len(FR[anim]["ranges"]), first, last), fill=(255, 255, 255, 255), font=font)
    return img, hits, arm


def template(anim, frames):
    """Draw-over sheet: grid, floor + anchor, hurtboxes, hitboxes, faint blockout ghost."""
    n = len(frames)
    sheet = Image.new("RGBA", (W * n, H), (245, 245, 240, 255))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)
    for i, (img, hits, arm, first, last) in enumerate(frames):
        ox = i * W
        ghost = img.copy()
        ghost.putalpha(ghost.getchannel("A").point(lambda a: a * 30 // 255))
        sheet.alpha_composite(ghost, (ox, 0))
        for gx in range(0, W, 32):
            d.line([(ox + gx, 0), (ox + gx, H)], fill=(220, 220, 215, 255))
        for gy in range(0, H, 32):
            d.line([(ox, gy), (ox + W, gy)], fill=(220, 220, 215, 255))
        d.rectangle([ox, 0, ox + W - 1, H - 1], outline=(40, 40, 40, 255), width=2)
        d.line([(ox, AY), (ox + W, AY)], fill=(40, 40, 200, 255), width=2)
        d.line([(ox + AX, AY - 12), (ox + AX, AY + 12)], fill=(40, 40, 200, 255), width=2)
        hurt = [[0, 6000, 2500, 6000]] + ([arm] if arm else [])
        for hb in hurt:
            r = su_rect(hb)
            d.rectangle([r[0] + ox, r[1], r[2] + ox, r[3]], outline=HURT, width=2)
        for hb in hits:
            r = su_rect(hb)
            d.rectangle([r[0] + ox, r[1], r[2] + ox, r[3]], outline=HIT, width=3)
        label = "%s %d  ticks %d-%d%s" % (anim, i + 1, first, min(last, 999), "  ACTIVE" if hits else "")
        d.text((ox + 6, 4), label, fill=(20, 20, 20, 255), font=font)
    return sheet


def main():
    os.makedirs(os.path.join(CHAR_DIR, "template"), exist_ok=True)
    for anim, spec in FR.items():
        if anim == "canvas":
            continue
        frames = []
        for i, (first, last) in enumerate(spec["ranges"]):
            img, hits, arm = draw_pose(anim, i, first, last)
            frames.append((img, hits, arm, first, last))
        strip = Image.new("RGBA", (W * len(frames), H), (0, 0, 0, 0))
        for i, f in enumerate(frames):
            strip.alpha_composite(f[0], (i * W, 0))
        strip.save(os.path.join(CHAR_DIR, "%s_%s.png" % (CHAR, anim)))
        template(anim, frames).save(os.path.join(CHAR_DIR, "template", "%s_%s_template.png" % (CHAR, anim)))
        print("wrote", anim, len(frames), "drawings")


if __name__ == "__main__":
    main()
