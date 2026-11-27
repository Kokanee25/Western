"""#1295's contact sheets: per view and hour, A | B | C side by side (~800 px each), labelled.
  python3 experiments/street_width/sheet.py RESULTS_DIR   (reads build/sw/{A,B,C}/<view>_<hour>.png)"""
import sys, pathlib, subprocess
root = pathlib.Path(__file__).resolve().parents[2]
out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
src = root / "build/sw"
label = {"A": "A  as is (20.1 m)", "B": "B  16 m between fronts", "C": "C  as is, gaps filled, street dressed"}
for v in ("across", "mid_east", "mid_west", "saloon_door", "west_entry"):
	for h in ("noon", "golden"):
		tiles = []
		for k in "ABC":
			p = src / k / f"{v}_{h}.png"
			if not p.exists():
				continue
			t = src / f"_{k}_{v}_{h}.png"
			subprocess.run(["convert", str(p), "-resize", "800x", "-gravity", "NorthWest", "-fill", "white", "-undercolor", "#000000a0",
				"-pointsize", "22", "-annotate", "+8+6", label[k], str(t)], check=True)
			tiles.append(str(t))
		if tiles:
			subprocess.run(["convert", *tiles, "+append", "-quality", "85", str(out / f"{v}_{h}.jpg")], check=True)
print(sorted(p.name for p in out.glob("*.jpg")))
