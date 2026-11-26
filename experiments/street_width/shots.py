"""#1295's five fixed views at noon and 17:36 (18:30 is past sunset on the valley's date), one game run (the real look, the valley, its folk in).
  python3 experiments/street_width/shots.py OUT_DIR [--dress] [--width=W] [--only=a,b]
The views follow the street's width (valley.json's, or --width for version B's override), so each
stands on the same walk or the same door in every version."""
import json, os, subprocess, sys, pathlib
root = pathlib.Path(__file__).resolve().parents[2]
args = [a for a in sys.argv[1:] if not a.startswith("--")]
opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
out = pathlib.Path(args[0]).resolve(); out.mkdir(parents=True, exist_ok=True)
v = json.loads((root / "config/valley.json").read_text())
F = float(opt.get("width", v["town"]["main_street"]["width_between_fronts"])) / 2
g = lambda x, z: -0.006 * x - 0.032 * z  # the town's ground plane (valley.json town.ground)
E = 1.65
views = {
	# On the south walk before the bank, looking across at the hotel, the yard and saloon B.
	"across": ((44.5, g(44.5, F) + 0.75 + E, F - 0.5), (36.0, g(36, -F) + 3.5, -F - 4.0)),
	# The street's middle, looking along it east and west.
	"mid_east": ((-40.0, g(-40, 0) + E, 0.8), (60.0, g(60, 0) + 2.2, 0.0)),
	"mid_west": ((40.0, g(40, 0) + E, -0.8), (-80.0, g(-80, 0) + 2.2, 0.0)),
	# Saloon B's corner door (its walk at 0.95 over the pad's 0.15), looking out across and down the street east.
	"saloon_door": ((8.9, 0.15 + 0.95 + E, -(F - 0.7)), (18.0, g(18, F) + 2.0, F + 6.0)),
	# Walking in from the west end on the ore road.
	"west_entry": ((-150.0, g(-150, 0) + E, 1.2), (0.0, g(0, 0) + 2.5, 0.0)),
}
only = set(opt["only"].split(",")) if "only" in opt else None
cmds = ["wait 4"]
if "dress" in opt:
	cmds += ["street_dress", "wait 4"]
for hour, tag in ((12.0, "noon"), (17.6, "golden")):
	cmds += ["time %s" % hour, "wait 4"]
	for name, (e, t) in views.items():
		if only and name not in only:
			continue
		cmds += ["camera %.2f %.2f %.2f %.2f %.2f %.2f 70" % (*e, *t), "wait 3", "screenshot %s/%s_%s.png" % (out, name, tag)]
cmds += ["read frame"]
import shutil
for d in ("blackbox", "crash_reports"):
	shutil.rmtree(os.path.expanduser("~/.local/share/godot/app_userdata/Salt Creek/" + d), ignore_errors=True)
log = open(out / "bridge.log", "w")
subprocess.run(["python3", "tools/bridge.py", "start", "--size=1280x720", "--game-args=--real,--world=valley,--crash-watch=40,180"], cwd=root, stdout=log, stderr=log)
subprocess.run(["python3", "tools/bridge.py", "--timeout=1500"] + cmds, cwd=root, stdout=log, stderr=log)
subprocess.run(["python3", "tools/bridge.py", "stop"], cwd=root, stdout=log, stderr=log)
print(sorted(p.name for p in out.glob("*.png")))
