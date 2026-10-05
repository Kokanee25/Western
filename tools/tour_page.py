#!/usr/bin/env python3
"""The tour's page on GitHub Pages (/tour/): the latest build's tour video to watch on a phone,
and the few before it. Run on a folder holding build-<N>.mp4 files; keeps the newest KEEP, copies
the newest to latest.mp4 and writes index.html.

    python3 tools/tour_page.py site/tour [--settings="what the render left out"]
"""
import html
import os
import re
import shutil
import sys

KEEP = 8


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    folder = argv[0]
    settings = next((a.split("=", 1)[1] for a in argv[1:] if a.startswith("--settings=")), "")
    os.makedirs(folder, exist_ok=True)
    videos = []
    for f in os.listdir(folder):
        m = re.fullmatch(r"build-(\d+)\.mp4", f)
        if m:
            videos.append((int(m.group(1)), f))
    videos.sort(reverse=True)
    for _, f in videos[KEEP:]:
        os.remove(os.path.join(folder, f))
    videos = videos[:KEEP]
    if videos:
        shutil.copyfile(os.path.join(folder, videos[0][1]), os.path.join(folder, "latest.mp4"))
    rows = "\n".join(
        f'<li><a href="{f}">Build {n}</a></li>' for n, f in videos[1:])
    latest = (f'<video src="latest.mp4" controls playsinline preload="metadata"></video>'
              f'<p class="cap">Build {videos[0][0]}</p>') if videos else "<p>No tour yet.</p>"
    note = f'<p class="note">{html.escape(settings)}</p>' if settings else ""
    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Salt Creek tour</title>
<style>
body {{ margin: 0; padding: 16px; background: #15100c; color: #ead9bf; font: 16px/1.4 Georgia, serif; }}
h1 {{ font-size: 22px; margin: 0 0 12px; }}
video {{ width: 100%; max-width: 1280px; background: #000; border-radius: 4px; }}
.cap {{ margin: 6px 0 16px; color: #c9a97a; }}
.note {{ font-size: 13px; color: #9c8a70; }}
a {{ color: #e8b56a; }}
ul {{ padding-left: 20px; }}
</style></head><body>
<h1>Salt Creek: the tour</h1>
{latest}
{note}
<h2 style="font-size:17px">Earlier builds</h2>
<ul>{rows or "<li>none yet</li>"}</ul>
<p><a href="../">Play in the browser</a></p>
</body></html>
"""
    with open(os.path.join(folder, "index.html"), "w") as f:
        f.write(page)
    print(f"tour page: {len(videos)} videos")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
