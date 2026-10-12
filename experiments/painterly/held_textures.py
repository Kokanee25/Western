"""Tileable textures for the modelled revolver (experiments/painterly/held_metal.gdshader):
case colours, bluing, brass, walnut. RGB the colour, A a noise the shader wears and roughens by.
Made from filtered noise (periodic, so every texture tiles); nothing painted by hand.
  python3 experiments/painterly/held_textures.py   →  assets/held/<name>.png
"""
import os

import numpy as np
from PIL import Image

N = 512
OUT = "assets/held"
rng = np.random.default_rng(1873)


def noise(scale, aniso=(1.0, 1.0), power=2.0):
    """Periodic noise: white noise filtered to features about `scale` texels across (aniso stretches
    them along x, y), normalised to 0..1."""
    f = np.fft.fft2(rng.normal(size=(N, N)))
    ky = np.fft.fftfreq(N)[:, None] * aniso[1]
    kx = np.fft.fftfreq(N)[None, :] * aniso[0]
    k = np.sqrt(kx * kx + ky * ky) * scale
    g = np.real(np.fft.ifft2(f * np.exp(-(k ** power))))
    g -= g.min()
    return g / g.max()


def fbm(scales, weights, aniso=(1.0, 1.0)):
    out = sum(w * noise(s, aniso) for s, w in zip(scales, weights))
    out -= out.min()
    return out / out.max()


def ramp(x, stops):
    xs = [s[0] for s in stops]
    cols = np.array([s[1] for s in stops], float)
    return np.stack([np.interp(x, xs, cols[:, c]) for c in range(3)], -1)


def save(name, rgb, a):
    img = np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)[..., None]], -1)
    Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, name + ".png"))
    print("wrote", name)


os.makedirs(OUT, exist_ok=True)

# Case colours, faded with use: mottled straw, brown, slate blue and violet over grey steel.
m1 = fbm([70, 25, 8], [1.0, 0.45, 0.15])
m2 = fbm([90, 30], [1.0, 0.4])
case = ramp(m1, [(0.0, (0.22, 0.25, 0.32)), (0.25, (0.33, 0.36, 0.43)), (0.42, (0.44, 0.43, 0.42)),
                 (0.55, (0.50, 0.45, 0.36)), (0.68, (0.40, 0.35, 0.33)), (0.82, (0.32, 0.30, 0.38)),
                 (1.0, (0.24, 0.27, 0.36))])
grey = np.array([0.46, 0.45, 0.44])
case = case * (0.55 + 0.45 * m2[..., None]) + grey * (0.45 - 0.45 * m2[..., None])
save("case", case, fbm([8, 3], [1.0, 0.6]))

# Bluing: near black with a blue cast, thinner (plum brown) in patches.
b = fbm([50, 12, 4], [1.0, 0.35, 0.15])
blued = ramp(b, [(0.0, (0.06, 0.07, 0.10)), (0.6, (0.09, 0.10, 0.14)), (0.8, (0.14, 0.12, 0.14)),
                 (1.0, (0.22, 0.17, 0.16))])
save("blued", blued, fbm([10, 3], [1.0, 0.5]))

# Brass, darkened unevenly with handling.
t = fbm([30, 8], [1.0, 0.4])
brass = ramp(t, [(0.0, (0.42, 0.32, 0.15)), (0.5, (0.62, 0.48, 0.24)), (1.0, (0.74, 0.60, 0.33))])
save("brass", brass, fbm([6, 2], [1.0, 0.5]))

# Walnut: grain running down the texture (v), dark lines, pores, oiled and handled.
g1 = fbm([30, 10, 3], [1.0, 0.5, 0.3], aniso=(1.0, 0.08))
lines = np.sin(g1 * 70.0) * 0.5 + 0.5
fig = fbm([60], [1.0], aniso=(1.0, 0.15))
pores = noise(1.2) > 0.72
w = 0.55 * lines ** 3 + 0.45 * fig
walnut = ramp(w, [(0.0, (0.16, 0.08, 0.04)), (0.45, (0.27, 0.14, 0.07)), (0.75, (0.36, 0.19, 0.09)),
                  (1.0, (0.45, 0.26, 0.12))])
walnut[pores] *= 0.7
save("walnut", walnut, fbm([20, 4], [1.0, 0.5], aniso=(1.0, 0.1)))

# Skin: a fine mottle (RGB near white, multiplied by the skin tone) and pores in alpha.
mot = fbm([25, 6, 1.5], [1.0, 0.5, 0.35])
skin = np.stack([0.9 + 0.1 * mot, 0.88 + 0.12 * mot, 0.88 + 0.12 * mot], -1)
save("skin", skin, 1.0 - 0.6 * (noise(0.9) > 0.8))

# Wool for the coat's sleeve: a twill's diagonal over a mottle; linen for the cuff.
yy, xx = np.mgrid[0:N, 0:N]
twill = (np.sin((xx + yy) * 2 * np.pi / 6.4) * 0.5 + 0.5)
wool = fbm([12, 3], [1.0, 0.5])
save("wool", np.repeat((0.75 + 0.15 * wool + 0.1 * twill)[..., None], 3, -1), wool)
weave = (np.sin(xx * 2 * np.pi / 4) * np.sin(yy * 2 * np.pi / 4)) * 0.5 + 0.5
lin = fbm([20, 4], [1.0, 0.4])
save("linen", np.repeat((0.85 + 0.08 * lin + 0.07 * weave)[..., None], 3, -1), lin)
