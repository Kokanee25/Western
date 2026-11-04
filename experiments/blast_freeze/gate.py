#!/usr/bin/env python3
"""#492's gate on bf_blast runs (issue #596 step 3b): per run, the stick's worst frame after it went
off, the frames over 100 and 50 ms, how long until the frames are back under 20 ms (50 fps) and
stay there for 0.25 s, and the mean of the 5 s after; all here and at Sean's (x0.65).

  python3 experiments/blast_freeze/gate.py RUN.json [RUN.json...]
"""
import json, sys

SEAN = 0.65


def gate(path):
    s = json.load(open(path))
    fr = [f for f in s["frames"] if f.get("after", -1) >= 0]
    ms = [float(f["ms"]) for f in fr]
    worst = max(ms) if ms else 0.0
    # Back above 50 fps: the first frame from which 15 frames running are all under 20 ms (Sean's).
    t, back = 0.0, None
    for i in range(len(ms)):
        if all(m * SEAN < 20.0 for m in ms[i:i + 15]) and len(ms[i:i + 15]) == 15:
            back = t
            break
        t += ms[i] / 1000.0
    first5 = []
    t = 0.0
    for m in ms:
        if t > 5.0:
            break
        first5.append(m)
        t += m / 1000.0
    st = s.get("setup", {})
    return {
        "run": path.split("/")[-1], "lift": st.get("blast_lift"), "men": len(st.get("men", [])),
        "thrown_m": [round(m["thrown_to"], 1) for m in st.get("men", [])],
        "worst": round(worst), "worst_sean": round(worst * SEAN), "over100_sean": sum(1 for m in ms if m * SEAN > 100),
        "over50_sean": sum(1 for m in ms if m * SEAN > 50), "back_50fps_s": None if back is None else round(back, 2),
        "mean5_sean": round(sum(first5) / max(len(first5), 1) * SEAN, 1), "broken": st.get("broken"),
    }


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(json.dumps(gate(p)))
