#!/usr/bin/env python3
"""Generic test-only forward weaving worker; no fixture or production imports in requests."""
import hashlib
import json
import os
import resource
import signal
import subprocess
import sys
import time
from pathlib import Path
from stage55_source_forward_oracle import count, unrank, tiny, source_rank

def digest(data):
    return hashlib.sha256(data).hexdigest()

def run_request(request, output):
    resource.setrlimit(resource.RLIMIT_AS, (2*1024**3, 2*1024**3))
    signal.alarm(300)
    started = time.monotonic()
    data = json.loads(request.read_text(encoding="utf-8"))
    op = data["operation"]
    lengths = data["lengths"]
    if isinstance(lengths, int): lengths = [lengths]
    if not isinstance(lengths, list) or not 1 <= len(lengths) <= 47 or any(type(n) is not int or n < 1 or n > 123 for n in lengths) or sum(lengths) > 5778:
        raise ValueError("invalid normative weaving lengths")
    lengths = tuple(lengths)
    if op not in ("count", "unrank") or set(data) != ({"operation", "lengths"} | ({"rank"} if op == "unrank" else set())):
        raise ValueError("invalid request shape")
    total = count((lengths, 0, 0))
    response = {"operation": op, "count": str(total)}
    if op == "unrank":
        rank = data["rank"]
        if not isinstance(rank, str) or not rank.isascii() or not rank.isdecimal() or rank.startswith("0"):
            raise ValueError("rank must be a canonical positive decimal string")
        word = unrank(lengths, int(rank))
        response["word"] = word
        response["positions"] = len(word)
    response["elapsed_seconds"] = time.monotonic() - started
    response["rss_kib"] = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    pending = output.with_suffix(output.suffix + ".tmp")
    pending.write_text(json.dumps(response, separators=(",", ":"))+"\n", encoding="utf-8")
    os.replace(pending, output)
    print("FORWARD_WORKER_PASS", op, response["elapsed_seconds"], flush=True)

def preflight():
    # The fixture is used only to exercise the generic interface, never in run_request.
    assert tiny() == dict(families=115, states=1335, edges=1697, words=1408)
    root = Path(__file__).resolve().parent.parent
    f = json.loads((root/"tests/fixtures/stage55_year5000_appendix_a_metadata.json").read_text())
    out = root/"logs/stage55_forward_worker/preflight"
    out.mkdir(parents=True, exist_ok=True)
    def invoke(name, request, expected_success=True):
        inp, resp = out/(name+".request.json"), out/(name+".response.json")
        resp.unlink(missing_ok=True)
        inp.write_text(json.dumps(request), encoding="utf-8")
        with (out/(name+".log")).open("w") as log:
            result = subprocess.run([sys.executable, str(Path(__file__).resolve()), str(inp), str(resp)], stdout=log, stderr=subprocess.STDOUT, timeout=320)
        assert (result.returncode == 0) == expected_success
        if not expected_success:
            assert not resp.exists()
            return None
        return json.loads(resp.read_text())
    lengths = f["month_lengths"]
    total = invoke("count", {"operation":"count","lengths":lengths})["count"]
    assert digest(total.encode()) == "c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8"
    rank, _ = source_rank(f["calculation_day"], f["first_day"], int(total))
    assert digest(str(rank).encode()) == "160ca5c4a8ee5d0ec29c583a0d7ab91a71d8be4b7dc4c139ebaae066596dcff3"
    result = invoke("source", {"operation":"unrank","lengths":lengths,"rank":str(rank)})
    assert result["count"] == total and result["positions"] == 4244
    assert digest((json.dumps(result["word"],separators=(",",":"))+"\n").encode()) == "76396b8dc72b209c9f273d7ebbab3c6a09b3424eff8ee71acd1566680641786e"
    for rank in ("0","3"):
        invoke("reject-"+rank, {"operation":"unrank","lengths":[2,2],"rank":rank}, False)
    print("FORWARD_GENERIC_PREFLIGHT_PASS tiny115/1335/1697/1408 source4244/4244", flush=True)

if __name__ == "__main__":
    if sys.argv[1:] == ["--preflight"]:
        preflight()
    elif len(sys.argv) == 3:
        run_request(Path(sys.argv[1]), Path(sys.argv[2]))
    else:
        raise SystemExit("usage: stage55_forward_worker.py REQUEST RESPONSE | --preflight")
