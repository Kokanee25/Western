"""Cut the cinematic (docs/briefs/cinematic.md): the rendered frames, faded, graded with grain and a
vignette, letterboxed into 16:9, with the sound mixed from assets/cinematic/audio by timeline.CUES.

    python tools/cinematic/cut.py --frames=DIR --quality=preview|final --out=FILE.mp4
"""
import os
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import timeline as T  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AUDIO = os.path.join(ROOT, "assets", "cinematic", "audio")


def args():
    return {k: v for k, _, v in (a[2:].partition("=") for a in sys.argv[1:] if a.startswith("--"))}


def brightness(t):
    for a, b, x, y in T.FADES:
        if a <= t < b:
            u = (t - a) / (b - a)
            u = u * u * (3 - 2 * u)
            return x + (y - x) * u
    return 1.0


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True).stdout.strip()
    return float(out or 0)


def frames(src, step, tmp):
    from PIL import Image, ImageEnhance
    os.makedirs(tmp, exist_ok=True)
    names = sorted(n for n in os.listdir(src) if n.endswith(".png"))
    size = Image.open(os.path.join(src, names[0])).size
    blank = Image.new("RGB", size, (0, 0, 0))
    last = blank
    missing = 0
    n = 0
    for f in range(0, T.frame(T.LENGTH), step):
        path = os.path.join(src, "f%04d.png" % f)
        t = f / T.FPS
        if os.path.exists(path):
            im = Image.open(path).convert("RGB")
            last = im
        elif 49.0 <= t < 50.0:
            im = blank
        else:
            im = last
            missing += 1
        k = brightness(t)
        if k < 0.999:
            im = ImageEnhance.Brightness(im).enhance(k)
        im.save(os.path.join(tmp, "s%05d.png" % n))
        n += 1
    print("frames", n, "missing", missing, "size", size, flush=True)
    return n, size


def mix_args(start_index):
    """ffmpeg inputs and the filter that mixes every cue."""
    inputs, parts, labels = [], [], []
    i = start_index
    for name, at, gain, frm, length, fin, fout in T.CUES:
        fname = T.VOICE if name == "voice" else name
        path = os.path.join(AUDIO, fname + ".mp3")
        if not os.path.exists(path):
            print("no sound", fname, "- left out", flush=True)
            continue
        dur = duration(path)
        if frm < 0:
            frm = max(0.0, dur + frm)
        ln = min(length or dur, dur - frm)
        inputs += ["-i", path]
        ch = "[%d:a]atrim=start=%.3f:duration=%.3f,asetpts=PTS-STARTPTS,aformat=sample_rates=48000:channel_layouts=stereo" % (
            i, frm, ln)
        if fin > 0:
            ch += ",afade=t=in:st=0:d=%.3f" % fin
        if fout > 0:
            ch += ",afade=t=out:st=%.3f:d=%.3f" % (max(0.0, ln - fout), fout)
        ch += ",volume=%.1fdB,adelay=%d|%d" % (gain, int(at * 1000), int(at * 1000))
        lab = "a%d" % i
        parts.append(ch + "[%s]" % lab)
        labels.append("[%s]" % lab)
        i += 1
    if not labels:
        return inputs, None
    filt = ";".join(parts) + ";" + "".join(labels) + "amix=inputs=%d:normalize=0:dropout_transition=0," % len(labels) \
        + "alimiter=limit=0.92,apad[aout]"
    return inputs, filt


def main():
    a = args()
    quality = a.get("quality", "preview")
    step = 2 if quality == "preview" else 1
    fps = T.FPS // step
    tmp = "/tmp/cinematic_seq"
    shutil.rmtree(tmp, ignore_errors=True)
    n, (w, h) = frames(a["frames"], step, tmp)
    H = int(round(w * 9 / 16 / 2)) * 2
    vf = "vignette=angle=PI/5,noise=alls=%d:allf=t,pad=%d:%d:0:(oh-ih)/2:black,format=yuv420p" % (
        6 if quality == "final" else 5, w, H)
    ain, afilt = mix_args(1)
    cmd = ["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-framerate", str(fps), "-i", os.path.join(tmp, "s%05d.png")]
    cmd += ain
    if afilt:
        cmd += ["-filter_complex", "[0:v]%s[vout];%s" % (vf, afilt), "-map", "[vout]", "-map", "[aout]",
                "-c:a", "aac", "-b:a", "192k"]
    else:
        cmd += ["-vf", vf]
    cmd += ["-c:v", "libx264", "-preset", "slow", "-crf", "18" if quality == "final" else "22", "-r", str(fps),
            "-t", "%.2f" % T.LENGTH, "-movflags", "+faststart", a["out"]]
    print(" ".join(cmd[:12]), "...", flush=True)
    subprocess.run(cmd, check=True)
    print("cut", a["out"], os.path.getsize(a["out"]) // 1024, "KB", flush=True)


if __name__ == "__main__":
    main()
