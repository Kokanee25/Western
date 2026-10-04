#!/usr/bin/env python3
"""The dev bridge's client (src/debug/dev_bridge.gd; docs/briefs/review-tools.md).

Start the game with the bridge, send it commands, stop it:

    python3 tools/bridge.py start [--size=960x540] [--headless] [--port=8737] [--fps=N]
    python3 tools/bridge.py "goto saloon_porch" "look saloon_door" "screenshot /tmp/a.png"
    python3 tools/bridge.py -f script.txt          # one command a line, # comments
    python3 tools/bridge.py stop

or all at once (start, the script, stop), the way a session collects screenshots:

    python3 tools/bridge.py run script.txt [--size=...]

Each command prints the game's one-line JSON answer. `start` runs Godot under xvfb with the
Vulkan renderer (lavapipe here) so screenshots work; --headless is quicker but draws nothing.
The game's own output goes to build/bridge/godot.log.
"""
import json
import os
import signal
import socket
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(ROOT, "build", "bridge")
PORT = 8737


def _opt(args, name, default=None):
    for a in args:
        if a.startswith(f"--{name}="):
            return a.split("=", 1)[1]
        if a == f"--{name}":
            return True
    return default


def start(args):
    os.makedirs(STATE, exist_ok=True)
    port = int(_opt(args, "port", PORT))
    if _connect(port, quiet=True):
        print(f"a game is already listening on {port}")
        return 0
    size = _opt(args, "size", "960x540")
    godot = os.environ.get("GODOT", "godot")
    cmd = [godot, "--path", ROOT]
    if _opt(args, "headless"):
        cmd += ["--headless"]
    else:
        cmd = ["xvfb-run", "-a", "-s", "-screen 0 %sx24" % size] + cmd + ["--rendering-driver", "vulkan"]
        cmd += ["--resolution", size]
    fps = _opt(args, "fps")
    if fps:
        cmd += ["--fixed-fps", str(fps)]
    cmd += ["--", "--dev-bridge", f"--bridge-port={port}"]
    script = _opt(args, "script")
    if script:
        cmd.append(f"--bridge-script={os.path.abspath(script)}")
    log = open(os.path.join(STATE, "godot.log"), "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    with open(os.path.join(STATE, "pid"), "w") as f:
        f.write(str(proc.pid))
    deadline = time.time() + 180
    while time.time() < deadline:
        if proc.poll() is not None:
            print(f"the game exited ({proc.returncode}); see build/bridge/godot.log")
            return 1
        s = _connect(port, quiet=True)
        if s:
            s.close()
            print(f"game up (pid {proc.pid}, port {port})")
            return 0
        time.sleep(1)
    print("the game didn't open its bridge in 3 minutes")
    return 1


def _connect(port, quiet=False):
    try:
        return socket.create_connection(("127.0.0.1", port), timeout=2)
    except OSError:
        if not quiet:
            print(f"nothing listening on {port} (python3 tools/bridge.py start)")
        return None


def send(lines, port=PORT, timeout=600):
    """Send commands one at a time; return their answers (dicts)."""
    s = _connect(port)
    if s is None:
        return None
    s.settimeout(timeout)
    out = []
    buf = b""
    try:
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            s.sendall((line + "\n").encode())
            while b"\n" not in buf:
                chunk = s.recv(65536)
                if not chunk:
                    raise ConnectionError("the game closed the connection")
                buf += chunk
            reply, buf = buf.split(b"\n", 1)
            answer = json.loads(reply)
            out.append(answer)
            print(json.dumps(answer))
            sys.stdout.flush()
    except (ConnectionError, socket.timeout) as e:
        if not (lines and lines[-1].strip() == "quit"):
            print(f"lost the game: {e}")
    finally:
        s.close()
    return out


def stop(port=PORT):
    if _connect(port, quiet=True):
        send(["quit"], port)
    pid_file = os.path.join(STATE, "pid")
    if os.path.exists(pid_file):
        pid = int(open(pid_file).read())
        for _ in range(20):
            try:
                os.kill(pid, 0)
            except OSError:
                break
            time.sleep(0.5)
        else:
            try:
                os.killpg(pid, signal.SIGTERM)
            except OSError:
                pass
        os.remove(pid_file)
    return 0


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    port = int(_opt(argv, "port", PORT))
    if argv[0] == "start":
        return start(argv[1:])
    if argv[0] == "stop":
        return stop(port)
    if argv[0] == "run":
        script = argv[1]
        if start(argv[2:]) != 0:
            return 1
        try:
            send(open(script).read().splitlines(), port)
        finally:
            stop(port)
        return 0
    if argv[0] == "-f":
        return 0 if send(open(argv[1]).read().splitlines(), port) is not None else 1
    cmds = [a for a in argv if not a.startswith("--port=")]
    return 0 if send(cmds, port) is not None else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
