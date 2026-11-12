"""Voiced lines (#846): takes of a line, one fal TTS call each, run by run.py on GitHub.

A request (task: takes):
    spend: 0.50
    price_per_1k: 0.08                  # $ per 1,000 characters (Eleven v4); text-to-dialogue v3 is 0.10
    variants:
      - id: road.shot_by.clear.A0       # becomes the file name and lines[].takes[].id on the page
        line: road.shot_by.clear
        app: elevenlabs/tts/eleven-v4   # or fal-ai/elevenlabs/text-to-dialogue/eleven-v3
        voice: <fal voice id>           # cast[].voice.picked's id (docs/scripts/<mission>.json)
        text: "[exhales sharply] ..."   # exactly what is sent
        stability: 0.0                  # tts only
        seed: 1
        price_per_1k: 0.10              # optional, per variant
Output: tools/voices/takes/<id>.mp4 (audio-only AAC: the page's asset store takes no mp3) and
takes/made.json. A refused call (fal's checker) costs nothing and is recorded as an error.
"""
import json
import os
import subprocess

import cast

HERE = os.path.dirname(os.path.abspath(__file__))


def estimate(req):
    d = float(req.get("price_per_1k", 0.08))
    return round(sum(len(v["text"]) / 1000.0 * float(v.get("price_per_1k", d)) for v in req["variants"]), 3)


def body_for(v):
    if "dialogue" in v["app"]:
        return {"inputs": [{"text": v["text"], "voice": v["voice"]}], "stability": v.get("stability", 0.5),
                "seed": v.get("seed", 1)}
    return {"text": v["text"], "voice": v["voice"], "stability": v.get("stability", 0.5),
            "similarity_boost": v.get("similarity_boost", 0.75), "seed": v.get("seed", 1),
            "output_format": cast.FMT}


def run(req, name):
    key = os.environ.get("FAL_KEY", "")
    est = estimate(req)
    if est > float(req["spend"]):
        return {"error": "estimate $%.2f is over spend $%.2f: nothing run" % (est, float(req["spend"]))}
    if not key:
        return {"error": "no FAL_KEY: nothing run"}
    d = os.path.join(HERE, "takes")
    os.makedirs(d, exist_ok=True)
    made, spent = [], 0.0
    for v in req["variants"]:
        row = {"id": v["id"], "line": v["line"], "app": v["app"], "text": v["text"],
               "stability": v.get("stability")}
        try:
            ans = cast.call(v["app"], body_for(v), key)
            cost = len(v["text"]) / 1000.0 * float(v.get("price_per_1k", req.get("price_per_1k", 0.08)))
            spent += cost
            cast.ledger(name, v["app"], v["id"], cost)
            url = (ans.get("audio") or {}).get("url")
            mp3 = os.path.join(d, v["id"] + ".mp3")
            cast.fetch(url, mp3)
            mp4 = os.path.join(d, v["id"] + ".mp4")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", mp3, "-vn", "-c:a", "aac", "-b:a", "128k", mp4], check=True)
            os.remove(mp3)
            row["file"] = "takes/%s.mp4" % v["id"]
        except Exception as e:
            row["error"] = str(e)[:400]
        made.append(row)
        json.dump(made, open(os.path.join(d, "made.json"), "w"), indent=1)
    return {"estimate": est, "spent_at_most": round(spent, 3), "made": made}
