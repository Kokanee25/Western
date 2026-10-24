"""The horse's coat and tack painted per texel (numpy; tools/blender/horse.py bakes the passes).

Each texel knows where it is on the horse at rest (position), which way it faces (the sculpt's
normal, so the muscles show) and how much it's tucked in (occlusion). From those it gets its
colour as a painter would lay it: the bay's red-brown with its black points, white socks over dark
hooves as the street painting's horse has, the mane and tail in black strands; light painted in
from above as the men's paint has it (body_skin.gdshaderinc lights it again, by brightness only),
and the tones cut to a few steps so it reads as blocks of colour, not a photograph.

The tack the same way: dark stock-saddle leather worn pale on its edges, a tan seat, a wool
blanket with a striped edge, iron, silver conchos.
"""
import numpy as np

import horse_shape as hs


def _hex(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


# The street painting's horse (docs/concept/street-golden-hour-painted.png, the livery rail),
# measured off its lit flank, its shaded belly and its points.
BAY = _hex("7c3d1f")
BAY_LIGHT = _hex("a65a30")
BAY_DARK = _hex("3e1c0f")
POINTS = _hex("1c1410")
SOCK = _hex("e6dccb")
HOOF = _hex("3a3330")
MANE = _hex("15100d")
MANE_LIGHT = _hex("4a3a30")


def value_noise(p, scale, seed):
    """Smooth 3D value noise in [0, 1] at `scale` cells a metre."""
    rng = np.random.default_rng(seed)
    table = rng.random((64, 64, 64))
    q = p * scale
    i = np.floor(q).astype(int)
    f = q - i
    f = f * f * (3.0 - 2.0 * f)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[..., 0] if dx else 1 - f[..., 0]) * (f[..., 1] if dy else 1 - f[..., 1]) * (f[..., 2] if dz else 1 - f[..., 2])
                out = out + w * table[(i[..., 0] + dx) % 64, (i[..., 1] + dy) % 64, (i[..., 2] + dz) % 64]
    return out


def fbm(p, scale, seed, octaves=3):
    out = 0.0
    amp = 0.5
    total = 0.0
    for o in range(octaves):
        out = out + amp * value_noise(p, scale * (2 ** o), seed + o)
        total += amp
        amp *= 0.5
    return out / total


def strands(p, along, scale, seed):
    """Streaks running along `along` (hair): noise squeezed along the direction."""
    a = np.asarray(along, float)
    a = a / np.linalg.norm(a)
    q = p - (p @ a)[..., None] * a * 0.92  # stretch along the hair
    return value_noise(q, scale, seed)


SUN = np.array([0.25, -0.35, 0.9])
SUN = SUN / np.linalg.norm(SUN)


def painted_light(normal, ao):
    """The light painted in: soft from above, a little from his left, tucked-in places dark."""
    key = np.clip(normal @ SUN, 0.0, 1.0)
    sky = 0.5 + 0.5 * normal[..., 2]
    # Soft: the game lights him again (the men's hybrid finish, HumanBody.paint_look); this keeps
    # the sculpt's muscles and creases the low mesh can't.
    light = 0.6 + 0.26 * key + 0.14 * sky
    return light * (0.5 + 0.5 * ao ** 1.3)


def tone(base, light_col, dark_col, light, steps=7):
    """A colour between its dark and light by `light` (0..1.2), cut to `steps` tones."""
    l = np.clip(light, 0.0, 1.25)
    if steps:
        l = np.round(l * steps) / steps
    lo = np.clip(l / 0.7, 0.0, 1.0)[..., None]
    hi = np.clip((l - 0.7) / 0.5, 0.0, 1.0)[..., None]
    return dark_col + (base - dark_col) * lo + (light_col - base) * hi


