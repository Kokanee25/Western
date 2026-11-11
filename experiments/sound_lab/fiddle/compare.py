#!/usr/bin/env python3
"""The measured comparison against the 1922 reference (issue #790): a guide, not the judge (Sean's
ear is). Each clip measured twice: as it is, and "as the horn heard it" (band-passed 250-4000 Hz,
the acoustic recording's band), since the record's medium alone would otherwise dominate.

- spectral shape: third-octave long-term spectrum, 250 Hz-4 kHz, levelled to the same total;
  `shape_db` the RMS difference from the reference's, band by band (0 = the same shape);
- centroid (Hz, 200 Hz-5 kHz): brightness;
- notes/s: onsets found by spectral flux (the reference's tempo differs: a guide to articulation);
- attack (ms): the envelope's rise, 10 to 90%, after each onset (median);
- pulse (dB): how far the envelope drops between notes (median peak-to-dip): the bow's rhythm;
- vibrato (cents): the pitch's wobble within held notes (YIN every 5 ms; runs over 150 ms,
  less their straight line, the standard deviation; its rate isn't reported: at a fiddle tune's
  note lengths a run is too short to find one);
- scratch: spectral flatness 2-6 kHz (the record's surface noise raises its own).

    python3 experiments/sound_lab/fiddle/compare.py [--dir=build/sound_lab/fiddle/dry]
        [--out=experiments/sound_lab/results/2026-11-10_fiddle]
"""
import json
import os
import sys

import numpy as np
from scipy.signal import butter, sosfilt, stft

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common  # noqa: E402

SR = common.SR
CLIPS = ["ref", "A", "B", "C"]
THIRDS = 1000.0 * 2.0 ** (np.arange(-6, 7) / 3.0)  # 250 Hz .. 4 kHz centres


def horn(x):
    sos = butter(4, [250 / (SR / 2), 4000 / (SR / 2)], "band", output="sos")
    return sosfilt(sos, x)


def spectrum(x):
    f, _, Z = stft(x, SR, nperseg=4096, noverlap=3072)
    P = np.mean(np.abs(Z) ** 2, axis=1)
    bands = []
    for c in THIRDS:
        m = (f >= c / 2 ** (1 / 6)) & (f < c * 2 ** (1 / 6))
        bands.append(P[m].sum())
    b = np.array(bands)
    b = 10 * np.log10(b / b.sum() + 1e-20)
    m = (f >= 200) & (f <= 5000)
    centroid = float(np.sum(f[m] * P[m]) / np.sum(P[m]))
    return b, centroid


def envelope(x, hop=0.005, win=0.015):
    h, w = int(hop * SR), int(win * SR)
    e = np.array([np.sqrt(np.mean(x[i:i + w] ** 2)) for i in range(0, len(x) - w, h)])
    return 20 * np.log10(e + 1e-9)


def onsets(x):
    f, t, Z = stft(x, SR, nperseg=1024, noverlap=1024 - 240)
    mag = np.log1p(100 * np.abs(Z[(f > 150) & (f < 6000)]))
    flux = np.maximum(np.diff(mag, axis=1), 0).sum(axis=0)
    flux = (flux - np.median(flux)) / (np.std(flux) + 1e-9)
    tt = t[1:]
    peaks = []
    for i in range(2, len(flux) - 2):
        if flux[i] > 1.0 and flux[i] == max(flux[i - 2:i + 3]) and (not peaks or tt[i] - peaks[-1] > 0.07):
            peaks.append(tt[i])
    return np.array(peaks)


