#!/usr/bin/env python3
"""What a crash, freeze or stall report says (issue #624; src/debug/crash_reports.gd).

    python3 tools/crash_report.py FILE.saltbug.zip [--seconds=30] [--symbols=DIR]

Prints: the build and the machine; what happened (crash, freeze, stall, or a run that didn't quit
cleanly) and the native guard's notes; the dead or stuck thread's stack (Linux: gdb's for the main
thread and Godot's own crash handler's backtrace with the GDScript one; Windows: the minidump's
exception, its thread and a scan of that thread's stack for return addresses, module + offset);
the last N seconds (30) of what happened; the frame times leading in; the log's last lines.

Windows minidumps: with `minidump-stackwalk` on the PATH (rust-minidump: `cargo install
minidump-stackwalk`) and `--symbols=DIR` a folder holding saltcreek_native.pdb (it ships beside
the DLL in every Windows build), it also prints the walked stack with this plugin's functions and
lines. Godot's own frames have no symbols (the official export templates ship none).

Reads F12's reports too (no crash section then).
"""
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from perf_report import summary_lines  # noqa: E402


# --- Minidumps (the Windows crash and freeze dumps) -------------------------------------------

def _mdstring(b, rva):
    n = struct.unpack_from("<I", b, rva)[0]
    return b[rva + 4:rva + 4 + n].decode("utf-16-le", "replace")


def read_minidump(b):
    """The parts of a minidump that say where: threads, names, modules, the exception."""
    if b[:4] != b"MDMP":
        return None
    nstreams, dir_rva = struct.unpack_from("<II", b, 8)
    out = {"threads": {}, "names": {}, "modules": [], "exception": None}
    for i in range(nstreams):
        kind, size, rva = struct.unpack_from("<III", b, dir_rva + 12 * i)
        if kind == 3:  # ThreadListStream
            n = struct.unpack_from("<I", b, rva)[0]
            for k in range(n):
                o = rva + 4 + 48 * k
                tid, = struct.unpack_from("<I", b, o)
                st_start, st_size, st_rva = struct.unpack_from("<QII", b, o + 24)
                ctx_size, ctx_rva = struct.unpack_from("<II", b, o + 40)
                out["threads"][tid] = {"stack": (st_start, st_size, st_rva), "ctx": (ctx_size, ctx_rva)}
        elif kind == 4:  # ModuleListStream
            n = struct.unpack_from("<I", b, rva)[0]
            for k in range(n):
                o = rva + 4 + 108 * k
                base, size_img = struct.unpack_from("<QI", b, o)
                name_rva, = struct.unpack_from("<I", b, o + 20)
                out["modules"].append((base, size_img, os.path.basename(_mdstring(b, name_rva).replace("\\", "/"))))
        elif kind == 6:  # ExceptionStream
            tid, = struct.unpack_from("<I", b, rva)
            code, flags, _rec, addr, nparams = struct.unpack_from("<IIQQI", b, rva + 8)
            params = struct.unpack_from("<15Q", b, rva + 8 + 32)
            ctx_size, ctx_rva = struct.unpack_from("<II", b, rva + 8 + 32 + 120)
            out["exception"] = {"thread": tid, "code": code, "address": addr, "params": params[:nparams],
                                "ctx": (ctx_size, ctx_rva)}
        elif kind == 24:  # ThreadNamesStream
            n = struct.unpack_from("<I", b, rva)[0]
            for k in range(n):
                tid, name_rva = struct.unpack_from("<IQ", b, rva + 4 + 12 * k)
                out["names"][tid] = _mdstring(b, name_rva)
    return out


def where(md, addr):
    for base, size, name in md["modules"]:
        if base <= addr < base + size:
            return f"{name}+0x{addr - base:x}"
    return f"0x{addr:x}"


