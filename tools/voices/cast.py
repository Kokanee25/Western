"""The cast (#807 step 2): candidate voices for each speaker, designed on fal (ElevenLabs Voice Design,
eleven-v3), run by run.py on GitHub. A request:
    task: cast
    spend: 5.00                       # the most the whole request may cost ($)
    script: docs/scripts/sheriff_road.json
    candidates: 4                     # voices per speaker
    round: v                          # candidate ids are <speaker>_<round><n> (b = the second round)
    seed_base: 0                      # added to every seed, so a new round gets new voices
    speakers:
      sheriff:
        prompt: "..."                 # age, region, grain, pace; never a real person's name
        text: "[tag] line one [tag] line two"   # 100-1000 characters: what each candidate says
        check: "[tag] line two"       # said again by the SAVED voice through TTS: proves the voice id is reusable
Each candidate is one design call (its own seed): fal returns three previews and saves one voice
(`voice_id`); the candidate is the preview of the saved voice. Then one TTS call (Eleven v4, the takes' model) with
voice=voice_id says `check`. Everything lands in tools/voices/cast/<speaker>/ and cast/made.json.
Prices (fal's model pages, fetched 2026-11-12 by the probe): design $0.10 per 1,000 characters
performed; Eleven v4 TTS $0.08 per 1,000 characters (v3 $0.10).
"""
import csv
import datetime
import json
import os
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
QUEUE = "https://queue.fal.run/"
DESIGN = "fal-ai/elevenlabs/text-to-voice/design/eleven-v3"
TTS = "elevenlabs/tts/eleven-v4"     # the takes' model: the check proves a designed voice speaks in it
FMT = "mp3_44100_128"


def estimate(req):
    """The most a request can cost: every character billed three times over in design (three
    previews), and every TTS call billed as a full 1,000 characters."""
    n = int(req.get("candidates", 4))
    total = 0.0
    for sp in req["speakers"].values():
        total += n * (3 * len(sp["text"]) / 1000.0 * 0.10 + 0.10)
    return round(total, 2)


def _req(method, url, key, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method,
                               headers={"Authorization": "Key " + key, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r, timeout=180) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: %s" % (e.code, url, e.read().decode(errors="replace")[:600]))


def call(app, body, key):
    q = _req("POST", QUEUE + app, key, body)
    base = QUEUE + "/".join(app.split("/")[:2])
    status = q.get("status_url") or "%s/requests/%s/status" % (base, q["request_id"])
    resp = q.get("response_url") or "%s/requests/%s" % (base, q["request_id"])
    for _ in range(450):
        st = _req("GET", status, key).get("status")
        if st == "COMPLETED":
            return _req("GET", resp, key)
        if st not in ("IN_QUEUE", "IN_PROGRESS"):
            raise RuntimeError("%s: %s" % (app, st))
        time.sleep(2)
    raise RuntimeError(app + ": timed out")


def fetch(url, path):
    with urllib.request.urlopen(url, timeout=120) as r, open(path, "wb") as f:
        f.write(r.read())


def ledger(name, app, what, est):
    path = os.path.join(HERE, "paid.csv")
    new = not os.path.exists(path)
    with open(path, "a", newline="") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["date", "request", "app", "what", "est_usd"])
        w.writerow([datetime.date.today().isoformat(), name, app, what, "%.3f" % est])


def run(req, name):
    key = os.environ.get("FAL_KEY", "")
    est = estimate(req)
    if est > float(req["spend"]):
        return {"error": "estimate $%.2f is over spend $%.2f: nothing run" % (est, float(req["spend"]))}
    if not key:
        return {"error": "no FAL_KEY: nothing run"}
    n = int(req.get("candidates", 4))
    out_root = os.path.join(HERE, "cast")
    made, spent = {}, 0.0
    for si, (sid, sp) in enumerate(req["speakers"].items()):
        d = os.path.join(out_root, sid)
        os.makedirs(d, exist_ok=True)
        made[sid] = []
        for c in range(1, n + 1):
            seed = int(req.get("seed_base", 0)) + 1000 * (si + 1) + c
            cid = "%s_%s%d" % (sid, req.get("round", "v"), c)
            row = {"id": cid, "seed": seed}
            body = {"prompt": sp["prompt"], "text": sp["text"], "auto_generate_text": False, "seed": seed,
                    "guidance_scale": sp.get("guidance_scale", 4), "loudness": 0.5, "output_format": FMT,
                    "voice_name": "saltcreek_" + cid}
            try:
                ans = call(DESIGN, body, key)
                cost = 3 * len(sp["text"]) / 1000.0 * 0.10
                spent += cost
                ledger(name, DESIGN, cid, cost)
                vid = ans.get("voice_id")
                prev = ans.get("previews") or []
                pick = next((p for p in prev if p.get("generated_voice_id") == vid), None)
                row.update(voice_id=vid, previews=[p.get("generated_voice_id") for p in prev],
                           saved_preview=("matched" if pick else "none matched: preview 0 shown"))
                pick = pick or (prev[0] if prev else None)
                if pick:
                    fetch(pick["audio"]["url"], os.path.join(d, cid + ".mp3"))
                    row["file"] = "%s/%s.mp3" % (sid, cid)
                    row["seconds"] = pick.get("duration_seconds")
            except Exception as e:
                row["error"] = "design: %s" % e
                made[sid].append(row)
                continue
            if vid and sp.get("check"):
                try:
                    a2 = call(TTS, {"text": sp["check"], "voice": vid, "stability": 0.5, "similarity_boost": 0.75, "seed": seed, "output_format": FMT}, key)
                    spent += 0.10
                    ledger(name, TTS, cid + " check", 0.10)
                    fetch(a2["audio"]["url"], os.path.join(d, cid + "_check.mp3"))
                    row["check_file"] = "%s/%s_check.mp3" % (sid, cid)
                except Exception as e:
                    row["check_error"] = "tts with voice_id: %s" % e
            made[sid].append(row)
            json.dump(made, open(os.path.join(out_root, "made.json"), "w"), indent=1)
    return {"estimate": est, "spent_at_most": round(spent, 2), "made": made}