def attack_and_pulse(x, ons):
    env = envelope(x)
    hop = 0.005
    rises, dips = [], []
    lin = 10 ** (env / 20)
    for k, o in enumerate(ons):
        i0 = int(o / hop) - 2
        i1 = int((ons[k + 1] if k + 1 < len(ons) else o + 0.3) / hop)
        if i0 < 0 or i1 >= len(env) or i1 - i0 < 6:
            continue
        seg = lin[i0:i1]
        pk = int(np.argmax(seg[: max(3, len(seg) // 2)]))
        lo = seg[0]
        top = seg[pk]
        if top <= lo * 1.2:
            continue
        a = np.argmax(seg[: pk + 1] >= lo + 0.1 * (top - lo))
        b = np.argmax(seg[: pk + 1] >= lo + 0.9 * (top - lo))
        rises.append((b - a) * hop * 1000)
        dips.append(20 * np.log10(top / (seg[pk:].min() + 1e-9)))
    return float(np.median(rises)) if rises else 0.0, float(np.median(dips)) if dips else 0.0


def yin_track(x, hop=0.005, win=0.03, fmin=180, fmax=1400):
    h, w = int(hop * SR), int(win * SR)
    tmax, tmin = int(SR / fmin), int(SR / fmax)
    f0 = np.zeros((len(x) - w - tmax) // h)
    nfft = 1 << int(np.ceil(np.log2(w + tmax)))
    for j in range(len(f0)):
        seg = x[j * h:j * h + w + tmax]
        e = np.cumsum(seg ** 2)
        ac = np.fft.irfft(np.fft.rfft(seg, nfft) * np.conj(np.fft.rfft(seg[:w], nfft)), nfft)[:tmax + 1]
        lag_e = e[w - 1:w + tmax] - np.concatenate([[0], e[:tmax]])
        d = e[w - 1] + lag_e - 2 * ac
        cm = d[1:] * np.arange(1, tmax + 1) / np.maximum(np.cumsum(d[1:]), 1e-12)
        c = np.where(cm[tmin - 1:] < 0.2)[0]
        if c.size == 0:
            continue
        t = c[0] + tmin - 1
        while t + 1 < len(cm) and cm[t + 1] < cm[t]:
            t += 1
        f0[j] = SR / (t + 1)
    return f0


def vibrato(x, hop=0.005):
    f0 = yin_track(x, hop)
    sds, rates = [], []
    i = 0
    while i < len(f0):
        if f0[i] <= 0:
            i += 1
            continue
        j = i
        while j + 1 < len(f0) and f0[j + 1] > 0 and abs(1200 * np.log2(f0[j + 1] / f0[j])) < 50:
            j += 1
        run = f0[i:j + 1]
        if len(run) * hop >= 0.15:
            c = 1200 * np.log2(run / np.median(run))
            k = np.arange(len(c))
            c = c - np.polyval(np.polyfit(k, c, 1), k)
            c = c[3:-3]  # the note's edges
            if len(c) > 10:
                sds.append(np.std(c))
                if len(c) * hop >= 0.4:
                    F = np.abs(np.fft.rfft(c * np.hanning(len(c)), 1024))
                    fr = np.fft.rfftfreq(1024, hop)
                    m = (fr >= 3) & (fr <= 9)
                    rates.append(fr[m][np.argmax(F[m])])
        i = j + 1
    return (float(np.median(sds)) if sds else 0.0, float(np.median(rates)) if rates else 0.0, len(sds))


def flatness(x):
    f, _, Z = stft(x, SR, nperseg=2048, noverlap=1536)
    P = np.abs(Z[(f >= 2000) & (f <= 6000)]) ** 2 + 1e-20
    fl = np.exp(np.mean(np.log(P), axis=0)) / np.mean(P, axis=0)
    loud = np.mean(P, axis=0) > np.percentile(np.mean(P, axis=0), 30)
    return float(np.median(fl[loud]))


def measure(x):
    b, cen = spectrum(x)
    ons = onsets(x)
    act = ons[(ons > 0.5) & (ons < len(x) / SR - 0.5)]
    att, pulse = attack_and_pulse(x, act)
    vsd, vrate, vruns = vibrato(x)
    return {"bands_db": [round(v, 2) for v in b], "centroid_hz": round(cen), "notes_per_s": round(len(act) / (len(x) / SR - 1.0), 2),
            "attack_ms": round(att, 1), "pulse_db": round(pulse, 1), "vibrato_cents": round(vsd, 1),
            "held_runs": vruns, "scratch": round(flatness(x), 3)}


def main():
    src = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--dir=")), os.path.join(common.BUILD, "dry"))
    out = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--out=")),
               os.path.join(common.ROOT, "experiments", "sound_lab", "results", "2026-11-10_fiddle"))
    res = {}
    for k in CLIPS:
        _, x = common.read_wav(os.path.join(src, f"{k}.wav"))
        res[k] = {"as_is": measure(x), "horn": measure(horn(x))}
    for way in ("as_is", "horn"):
        ref = np.array(res["ref"][way]["bands_db"])
        for k in CLIPS:
            d = np.array(res[k][way]["bands_db"]) - ref
            res[k][way]["shape_db"] = round(float(np.sqrt(np.mean(d ** 2))), 2)
    os.makedirs(out, exist_ok=True)
    json.dump({"thirds_hz": [round(c) for c in THIRDS], "clips": res}, open(os.path.join(out, "measures.json"), "w"), indent=1)
    rows = [("shape_db", "spectral shape off the reference (dB RMS, 250 Hz-4 kHz)"), ("centroid_hz", "centroid (Hz)"),
            ("notes_per_s", "notes/s found"), ("attack_ms", "attack 10-90% (ms)"), ("pulse_db", "pulse: drop between notes (dB)"),
            ("vibrato_cents", "vibrato within held notes (cents s.d.)"),
            ("scratch", "scratch: flatness 2-6 kHz")]
    lines = []
    for way, title in (("horn", "As the 1922 horn heard it (all four band-passed 250 Hz-4 kHz)"), ("as_is", "As they are")):
        lines += [f"**{title}**", "", "| Measure | Reference (1922) | A samples | B model | C hybrid |", "|---|---|---|---|---|"]
        for key, name in rows:
            lines.append(f"| {name} | " + " | ".join(str(res[k][way][key]) for k in CLIPS) + " |")
        lines.append("")
    open(os.path.join(out, "measures.md"), "w").write("\n".join(lines))
    print("\n".join(lines))
    plot(res, out)


def plot(res, out):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    colours = {"ref": "#0b0b0b", "A": "#2a78d6", "B": "#eb6834", "C": "#1baf7a"}
    names = {"ref": "Reference 1922", "A": "A samples", "B": "B model", "C": "C hybrid"}
    fig, ax = plt.subplots(figsize=(8, 4.2), dpi=120)
    fig.patch.set_facecolor("#fcfcfb")
    ax.set_facecolor("#fcfcfb")
    ends = {}
    for k in CLIPS:
        y = res[k]["horn"]["bands_db"]
        ax.plot(THIRDS, y, color=colours[k], lw=2.6 if k == "ref" else 2, marker="o", ms=4, label=names[k])
        ends[k] = y[-1]
    # end labels, nudged apart where they'd overlap
    placed = []
    for k in sorted(ends, key=lambda k: ends[k]):
        yv = ends[k]
        while any(abs(yv - p) < 1.6 for p in placed):
            yv += 1.6
        placed.append(yv)
        ax.annotate(names[k], (THIRDS[-1], ends[k]), xytext=(THIRDS[-1] * 1.08, yv), textcoords="data",
                    va="center", fontsize=9, color="#52514e")
    ax.set_xscale("log")
    ax.minorticks_off()
    ax.set_xticks([250, 500, 1000, 2000, 4000])
    ax.set_xticklabels(["250", "500", "1k", "2k", "4k"])
    ax.set_xlim(220, 7600)
    ax.set_xlabel("Hz (third octaves)", color="#52514e")
    ax.set_ylabel("share of the energy (dB)", color="#52514e")
    ax.set_title("Spectral shape, all four through the 1922 recording's band", color="#0b0b0b", fontsize=11, loc="left", pad=26)
    ax.grid(True, color="#e6e5e1", lw=0.8)
    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)
    for sp in ("left", "bottom"):
        ax.spines[sp].set_color("#c3c2b7")
    ax.tick_params(colors="#52514e")
    ax.legend(frameon=False, fontsize=9, loc="lower left", bbox_to_anchor=(0, 1.0), ncol=4, borderaxespad=0.2)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "spectrum.png"))


if __name__ == "__main__":
    main()
