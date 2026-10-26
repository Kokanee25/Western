"""The cinematic workflow's helpers (.github/workflows/cinematic.yml).

    python tools/cinematic/ci.py error LOG     # the log's tail as one error annotation
    python tools/cinematic/ci.py publish DIR   # DIR/out and the log's tail to the cinematic-results branch
    python tools/cinematic/ci.py font          # the title's font (Rye, SIL OFL) into build/fonts/
"""
import glob
import os
import shutil
import subprocess
import sys
import urllib.request

FONT_URL = "https://raw.githubusercontent.com/google/fonts/main/ofl/rye/Rye-Regular.ttf"
FONT = "build/fonts/Rye-Regular.ttf"
NOISE = ("DeprecationWarning", "use_nodes", "INFO:", "| INFO")


def error(log):
    lines = [l.rstrip() for l in open(log, errors="replace") if not any(n in l for n in NOISE)]
    print("::error::" + "%0A".join(lines[-30:]))


def sh(*cmd, check=True):
    return subprocess.run(cmd, check=check)


def publish(d):
    run = os.environ.get("GITHUB_RUN_ID", "local")
    dest = "/tmp/res/" + run
    os.makedirs(dest, exist_ok=True)
    log = os.path.join(d, "blender.log")
    if os.path.exists(log):
        with open(log, errors="replace") as f:
            lines = [l for l in f if not any(n in l for n in NOISE)]
        open(os.path.join(dest, "blender_tail.log"), "w").writelines(lines[-300:])
    out = os.path.join(d, "out")
    for f in glob.glob(os.path.join(out, "**", "*"), recursive=True):
        if os.path.isdir(f):
            continue
        rel = os.path.relpath(f, out)
        target = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        if f.endswith(".png"):
            from PIL import Image
            Image.open(f).convert("RGB").save(target[:-4] + ".jpg", quality=90)
        else:
            shutil.copy(f, target)
    sh("git", "config", "user.name", "github-actions")
    sh("git", "config", "user.email", "github-actions@users.noreply.github.com")
    for attempt in range(4):
        if subprocess.run(["git", "fetch", "-q", "origin", "cinematic-results"]).returncode == 0:
            sh("git", "checkout", "-q", "-f", "-B", "cinematic-results", "FETCH_HEAD")
        else:
            sh("git", "checkout", "-q", "--orphan", "cinematic-results")
            sh("git", "rm", "-rq", "--cached", ".", check=False)
        os.makedirs("results", exist_ok=True)
        shutil.copytree(dest, os.path.join("results", run), dirs_exist_ok=True)
        sh("git", "add", "-f", os.path.join("results", run))
        sh("git", "commit", "-q", "-m", "Cinematic results, run %s (%s)" % (run, os.environ.get("GITHUB_SHA", "")[:8]))
        if subprocess.run(["git", "push", "-q", "origin", "cinematic-results"]).returncode == 0:
            print("published results/%s" % run)
            return
    sys.exit("could not push the results")


def font():
    os.makedirs(os.path.dirname(FONT), exist_ok=True)
    if not os.path.exists(FONT):
        with urllib.request.urlopen(FONT_URL, timeout=60) as r, open(FONT, "wb") as f:
            f.write(r.read())
    print("font", FONT, os.path.getsize(FONT))


if __name__ == "__main__":
    what = sys.argv[1]
    if what == "error":
        error(sys.argv[2])
    elif what == "publish":
        publish(sys.argv[2])
    elif what == "font":
        font()
