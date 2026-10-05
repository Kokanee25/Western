#!/usr/bin/env python3
"""The playtest's runner (tools/playtest.md): the game under xvfb with the dev bridge, and
screenshots kept for the report in docs/playtests/<date>/.

    python3 tools/playtest.py start [--date=YYYY-MM-DD]
    python3 tools/playtest.py shot NAME
    python3 tools/playtest.py stop
"""
import datetime
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(ROOT, "build", "bridge", "playtest_dir")
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]


def main(argv):
    if not argv:
        print(__doc__)
        return 0
    if argv[0] == "start":
        date = next((a.split("=", 1)[1] for a in argv if a.startswith("--date=")), datetime.date.today().isoformat())
        folder = os.path.join(ROOT, "docs", "playtests", date)
        os.makedirs(folder, exist_ok=True)
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        with open(STATE, "w") as f:
            f.write(folder)
        r = subprocess.call(BRIDGE + ["start", "--size=960x540"])
        if r == 0:
            print(f"date {date}; screenshots go in docs/playtests/{date}/; the report is docs/playtests/{date}.md")
        return r
    if argv[0] == "shot":
        folder = open(STATE).read().strip()
        name = argv[1] if len(argv) > 1 else "shot"
        path = os.path.join(folder, name if name.endswith(".png") else name + ".png")
        return subprocess.call(BRIDGE + [f"screenshot {path}"])
    if argv[0] == "stop":
        return subprocess.call(BRIDGE + ["stop"])
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
