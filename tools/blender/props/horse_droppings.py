"""Horse droppings in the street: a scatter of six or seven balls, some broken open and trodden,
~0.3 m across. Part: lumps (dung)."""
import numpy as np

import common as C


def build():
    rng = np.random.default_rng(47)
    part = C.Part("lumps")
    for i in range(7):
        r = rng.uniform(0.028, 0.04)
        x, z = rng.uniform(-0.11, 0.11), rng.uniform(-0.09, 0.09)
        squash = rng.uniform(0.55, 0.85)
        part.merge(C.blob("lump", (x, r * squash * 0.8, z), (r * 1.1, r * squash, r), rings=5, sides=8, squash_bottom=0.0, noise=0.12,
                          seed=int(rng.integers(1000))))
    return C.export("horse_droppings", [part])
