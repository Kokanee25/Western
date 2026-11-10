#!/usr/bin/env python3
"""The Winchester's side render laid over a real 1873's side-on photo at the same scale (#734; the
Colt's overlay.py, experiments/gun_lab/saa/, copied and adapted): the photo's two points on the bore's
axis fix the scale, turn and place; the render (win73_blender.py --preview --alpha=1
--views=right|left, with its .json) is warped onto it.

    python3 experiments/gun_lab/win73/overlay.py PHOTO RENDER.png OUT_DIR --points=x1,y1,f1:x2,y2,f2 [--name=N] \
        [--mask=PHOTO_MASK.png] [--crop=f0,f1,u0,u1 [--zoom=3]] [--profile=f,f,...]

--points: two places on the bore's axis in the photo's pixels, each with its distance along the bore
in the design's inches (f: 0 the breech face, 2.25 the receiver's front face, MUZZLE the muzzle; the
render's .json gives muzzle_f). The photo's gun faces either way: a right-side photo (muzzle to the
right) takes the "right" render, a left-side one the "left".
--profile: at each f, the silhouette's runs (top and bottom, in design inches) in the photo's mask and
in the render: where an outline is off, by how much.
Out: OUT_DIR/<name>_overlay.jpg (the photo, the render's outline in red over it, its body tinted) and
<name>_side.jpg (the photo and the render side by side, same scale, cropped alike); with --mask (the
photo's gun as white on black, its holes filled), <name>_diff.png and the overlap printed.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter


def arg(name, default=""):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def side_plain(photo_p, render_p, out, name):
    """A render with no alpha (the game's, under the real look) beside the photo at the same scale:
    its .json gives where the muzzle and the receiver's front face (ReceiverFront) landed in it; the
    photo's two --points (the muzzle, then the receiver's front) put them in the photo's pixels."""
    meta = json.load(open(os.path.splitext(render_p)[0] + ".json"))
    (x1, y1, f1), (x2, y2, f2) = [tuple(float(v) for v in p.split(",")) for p in arg("points").split(":")]
    # The receiver's front (ReceiverFront, f 2.25) on the photo: along the photo's bore from its two points.
    breech_f = float(arg("breech_f", "2.25"))
    t = (f1 - breech_f) / (f1 - f2)
    zb = complex(x1, y1) + (complex(x2, y2) - complex(x1, y1)) * t
    zm = complex(x1, y1)
    rm = complex(*meta["Muzzle"])
    rb = complex(*meta["ReceiverFront"])
    # render -> photo: z = a * r + b, mirrored first if the render faces the other way.
    flip = (rb.real - rm.real) * (zb.real - zm.real) < 0
    render = Image.open(render_p).convert("RGB")
    if flip:
        render = render.transpose(Image.FLIP_LEFT_RIGHT)
        rm, rb = complex(render.width - rm.real, rm.imag), complex(render.width - rb.real, rb.imag)
    a = (zb - zm) / (rb - rm)
    b = zm - a * rm
    photo = Image.open(photo_p).convert("RGB")
    inv_a = 1 / a
    o = -b * inv_a
    coeffs = (inv_a.real, -inv_a.imag, o.real, inv_a.imag, inv_a.real, o.imag)
    warped = render.transform(photo.size, Image.AFFINE, coeffs, resample=Image.BICUBIC)
    mask = Image.open(arg("mask")).convert("L") if arg("mask") else None
    x0, y0, x1b, y1b = mask.getbbox() if mask else (0, 0, photo.width, photo.height)
    m = int(0.05 * (x1b - x0))
    crop = (max(0, x0 - m), max(0, y0 - m), min(photo.width, x1b + m), min(photo.height, y1b + m))
    pa, ra = photo.crop(crop), warped.crop(crop)
    side = Image.new("RGB", (pa.width * 2 + 12, pa.height), (20, 20, 20))
    side.paste(pa, (0, 0))
    side.paste(ra, (pa.width + 12, 0))
    side.save(os.path.join(out, name + "_side.jpg"), quality=90)
    print("%s_side.jpg (the render %s)" % (os.path.join(out, name), "mirrored to face as the photo" if flip else "as rendered"))
    if arg("crop"):
        # The same box (design inches) from the photo and the game's render, side by side.
        f0, f1c, u0, u1 = (float(v) for v in arg("crop").split(","))
        ap = (complex(x2, y2) - complex(x1, y1)) / (f2 - f1)
        bp = complex(x1, y1) - ap * f1
        zs = [ap * complex(f, u) + bp for f in (f0, f1c) for u in (u0, u1)]
        box = (int(min(z.real for z in zs)), int(min(z.imag for z in zs)), int(max(z.real for z in zs)), int(max(z.imag for z in zs)))
        zoom = int(arg("zoom", "3"))
        pa = photo.crop(box).resize(((box[2] - box[0]) * zoom, (box[3] - box[1]) * zoom), Image.LANCZOS)
        ra = warped.crop(box).resize(pa.size, Image.LANCZOS)
        sheet = Image.new("RGB", (pa.width * 2 + 12, pa.height), (20, 20, 20))
        sheet.paste(pa, (0, 0))
        sheet.paste(ra, (pa.width + 12, 0))
        sheet.save(os.path.join(out, name + "_crop.jpg"), quality=90)