def _smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def coat(pos, normal, ao, part, mask):
    """The coat (part 0: the horse; part 1: the tail's hair) as an (h, w, 3) sRGB image."""
    h, w = pos.shape[:2]
    p = pos.reshape(-1, 3)
    n = normal.reshape(-1, 3)
    n = n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-6)
    a = ao.reshape(-1)
    light = painted_light(n, a)
    x, y, z = p[:, 0], p[:, 1], p[:, 2]
    rough = fbm(p, 9.0, 11)  # a painter's uneven hand: dapples, the coat's lie
    light = light * (0.9 + 0.2 * rough)

    # The bay: lighter on the flank and quarters, darker along the topline and under the belly.
    base = np.tile(BAY, (len(p), 1))
    top = _smooth(z, 1.42, 1.56)[:, None]
    base = base * (1.0 - 0.18 * top)
    belly = _smooth(-z, -1.02, -0.9)[:, None]
    base = base * (1.0 - 0.15 * belly)
    out = tone(base, BAY_LIGHT, BAY_DARK, light)

    # Black points: the legs from the knee and hock down, ragged where they meet the red.
    edge = (fbm(p, 22.0, 5) - 0.5) * 0.09
    front = x < 0.0
    knee = np.where(front, 0.6, 0.66) + edge
    dark_leg = _smooth(-z, -(knee + 0.08), -knee)
    hair = strands(p, (0, 0, 1), 60.0, 7)
    points = tone(np.tile(POINTS, (len(p), 1)) * (0.9 + 0.25 * hair[:, None]), POINTS * 2.4, POINTS * 0.6, light)
    out = out + (points - out) * dark_leg[:, None]

    # White socks over the fetlock, the hooves dark and streaked.
    sock_top = 0.2 + edge * 0.6 + np.where(front, 0.0, 0.015)
    sock = (z < sock_top) & (z > 0.07)
    socks = tone(np.tile(SOCK, (len(p), 1)), SOCK * 1.05, SOCK * 0.55, light, 6)
    out[sock] = socks[sock]
    hoof_line = 0.075 - 0.03 * np.clip((x - np.where(front, -0.66, 0.62)) / 0.1, 0.0, 1.0)
    hoof = z < hoof_line + 0.006
    streak = strands(p, (0, 0, 1), 90.0, 9)[:, None]
    hooves = tone(np.tile(HOOF, (len(p), 1)) * (0.8 + 0.4 * streak), HOOF * 1.7, HOOF * 0.5, light, 5)
    out[hoof] = hooves[hoof]

    # The head: a dark muzzle, nostrils, eyes with a glint, the ears' rims dark.
    rel = p - np.array([hs.POLL[0], 0.0, hs.POLL[1]])
    along = rel @ hs.HEAD_DIR
    face = rel @ hs.HEAD_FACE
    on_head = (x < -1.0) & (z > 1.3)
    muzzle = _smooth(along, 0.46, 0.6) * on_head
    dark_muzzle = tone(np.tile(POINTS * 1.5, (len(p), 1)), BAY_DARK * 0.9, POINTS * 0.5, light)
    out = out + (dark_muzzle - out) * (muzzle * 0.85)[:, None]
    for s in (-1.0, 1.0):
        nostril = np.linalg.norm(np.stack([along - 0.6, face - 0.035, y - s * 0.04], 1), axis=1) < 0.022
        out[nostril & on_head] = POINTS * 0.4
        eye_c = hs._head_point(0.17, 0.045, s * 0.088)
        de = np.linalg.norm(p - eye_c, axis=1)
        eye = de < 0.03
        out[eye] = POINTS * 0.55
        glint_c = eye_c + np.array([-0.012, s * 0.02, 0.012])
        out[np.linalg.norm(p - glint_c, axis=1) < 0.0045] = np.array([0.55, 0.52, 0.5])
        ear_mid = np.array([hs.POLL[0] - 0.005, s * 0.078, hs.POLL[1] + 0.12])
        ear = (z > hs.POLL[1] + 0.06) & (np.abs(y) > 0.04) & (np.linalg.norm(p - ear_mid, axis=1) < 0.12)
        rim = ear & (z > hs.POLL[1] + 0.16)
        out[rim] = out[rim] * 0.35 + POINTS * 0.65
        inner = ear & (n[:, 0] < -0.4) & (np.abs(y) < 0.085 + 0.03 * (z - hs.POLL[1]))
        out[inner] = out[inner] * 0.45

    # The mane and forelock, and the tail's hair: black in strands.
    mane = _mane_mask(p)
    mane_dir = np.array([0.15, 0.6, -0.8])
    mstr = strands(p, mane_dir, 70.0, 13)[:, None]
    hair_col = MANE + (MANE_LIGHT - MANE) * np.clip(mstr * 1.4 - 0.45, 0, 1)
    manes = tone(hair_col, hair_col * 2.2, hair_col * 0.5, light, 6)
    out[mane] = manes[mane]
    tail = part.reshape(-1) > 0.5
    tstr = strands(p, (0.1, 0.0, -1.0), 80.0, 17)[:, None]
    tail_col = MANE + (MANE_LIGHT - MANE) * np.clip(tstr * 1.5 - 0.5, 0, 1)
    tails = tone(tail_col, tail_col * 2.2, tail_col * 0.5, light, 6)
    out[tail] = tails[tail]

    img = np.clip(out, 0.0, 1.0).reshape(h, w, 3)
    img[~mask] = BAY_DARK  # texels no face covers (the margin fills them first)
    return img