def scan_stack(b, md, tid, ctx=None, limit=40):
    """A thread's instruction pointer and the stack's words that point into a module's image:
    the likely return addresses, newest first (what a stack walk without unwind data does)."""
    t = md["threads"].get(tid)
    if not t:
        return []
    size, rva = ctx or t["ctx"]
    lines = []
    if size >= 0x100:
        rip, = struct.unpack_from("<Q", b, rva + 0xF8)
        rsp, = struct.unpack_from("<Q", b, rva + 0x98)
        lines.append(f"  at   {where(md, rip)}  (rsp 0x{rsp:x})")
    start, st_size, st_rva = t["stack"]
    found = 0
    for off in range(0, st_size - 7, 8):
        v, = struct.unpack_from("<Q", b, st_rva + off)
        if any(base <= v < base + size for base, size, _ in md["modules"]):
            lines.append(f"  [sp+0x{off:x}] {where(md, v)}")
            found += 1
            if found >= limit:
                lines.append("  ...")
                break
    return lines


EXCEPTIONS = {0xC0000005: "access violation", 0xC00000FD: "stack overflow", 0xC000001D: "illegal instruction",
              0xC0000094: "integer divide by zero", 0xC0000374: "heap corruption", 0xC0000006: "in-page error"}


def minidump_part(name, data, symbols, main_tid):
    md = read_minidump(data)
    if md is None:
        return [f"{name}: not a minidump"]
    out = [f"## {name} ({len(data) // 1024} KB, {len(md['threads'])} threads, {len(md['modules'])} modules)"]
    ex = md["exception"]
    if ex:
        what = EXCEPTIONS.get(ex["code"], "exception")
        tname = md["names"].get(ex["thread"], "")
        out.append(f"exception 0x{ex['code']:08x} ({what}) at {where(md, ex['address'])}, thread {ex['thread']} {tname!r}")
        if ex["code"] == 0xC0000005 and len(ex["params"]) >= 2:
            out.append(f"  {'writing' if ex['params'][0] == 1 else 'reading'} 0x{ex['params'][1]:x}")
        out.append("its stack (scanned):")
        out += scan_stack(data, md, ex["thread"], ex["ctx"])
    elif main_tid and main_tid in md["threads"]:
        out.append(f"the main thread ({main_tid}), scanned:")
        out += scan_stack(data, md, main_tid)
    out.append("threads: " + ", ".join(f"{t}{' ' + repr(md['names'][t]) if t in md['names'] else ''}" for t in md["threads"]))
    walker = shutil.which("minidump-stackwalk")
    if walker:
        with tempfile.TemporaryDirectory() as tmp:
            p = os.path.join(tmp, name)
            with open(p, "wb") as f:
                f.write(data)
            cmd = [walker, p] + (["--symbols-path", symbols] if symbols else [])
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            text = r.stdout
            if "Thread 0" in text or "crashing thread" in text.lower():
                out.append("\nminidump-stackwalk:")
                out += text.splitlines()[:120]
    else:
        out.append("(minidump-stackwalk isn't here: `cargo install minidump-stackwalk` for a walked stack)")
    return out


# --- Linux: gdb's stacks in freeze.txt, Godot's handler in the log -----------------------------

def gdb_main_thread(text):
    """The main thread's stack from freeze.txt's gdb section (its LWP is marked in the /proc list)."""
    main = None
    for line in text.splitlines():
        if line.endswith("<- the main thread"):
            main = line.split()[0]
    if not main or "## Stacks (gdb)" not in text:
        return []
    gdb = text.split("## Stacks (gdb)", 1)[1].splitlines()
    out, on = [], False
    for line in gdb:
        if line.startswith("Thread "):
            on = f"LWP {main})" in line
            if on:
                out.append(line)
            continue
        if on and line.startswith("#"):
            out.append("  " + line[:200])
    return out


def handler_part(log):
    """Godot's crash handler's output in the log: the C++ and GDScript backtraces."""
    for start in ("handle_crash:", "CrashHandlerException", "Program crashed"):
        if start in log:
            block = log[log.index(start):]
            end = block.find("-- END OF GDSCRIPT BACKTRACE --")
            if end < 0:
                end = block.find("-- END OF C++ BACKTRACE --")
            return block[:end + 40 if end >= 0 else 3000].rstrip().splitlines()
    return []


# --- The report -------------------------------------------------------------------------------

