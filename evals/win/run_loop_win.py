#!/usr/bin/env python3
"""Windows-compatible launcher for skill-creator's description-optimization loop.

WHY THIS EXISTS
---------------
skill-creator's scripts/run_eval.py detects whether a skill triggers by reading
`claude -p` streaming output with `select.select([process.stdout], ...)`. On
Windows `select` only works on sockets, so on a subprocess pipe it raises
OSError [WinError 10093] and the reader never sees any output. The result: every
query is scored as "did not trigger" (trigger_rate 0.0) regardless of the
description. The 50% scores you see are an artifact (negatives trivially pass).

This launcher fixes that WITHOUT modifying the installed plugin:
  1. ProcessPoolExecutor -> ThreadPoolExecutor  (threads share our monkeypatched
     function; ProcessPool would pickle-import the original by reference).
  2. select-based reader  -> background-thread + queue reader (Windows-safe).
The trigger-detection state machine is kept byte-for-byte equivalent to the
plugin's, so results are comparable to a POSIX run.

USAGE (env SKILL_CREATOR_DIR must point at the installed skill-creator):
  python run_loop_win.py --eval-set <f.json> --skill-path <dir> --model <id> --max-iterations 5 --verbose
  python run_loop_win.py --selftest      # validate the reader + detection without claude
"""
import json
import os
import queue
import subprocess
import sys
import threading
import time
import uuid
from pathlib import Path


# --- trigger-detection state machine (mirrors run_eval.run_single_query) -----
def _feed(event: dict, state: dict, clean_name: str):
    """Consume one stream-json event. Return True/False once decided, else None."""
    t = event.get("type")
    if t == "stream_event":
        se = event.get("event", {})
        st = se.get("type", "")
        if st == "content_block_start":
            cb = se.get("content_block", {})
            if cb.get("type") == "tool_use":
                name = cb.get("name", "")
                if name in ("Skill", "Read"):
                    state["pending"] = name
                    state["acc"] = ""
                else:
                    return False
        elif st == "content_block_delta" and state.get("pending"):
            delta = se.get("delta", {})
            if delta.get("type") == "input_json_delta":
                state["acc"] += delta.get("partial_json", "")
                if clean_name in state["acc"]:
                    return True
        elif st in ("content_block_stop", "message_stop"):
            if state.get("pending"):
                return clean_name in state["acc"]
            if st == "message_stop":
                return False
    elif t == "assistant":
        for ci in event.get("message", {}).get("content", []):
            if ci.get("type") != "tool_use":
                continue
            name = ci.get("name", "")
            inp = ci.get("input", {})
            if name == "Skill" and clean_name in inp.get("skill", ""):
                state["triggered"] = True
            elif name == "Read" and clean_name in inp.get("file_path", ""):
                state["triggered"] = True
            return state["triggered"]
    elif t == "result":
        return state.get("triggered", False)
    return None


def win_run_single_query(query, skill_name, skill_description, timeout, project_root, model=None) -> bool:
    """Windows-safe drop-in for run_eval.run_single_query."""
    unique_id = uuid.uuid4().hex[:8]
    clean_name = f"{skill_name}-skill-{unique_id}"
    commands_dir = Path(project_root) / ".claude" / "commands"
    command_file = commands_dir / f"{clean_name}.md"
    try:
        commands_dir.mkdir(parents=True, exist_ok=True)
        indented_desc = "\n  ".join(skill_description.split("\n"))
        command_file.write_text(
            f"---\ndescription: |\n  {indented_desc}\n---\n\n"
            f"# {skill_name}\n\nThis skill handles: {skill_description}\n",
            encoding="utf-8",
        )
        cmd = ["claude", "-p", query, "--output-format", "stream-json",
               "--verbose", "--include-partial-messages"]
        if model:
            cmd += ["--model", model]
        env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}

        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, cwd=project_root, env=env)
        q: "queue.Queue" = queue.Queue()

        def _reader():
            try:
                for raw in iter(proc.stdout.readline, b""):
                    q.put(raw)
            finally:
                q.put(None)

        threading.Thread(target=_reader, daemon=True).start()

        state = {"pending": None, "acc": "", "triggered": False}
        deadline = time.time() + timeout
        try:
            while time.time() < deadline:
                try:
                    raw = q.get(timeout=0.5)
                except queue.Empty:
                    if proc.poll() is not None and q.empty():
                        break
                    continue
                if raw is None:
                    break
                line = raw.decode("utf-8", errors="replace").strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue
                decision = _feed(event, state, clean_name)
                if decision is not None:
                    return decision
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
        return state["triggered"]
    finally:
        if command_file.exists():
            command_file.unlink()


# --- selftest (no claude needed) --------------------------------------------
def _selftest() -> int:
    ok = True

    # 1) detection logic parity
    cn = "demo-skill-abcd1234"
    def run(events):
        st = {"pending": None, "acc": "", "triggered": False}
        for e in events:
            d = _feed(e, st, cn)
            if d is not None:
                return d
        return st["triggered"]

    pos = [
        {"type": "stream_event", "event": {"type": "content_block_start",
            "content_block": {"type": "tool_use", "name": "Skill"}}},
        {"type": "stream_event", "event": {"type": "content_block_delta",
            "delta": {"type": "input_json_delta", "partial_json": '{"skill":"' + cn + '"}'}}},
    ]
    neg_other_tool = [
        {"type": "stream_event", "event": {"type": "content_block_start",
            "content_block": {"type": "tool_use", "name": "Bash"}}},
    ]
    neg_no_trigger = [
        {"type": "stream_event", "event": {"type": "message_stop"}},
    ]
    for label, events, expected in [
        ("positive(Skill+name)", pos, True),
        ("negative(other tool)", neg_other_tool, False),
        ("negative(message_stop)", neg_no_trigger, False),
    ]:
        got = run(events)
        status = "ok" if got == expected else "FAIL"
        if got != expected:
            ok = False
        print(f"  detection {label}: expected={expected} got={got} [{status}]")

    # 2) Windows-safe pipe reader (this is what 'select' broke)
    proc = subprocess.Popen(["cmd", "/c", 'echo {"type":"result"}'],
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    q: "queue.Queue" = queue.Queue()
    def _r():
        try:
            for raw in iter(proc.stdout.readline, b""):
                q.put(raw)
        finally:
            q.put(None)
    threading.Thread(target=_r, daemon=True).start()
    got_line = None
    try:
        item = q.get(timeout=5)
        if item is not None:
            got_line = item.decode("utf-8", errors="replace").strip()
    except queue.Empty:
        pass
    proc.wait()
    reader_ok = got_line is not None and "result" in got_line
    if not reader_ok:
        ok = False
    print(f"  thread reader read pipe: got={got_line!r} [{'ok' if reader_ok else 'FAIL'}]")

    print("SELFTEST:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


def _main() -> int:
    if "--selftest" in sys.argv:
        return _selftest()

    sc = os.environ.get("SKILL_CREATOR_DIR")
    if not sc or not Path(sc).is_dir():
        print("ERROR: set SKILL_CREATOR_DIR to the installed skill-creator dir.", file=sys.stderr)
        return 2
    sys.path.insert(0, sc)

    import scripts.run_eval as re_mod
    from concurrent.futures import ThreadPoolExecutor
    # 1) avoid ProcessPool pickling so our monkeypatch applies in workers
    re_mod.ProcessPoolExecutor = ThreadPoolExecutor
    # 2) Windows-safe trigger reader
    re_mod.run_single_query = win_run_single_query

    import scripts.run_loop as rl
    rl.main()  # reads sys.argv via argparse; we pass the same flags through
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