def _mane_mask(p):
    """Texels on the mane's ridge and its hang, and the forelock (horse_shape's mane parts)."""
    d = np.full(len(p), 1e9)
    crest = [(-1.11, 2.02), (-0.98, 1.92), (-0.84, 1.81), (-0.7, 1.69), (-0.57, 1.6), (-0.47, 1.56)]
    for i in range(len(crest) - 1):
        a = (crest[i][0], 0.035, crest[i][1] - 0.01)
        b = (crest[i + 1][0], 0.035, crest[i + 1][1] - 0.01)
        d = np.minimum(d, hs.round_cone(p, a, b, 0.045, 0.04))
        ha = (crest[i][0] + 0.02, 0.1, crest[i][1] - 0.09)
        hb = (crest[i + 1][0] + 0.02, 0.1, crest[i + 1][1] - 0.09)
        d = np.minimum(d, hs.round_cone(p, ha, hb, 0.04, 0.035))
    d = np.minimum(d, hs.flat_cone(p, hs._head_point(-0.01, 0.07), hs._head_point(0.16, 0.085), 0.045, 0.03, 0.8))
    on_top = p[:, 2] > 1.45
    # The crest's top on the near (left) side too: the mane parts over it.
    crest_line = np.interp(p[:, 0], [c[0] for c in crest], [c[1] for c in crest], left=9.0, right=9.0)
    near_top = (p[:, 0] > -1.12) & (p[:, 0] < -0.5) & (p[:, 2] > crest_line - 0.035) & (p[:, 1] > -0.05)
    return ((d < 0.012) & on_top) | near_top


# --- tack ---------------------------------------------------------------------------------------

LEATHER = _hex("4a2a17")
LEATHER_LIGHT = _hex("8a5a35")
SEAT = _hex("9a8a6c")
BLANKET = _hex("a39478")
STRIPE_RED = _hex("8c2f22")
STRIPE_DARK = _hex("2e2620")
BAGS = _hex("6b4024")
IRON = _hex("55555a")
SILVER = _hex("c9c6bd")
CINCH = _hex("8a7d66")
WOOD = _hex("6e4a2a")

# Part ids (horse.py's TACK parts): what each is painted as.
PARTS = {1: "blanket", 2: "saddle", 3: "horn", 4: "stirrup", 5: "cinch", 6: "bags", 7: "bridle", 8: "iron",
         9: "silver", 10: "reins"}


def tack(pos, normal, ao, curv, part, mask):
    h, w = pos.shape[:2]
    p = pos.reshape(-1, 3)
    n = normal.reshape(-1, 3)
    n = n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-6)
    a = ao.reshape(-1)
    c = curv.reshape(-1)
    pid = np.rint(part.reshape(-1) * 16.0).astype(int)
    light = painted_light(n, a) * (0.9 + 0.2 * fbm(p, 14.0, 3))
    worn = np.clip((c - 0.5) * 6.0, 0.0, 1.0)  # convex edges rubbed pale
    out = np.zeros((len(p), 3))

    def paint(sel, base, lift=2.0, drop=0.5, steps=7, wear=0.0):
        b = np.tile(base, (len(p), 1))
        b = b + (np.minimum(base * 1.8, 1.0) - b) * (worn * wear)[:, None]
        col = tone(b, np.minimum(base * lift, 1.0), base * drop, light, steps)
        out[sel] = col[sel]

    leather = (pid == 2) | (pid == 3) | (pid == 7) | (pid == 10)
    tool = fbm(p, 40.0, 21)  # the skirts' tooling, a fine figure in the leather
    lb = LEATHER * (0.88 + 0.24 * tool[:, None])
    b = lb + (LEATHER_LIGHT - lb) * (worn * 0.35)[:, None]
    col = tone(b, LEATHER * 1.75, LEATHER * 0.45, light)
    out[leather] = col[leather]
    # The seat: suede, tan, where the rider sits (the saddle's top between the swell and cantle).
    seat = (pid == 2) & (p[:, 0] > -0.3) & (p[:, 0] < 0.0) & (np.abs(p[:, 1]) < 0.15) & (n[:, 2] > 0.55) & (p[:, 2] > 1.58)
    paint(seat, SEAT, 1.3, 0.55, 6)
    paint(pid == 6, BAGS, 1.8, 0.45, 7, 0.7)
    paint(pid == 4, WOOD, 1.7, 0.5, 6, 0.5)
    paint(pid == 8, IRON, 1.9, 0.45, 5)
    paint(pid == 9, SILVER, 1.15, 0.5, 5)
    # The cinch: mohair strands across it.
    cstr = strands(p, (0, 0, 1), 70.0, 31)[:, None]
    cin = (pid == 5)
    cb = CINCH * (0.8 + 0.35 * cstr)
    col = tone(cb, CINCH * 1.4, CINCH * 0.45, light, 6)
    out[cin] = col[cin]
    # The blanket: wool, with a red and a dark stripe a hand in from its edge, front and back.
    bl = pid == 1
    wool = fbm(p, 50.0, 41)[:, None]
    bb = BLANKET * (0.88 + 0.22 * wool)
    xs = p[:, 0]
    stripe_r = (np.abs(xs - (-0.47)) < 0.025) | (np.abs(xs - 0.13) < 0.025)
    stripe_d = (np.abs(xs - (-0.42)) < 0.012) | (np.abs(xs - 0.08) < 0.012) | (p[:, 2] < 1.03)
    bb[stripe_r] = STRIPE_RED
    bb[stripe_d & ~stripe_r] = STRIPE_DARK
    col = tone(bb, BLANKET * 1.25, BLANKET * 0.4, light, 6)
    out[bl] = col[bl]
    img = np.clip(out, 0.0, 1.0).reshape(h, w, 3)
    img[~mask] = LEATHER
    return img