def main():
    photo_p, render_p, out = sys.argv[1], sys.argv[2], sys.argv[3]
    if arg("plain"):
        os.makedirs(out, exist_ok=True)
        return side_plain(photo_p, render_p, out, arg("name", "w73"))
    name = arg("name", "w73")
    os.makedirs(out, exist_ok=True)
    meta = json.load(open(os.path.splitext(render_p)[0] + ".json"))
    pts = [tuple(float(v) for v in p.split(",")) for p in arg("points").split(":")]
    photo = Image.open(photo_p).convert("RGB")
    render = Image.open(render_p).convert("RGBA")
    W, H = render.size
    ppi, cf, cu = meta["px_per_in"], meta["centre_f"], meta["centre_u"]
    right = meta["muzzle_right"]

    # design (f, u) -> photo z = x + iy (y down). Seen from the gun's right the design is mirrored
    # in that plane (f right, u up), so z = a * conj(w) + b; from its left z = a * w + b.
    def w_of(f, u):
        w = complex(f, u)
        return w.conjugate() if right else w
    (x1, y1, f1), (x2, y2, f2) = pts
    w1, w2 = w_of(f1, 0.0), w_of(f2, 0.0)
    z1, z2 = complex(x1, y1), complex(x2, y2)
    a = (z2 - z1) / (w2 - w1)
    b = z1 - a * w1

    # photo pixel -> design -> render pixel, as an affine for PIL (output = photo space).
    def photo_to_render(x, y):
        w = (complex(x, y) - b) / a
        f, u = (w.real, -w.imag) if right else (w.real, w.imag)
        rx = W / 2 + (f - cf) * ppi * (1 if right else -1)
        ry = H / 2 - (u - cu) * ppi
        return rx, ry
    o = photo_to_render(0, 0)
    ex = photo_to_render(1, 0)
    ey = photo_to_render(0, 1)
    coeffs = (ex[0] - o[0], ey[0] - o[0], o[0], ex[1] - o[1], ey[1] - o[1], o[1])
    warped = render.transform(photo.size, Image.AFFINE, coeffs, resample=Image.BICUBIC)
    alpha = warped.split()[3].point(lambda v: 255 if v > 100 else 0)
    edge = alpha.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(3))

    over = photo.copy()
    tint = Image.new("RGB", photo.size, (40, 160, 255))
    over = Image.composite(Image.blend(over, tint, 0.28), over, alpha)
    over.paste((255, 30, 30), mask=edge)
    # Crop both to the union of the gun in the photo and the render, with a margin.
    box = alpha.getbbox()
    x0, y0, x1b, y1b = box
    m = int(0.06 * (x1b - x0))
    crop = (max(0, x0 - m), max(0, y0 - m), min(photo.width, x1b + m), min(photo.height, y1b + m))
    over.crop(crop).save(os.path.join(out, name + "_overlay.jpg"), quality=90)
    # Side by side: the photo, then the render alone on grey, the same crop.
    plain = Image.new("RGB", photo.size, (128, 128, 128))
    plain.paste(warped.convert("RGB"), mask=warped.split()[3])
    a_ = photo.crop(crop)
    b_ = plain.crop(crop)
    side = Image.new("RGB", (a_.width * 2 + 12, a_.height), (20, 20, 20))
    side.paste(a_, (0, 0))
    side.paste(b_, (a_.width + 12, 0))
    side.save(os.path.join(out, name + "_side.jpg"), quality=90)
    # A crop in the design's inches (--crop=f0,f1,u0,u1: one part judged on its own, its pixels too few
    # in the whole gun's overlap): the photo, the render, the outline over the photo, side by side.
    if arg("crop"):
        f0, f1, u0, u1 = (float(v) for v in arg("crop").split(","))
        corners = [a * w_of(f, u) + b for f in (f0, f1) for u in (u0, u1)]
        box = (int(min(z.real for z in corners)), int(min(z.imag for z in corners)),
               int(max(z.real for z in corners)), int(max(z.imag for z in corners)))
        zoom = int(arg("zoom", "3"))
        plain_r = Image.new("RGB", photo.size, (128, 128, 128))
        plain_r.paste(warped.convert("RGB"), mask=warped.split()[3])
        outl = photo.copy()
        outl.paste((255, 30, 30), mask=edge)
        panels = [im.crop(box).resize(((box[2] - box[0]) * zoom, (box[3] - box[1]) * zoom), Image.LANCZOS)
                  for im in (photo, plain_r, outl)]
        cw, ch = panels[0].size
        sheet = Image.new("RGB", (cw * 3 + 24, ch), (20, 20, 20))
        for i, pnl in enumerate(panels):
            sheet.paste(pnl, (i * (cw + 12), 0))
        sheet.save(os.path.join(out, name + "_crop.jpg"), quality=90)
        if arg("mask"):
            ph = np.array(Image.open(arg("mask")).convert("L").crop(box)) > 127
            rn = np.array(alpha.crop(box)) > 127
            print("crop overlap (IoU) %.3f over %s" % ((ph & rn).sum() / max(1, (ph | rn).sum()), arg("crop")))
    # The difference, a number to drive by: the photo's gun (dark on its light ground, holes filled)
    # against the render's. Red: the photo's gun only; blue: the render's only.
    mask_p = arg("mask")
    if mask_p:
        ph = np.array(Image.open(mask_p).convert("L")) > 127
        rn = np.array(alpha) > 127
        inter = (ph & rn).sum()
        union = (ph | rn).sum()
        diff = np.full(ph.shape + (3,), 255, np.uint8)
        diff[ph & rn] = (190, 190, 190)
        diff[ph & ~rn] = (220, 40, 40)
        diff[rn & ~ph] = (40, 90, 230)
        Image.fromarray(diff).crop(crop).save(os.path.join(out, name + "_diff.png"))
        ppi2 = abs(a) ** 2
        print("overlap (IoU) %.3f; photo only %.2f sq in, render only %.2f sq in" % (
            inter / union, (ph & ~rn).sum() / ppi2, (rn & ~ph).sum() / ppi2))
    if arg("profile") and mask_p:
        ph = np.array(Image.open(mask_p).convert("L")) > 127
        rn = np.array(alpha) > 127

        def runs(m, f):
            # sample the column of design points at f, u from +2 down to -8 in 0.01" steps
            out_ = []
            cur = None
            for i in range(1001):
                u = 2.0 - i * 0.01
                z = a * w_of(f, u) + b
                x, y = int(round(z.real)), int(round(z.imag))
                on = 0 <= y < m.shape[0] and 0 <= x < m.shape[1] and m[y, x]
                if on and cur is None:
                    cur = u
                if not on and cur is not None:
                    out_.append((cur, u + 0.01))
                    cur = None
            return " ".join("[%.2f %.2f]" % r for r in out_)
        for f in [float(v) for v in arg("profile").split(",")]:
            print("f %6.2f  photo %-40s render %s" % (f, runs(ph, f), runs(rn, f)))
    print("scale %.2f photo px per inch; overlay %s" % (abs(a), os.path.join(out, name + "_overlay.jpg")))


main()
