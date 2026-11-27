"""#1304's sheets: per view and hour, A (as it was: #1295's render, the left third of results/<view>_<hour>.jpg,
or build/sw/A/<view>_<hour>.png if it's there) | D (as it is now: Main Street dressed by ValleyStreetDressing),
~800 px each, labelled.
  python3 experiments/street_width/shots.py build/sw/D                  # D: the game as it is (dressing on)
  python3 experiments/street_width/sheet_dressed.py experiments/street_width/dressed"""
import sys, pathlib, subprocess
root = pathlib.Path(__file__).resolve().parents[2]
out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
(out / ".gdignore").touch()
src = root / "build/sw"
old = root / "experiments/street_width/results"
for v in ("across", "mid_east", "mid_west", "saloon_door", "west_entry"):
	for h in ("noon", "golden"):
		d = src / "D" / f"{v}_{h}.png"
		if not d.exists():
			continue
		a_png = src / "A" / f"{v}_{h}.png"
		ta = src / f"_A_{v}_{h}.png"
		if a_png.exists():
			subprocess.run(["convert", str(a_png), "-resize", "800x", "-gravity", "NorthWest", "-fill", "white", "-undercolor", "#000000a0",
				"-pointsize", "22", "-annotate", "+8+6", "A  as it was (bare)", str(ta)], check=True)
		else:
			subprocess.run(["convert", str(old / f"{v}_{h}.jpg"), "-crop", "800x450+0+0", "+repage", str(ta)], check=True)
		td = src / f"_D_{v}_{h}.png"
		subprocess.run(["convert", str(d), "-resize", "800x", "-gravity", "NorthWest", "-fill", "white", "-undercolor", "#000000a0",
			"-pointsize", "22", "-annotate", "+8+6", "D  as is, Main Street dressed (#1304)", str(td)], check=True)
		subprocess.run(["convert", str(ta), str(td), "+append", "-quality", "85", str(out / f"{v}_{h}.jpg")], check=True)
print(sorted(p.name for p in out.glob("*.jpg")))
