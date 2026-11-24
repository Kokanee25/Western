#!/usr/bin/env python3
"""Saloon B's walls (#1030, S5) on the judging stand, as S1's and the stage's (s1_sheet.py: the stand on
the road east of town, its boarded wall and beam, noon and night by a hanging lamp), through the dev
bridge (experiments/prop_lab/bridge.gd). The wall clock first (its hands at the town's time, its
pendulum swinging); then the room (place_views.gd) judges them where they hang.

    python3 experiments/prop_lab/saloon/walls_sheet.py --out=DIR [--groups=clock] [--size=960x540]

DIR/<group>_<noon|night>.png and DIR/sheet.jpg. ~1-2 min a group under lavapipe.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import stage_sheet as st  # noqa: E402

WALL = st.WALL

st.GROUPS = {
    # The regulator, its dial at ~1.9 m, seen from a man's eye a step off and a little to the side.
    "clock": {"props": [("wall_clock", 0.0, 1.05, WALL, 0, None, None)],
              "cam": ((0.45, 1.7, WALL + 1.25), (0.0, 1.62, WALL), 50), "night_lamp": 0.7},
    # Close on the dial (the hands, the numerals, the glass).
    "dial": {"props": [("wall_clock", 0.0, 1.05, WALL, 0, None, None)],
             "cam": ((0.12, 1.74, WALL + 0.45), (0.0, 1.72, WALL), 50), "night_lamp": 0.6},
}

if __name__ == "__main__":
    st.main()