def frames_in(perf, seconds=3.0):
    cols = perf.get("frames_columns", [])
    rows = perf.get("frames", [])
    if not rows:
        return ["frames: none"]
    i_t, i_f = cols.index("t"), cols.index("frame_ms")
    end = rows[-1][i_t]
    last = [r for r in rows if r[i_t] >= end - seconds]
    out = [f"the last {seconds:.0f} s of frames (ms, oldest first; the ring ends at {end:.1f} s):"]
    line = []
    for r in last:
        line.append(f"{r[i_f]:.0f}")
        if len(line) == 30:
            out.append("  " + " ".join(line))
            line = []
    if line:
        out.append("  " + " ".join(line))
    return out


def seconds_in(perf, seconds):
    cols = perf.get("seconds_columns", [])
    rows = perf.get("seconds", [])[-seconds:]
    if not rows or "frame_ms" not in cols:
        return []
    i_t, i_n, i_m = cols.index("t"), cols.index("frames"), cols.index("frame_ms")
    i_w = cols.index("frame_ms_worst")
    out = [f"the last {len(rows)} s, a second each: t, frames, mean ms, worst ms"]
    for r in rows:
        out.append(f"  {r[i_t]:7.1f} {int(r[i_n]):4d} {r[i_m]:7.1f} {r[i_w]:8.1f}")
    return out


def main(argv):
    path, seconds, symbols = "", 30, None
    for a in argv:
        if a.startswith("--seconds="):
            seconds = int(a.split("=", 1)[1])
        elif a.startswith("--symbols="):
            symbols = a.split("=", 1)[1]
        elif not a.startswith("--"):
            path = a
    if not path:
        print(__doc__)
        return 2
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        report = json.loads(z.read("report.json")) if "report.json" in names else {}
        perf = json.loads(z.read("perf.json")) if "perf.json" in names else {}
        notes = {n: z.read(n).decode("utf-8", "replace") for n in ("crash.txt", "freeze.txt", "panic.txt") if n in names}
        log = z.read("godot.log").decode("utf-8", "replace") if "godot.log" in names else ""
        lines = z.read("log.txt").decode("utf-8", "replace").splitlines() if "log.txt" in names else []
        dumps = {n: z.read(n) for n in names if n.endswith(".dmp")}
    crash = report.get("crash", {})
    print(f"{os.path.basename(path)}: build {report.get('build', '?')}, {report.get('os', '?')}, "
          f"{report.get('video', '?')}, scene {report.get('scene', '?')}")
    print(f"  {report.get('game_seconds', 0):.0f} s of play, clock {report.get('clock', '?')}, "
          f"{report.get('fps', 0):.0f} fps at the last black box ({crash.get('box_written', 'F12')})")
    if crash:
        print(f"\n# What happened: {crash.get('kind', '?')}\n{crash.get('what', '')}")
        if not crash.get("box_found", True):
            print("(no black box: the run ended before its first write)")
    else:
        print("\n# An F12 report (no crash)")
    main_tid = None
    for n, text in notes.items():
        print(f"\n## {n}")
        head = text.split("## Stacks (gdb)", 1)[0]
        print(head.rstrip())
        for line in head.splitlines():
            if line.startswith("the main thread is thread "):
                main_tid = int(line.split()[5])
    stack = gdb_main_thread(notes.get("freeze.txt", ""))
    if stack:
        print("\n## The main thread's stack (gdb)")
        print("\n".join(stack[:41]))
    hb = handler_part(log)
    if hb:
        print("\n## Godot's crash handler (godot.log)")
        print("\n".join(hb[:80]))
    for n, data in dumps.items():
        print()
        print("\n".join(minidump_part(n, data, symbols, main_tid)))
    t_end = float(report.get("game_seconds", 0.0))
    events = [e for e in report.get("events", []) if float(e.get("t", 0)) >= t_end - seconds]
    print(f"\n## The last {seconds} s ({len(events)} things)")
    for e in events:
        print(f"  {float(e.get('t', 0)):7.1f} {e.get('kind', ''):<10} {e.get('text', '')}")
    print("\n## Frames leading in")
    print("\n".join(summary_lines(report.get("perf_summary", {}))))
    if perf:
        print("\n".join(frames_in(perf)))
        print("\n".join(seconds_in(perf, seconds)))
    if lines:
        print(f"\n## The log's last lines ({len(lines)} kept)")
        print("\n".join("  " + x[:220] for x in lines[-25:]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
