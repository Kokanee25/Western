#!/usr/bin/env python3
"""The dev bridge's client (src/debug/dev_bridge.gd; docs/briefs/review-tools.md).

Start the game with the bridge, send it commands, stop it:

    python3 tools/bridge.py start [--size=960x540] [--headless] [--port=8737] [--fps=N] [--movie=OUT.avi]
        [--game-args=--young-town,...] [--render-thread=on]
    python3 tools/bridge.py "goto saloon_porch" "look saloon_door" "screenshot /tmp/a.png"
    python3 tools/bridge.py -f script.txt          # one command a line, # comments
    python3 tools/bridge.py stop

or all at once (start, the script, stop), the way a session collects screenshots:

    python3 tools/bridge.py run script.txt [--size=...] [--timeout=S]

--timeout: the seconds (wall) one command may take before the game counts as lost (600; a film's
long command under the movie writer at lavapipe's pace needs more).

--movie records every frame drawn, with the game's sound, to an AVI (Godot's Movie Maker; it
runs on a fixed step, 30 fps unless --fps says otherwise, so slow rendering doesn't slow the game's
clock), from start to stop; cut clips from it with ffmpeg by the game's clock.

Each command prints the game's one-line JSON answer. `start` runs Godot under xvfb with the
Vulkan renderer (lavapipe here) so screenshots work; --headless is quicker but draws nothing.
The game's own output goes to build/bridge/godot.log.

The game starts with the renderer on the main thread (Godot's --render-thread safe), whatever the
game's own setting (Settings.render_thread): screenshots are of the frame the commands set up.
--render-thread=on draws on its own thread (more-cores step 7): a screenshot is then a drawn
frame, but may be one later than the one asked for.
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
    cmd = [godot, "--path", ROOT, "--render-thread", "separate" if _opt(args, "render-thread") == "on" else "safe"]
    if _opt(args, "headless"):
        cmd += ["--headless"]
    else:
        cmd = ["xvfb-run", "-a", "-s", "-screen 0 %sx24" % size] + cmd + ["--rendering-driver", "vulkan"]
        cmd += ["--resolution", size]
    fps = _opt(args, "fps")
    movie = _opt(args, "movie")
    if movie and not fps:
        fps = 30
    if fps:
        cmd += ["--fixed-fps", str(fps)]
    if movie:
        cmd += ["--write-movie", os.path.abspath(movie)]
    cmd += ["--", "--dev-bridge", f"--bridge-port={port}"]
    # The game's own flags, comma separated (--game-args=--young-town: every building as new).
    game_args = _opt(args, "game-args")
    if game_args:
        cmd += game_args.split(",")
    script = _opt(args, "script")
    if script:
        cmd.append(f"--bridge-script={os.path.abspath(script)}")
    log = open(os.path.join(STATE, _per_port("godot.log", port)), "w")
    proc = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    with open(os.path.join(STATE, _per_port("pid", port)), "w") as f:
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


def _reconnect(port, timeout):
    """After a scene reload: wait for the old bridge to go and the new one to listen."""
    time.sleep(1.0)
    deadline = time.time() + 180
    while time.time() < deadline:
        s = _connect(port, quiet=True)
        if s:
            # A ping answered on this connection: the old bridge, still closing, would drop it.
            try:
                s.settimeout(timeout)
                s.sendall(b"ping\n")
                buf = b""
                while b"\n" not in buf:
                    chunk = s.recv(65536)
                    if not chunk:
                        raise ConnectionError
                    buf += chunk
                return s
            except (OSError, ConnectionError):
                s.close()
        time.sleep(0.5)
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
            if answer.get("reloading"):
                # `world NAME`: the game reloads its scene and its bridge with it; go on once the
                # new one is listening.
                s.close()
                s = _reconnect(port, timeout)
                if s is None:
                    raise ConnectionError("the game didn't come back after the reload")
                buf = b""
    except (ConnectionError, socket.timeout) as e:
        if not (lines and lines[-1].strip() == "quit"):
            print(f"lost the game: {e}")
    finally:
        s.close()
    return out


def _per_port(name, port):
    """The game's pid and log files: the default port's as they were, another port's its own (two
    games at once, each stopped by its own pid)."""
    return name if int(port) == PORT else f"{name}.{port}"


def stop(port=PORT):
    if _connect(port, quiet=True):
        send(["quit"], port)
    pid_file = os.path.join(STATE, _per_port("pid", port))
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
            send(open(script).read().splitlines(), port, int(_opt(argv, "timeout", 600)))
        finally:
            stop(port)
        return 0
    if argv[0] == "-f":
        return 0 if send(open(argv[1]).read().splitlines(), port) is not None else 1
    cmds = [a for a in argv if not a.startswith("--port=")]
    return 0 if send(cmds, port) is not None else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
