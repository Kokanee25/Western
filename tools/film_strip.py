#!/usr/bin/env python3
"""A film strip for the cheap judge: the gang riding in at golden hour seen from a fixed camera,
eight frames 0.4 s apart once Brody is within 9 m of the street's middle (the 2026-11-03 session's
recipe; the walks_lineup walker doesn't draw under lavapipe). The game must be up
(tools/bridge.py start). --real turns the real look on first (docs/briefs/red-dead.md R0).

    python3 tools/bridge.py start --size=1280x720
    python3 tools/film_strip.py OUT_DIR [--real]
    python3 tools/bridge.py stop
"""
import math
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bridge  # noqa: E402

CENTRE = (11.5, -1.5)
NEAR = 9.0


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    out = os.path.abspath(argv[0])
    os.makedirs(out, exist_ok=True)
    real = "--real" in argv
    lines = ["time 17.6"]
    if real:
        lines.append("set settings.real_look true")
    lines += ["camera 6.5 1.7 -7.5 11.5 1.2 -1.5 55", "gang", "wait 2"]
    bridge.send(lines, timeout=1800)
    t0 = time.time()
    while time.time() - t0 < 1800:
        reply = bridge.send(["read people"], timeout=600)
        brody = _find_brody(reply)
        if brody is not None and math.hypot(brody[0] - CENTRE[0], brody[2] - CENTRE[1]) < NEAR:
            break
        bridge.send(["wait 1"], timeout=600)
    else:
        print("Brody never came within %.0f m" % NEAR, file=sys.stderr)
        return 1
    shots = []
    for i in range(8):
        shots.append("screenshot %s/frame_%02d.png" % (out, i))
        shots.append("wait 0.4")
    bridge.send(shots, timeout=3600)
    print("8 frames in %s" % out)
    return 0


def _find_brody(reply):
    """Brody's position from a `read people` reply (whatever shape send() hands back)."""
    stack = [reply]
    while stack:
        d = stack.pop()
        if isinstance(d, dict):
            if str(d.get("name", "")).lower().startswith("brody") and "at" in d:
                return d["at"]
            stack.extend(d.values())
        elif isinstance(d, list):
            stack.extend(d)
    return None


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
