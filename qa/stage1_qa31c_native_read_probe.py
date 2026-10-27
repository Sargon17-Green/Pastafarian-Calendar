#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31C: controlled physical stdin-suffix intervention, original Native IP and source.
Diagnostic-only until exact-HEAD CI + independent artifact review. No Stage1 acceptance.
"""
from __future__ import print_function
import os, sys, json, gzip, hashlib, StringIO
import stage1_qa20_native_input_route_scan as qa20

SOURCE = "560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES = {
    "valid00": (0, "782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a", 9607, 17387, 61, 176),
    "invalid18": (1, "9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd", 1455, 1672, 0, 115)
}
def need(ok, msg):
    if not ok: raise AssertionError(msg)
def sha(raw):
    return hashlib.sha256(raw).hexdigest()
def signed(root, label):
    shard, expected_sha, jtick, steps, operand, x = CASES[label]
    directory = os.path.join(root, label)
    b = open(os.path.join(directory, "qa20_manifest.json"), "rb").read()
    need(sha(b) == expected_sha, "QA20 manifest drift " + label)
    m = json.loads(b)
    need(m["shard"] == shard and m["source_git_blob"] == SOURCE
         and m["source_modified"] is False and m["ip_relocated"] is False
         and m["stage1_final_acceptance"] is False, "QA20 provenance")
    records = [r for r in m["records"] if r["label"] == label]
    need(len(records) == 1, "QA20 case absent")
    r = records[0]
    z = open(os.path.join(directory, r["path"]), "rb").read()
    need(sha(z) == r["compressed_trace_sha256"] and len(z) == r["compressed_bytes"], "QA20 trace digest")
    physical = gzip.GzipFile(fileobj=StringIO.StringIO(z), mode="rb").read().splitlines()
    need(len(physical) == steps == r["steps"] and r["output"] == r["expected"],
         "QA20 signed Native steps/output")
    return r, physical

class ReadProbe(StringIO.StringIO):
    """Buffer always holds baseline bytes; only returned read bytes may be substituted.
    Equal-length, equal-newline suffix prevents cursor and line-boundary manipulation.
    No changes to source, IP, Funge-space, stack, or PyFunge interpreter.
    """
    def __init__(self, baseline, delivered):
        need(len(baseline) == len(delivered) and baseline.count("\n") == delivered.count("\n")
             and [i for i,c in enumerate(baseline) if c=="\n"] == [i for i,c in enumerate(delivered) if c=="\n"],
             "intervention changes length or newline offsets")
        StringIO.StringIO.__init__(self, baseline)
        self.baseline, self.delivered = baseline, delivered
        self.events = []
        self.tick, self.ip = 0, None
    def _record(self, method, start, old):
        end = self.tell()
        need(end-start == len(old), "unexpected Native stdin cursor operation")
        replacement = self.delivered[start:end]
        ip = self.ip
        need(ip is not None and self.tick > 0, "Native read outside physical STEP")
        state = (int(ip.position[0]), int(ip.position[1]), int(ip.delta[0]), int(ip.delta[1]),
                 int(bool(ip.stringmode)))
        toss = list(ip.stack[-1]) if len(ip.stack) else []
        self.events.append({"tick": self.tick, "method": method, "start": start, "end": end,
                            "ip": list(state), "toss_sha256": sha(repr(toss)),
                            "baseline_hex": old.encode("hex"), "delivered_hex": replacement.encode("hex")})
        return replacement
    def read(self, *args):
        start = self.tell()
        return self._record("read", start, StringIO.StringIO.read(self, *args))
    def readline(self, *args):
        start = self.tell()
        return self._record("readline", start, StringIO.StringIO.readline(self, *args))

def execute(source, root, mode, baseline, delivered, orig_label, output_dir):
    original, signed_steps = signed(root, orig_label)
    _, _, jt, stepcount, op, x = CASES[orig_label]
    stream = ReadProbe(baseline, delivered)
    stdout = StringIO.StringIO()
    platform = qa20.BufferedPlatform([], {}, stdin=stream, stdout=stdout)
    program = qa20.Program(qa20.Befunge98, platform=platform)
    program.load_code(source)
    program.create_ip()
    need(len(program.ips) == 1, "not one natural initial IP")
    item = {"program": program, "steps": 0, "stdin": stream, "stdout": stdout}
    raw_trace = []
    witness = None
    while program.ips:
        need(len(program.ips) == 1, "unexpected multiple IPs")
        ip = program.ips[0]
        tick = item["steps"] + 1
        need(tick <= stepcount, "Native diverged beyond signed physical-step bound: " + mode)
        step = (tick, int(ip.position[0]), int(ip.position[1]), int(ip.delta[0]), int(ip.delta[1]),
                int(program.space.get(ip.position)), int(bool(ip.stringmode)))
        raw = "\t".join(map(str, step))
        need(raw == signed_steps[tick-1], "signed physical STEP changed %s:%d" % (mode,tick))
        raw_trace.append(raw + "\n")
        stream.tick, stream.ip = tick, ip
        if tick == jt:
            stack = ip.stack
            need(len(stack) > 0 and not stack.queuemode and not stack.invertmode, "j stack mode")
            pre = list(stack[-1])
            measured = int(pre[-1] if pre else 0)
            need(measured == op, "pre-j operand changed " + mode)
        qa20.tick_qa20(item)
        if tick == jt:
            need(len(program.ips) == 1 and program.ips[0] is ip, "original Native IP changed")
            post = list(ip.stack[-1])
            need(post == (pre[:-1] if pre else []), "j operand not popped once")
            succ = (tick+1, int(ip.position[0]), int(ip.position[1]),
                    int(ip.delta[0]), int(ip.delta[1]),
                    int(program.space.get(ip.position)), int(bool(ip.stringmode)))
            need("\t".join(map(str, succ)) == signed_steps[tick] and succ[1] == x,
                 "signed j successor changed")
            witness = {"tick": jt, "operand": measured, "pre_toss": pre,
                       "post_toss": post, "successor_x": succ[1]}
    need(item["steps"] == stepcount and witness is not None, "incomplete physical Native replay")
    need(stdout.getvalue().split() == original["output"], "Native final output differs signed route")
    raw = "".join(raw_trace)
    path = "qa31c_" + mode + ".steps.gz"
    with gzip.open(os.path.join(output_dir, path), "wb") as out:
        out.write(raw)
    compressed = open(os.path.join(output_dir, path), "rb").read()
    need(gzip.GzipFile(fileobj=StringIO.StringIO(compressed), mode="rb").read() == raw,
         "written STEP gzip corrupted")
    return {"mode": mode, "signed_route": orig_label, "raw_input_sha256": sha(delivered),
            "step_count": stepcount, "step_trace_file": path,
            "step_trace_sha256": sha(compressed), "uncompressed_step_sha256": sha(raw),
            "output": original["output"], "j": witness, "read_events": stream.events}

def main(root, output):
    source = open(qa20.SOURCE, "rb").read()
    need(qa20.pin(source) == SOURCE == qa20.PIN, "original production Git blob changed")
    valid, _ = signed(root, "valid00")
    invalid, _ = signed(root, "invalid18")
    baseline, alternative = valid["raw_input"], invalid["raw_input"]
    need(len(baseline) == len(alternative) and baseline != alternative, "not same-size intervention")
    first_diff = next(i for i in xrange(len(baseline)) if baseline[i] != alternative[i])
    need(first_diff >= 1, "no shared genuine input prefix")
    sham = execute(source, root, "sham", baseline, baseline, "valid00", output)
    altered = execute(source, root, "splice", baseline, alternative, "invalid18", output)
    a, b = sham["read_events"], altered["read_events"]
    changes = [i for i,e in enumerate(b) if e["baseline_hex"] != e["delivered_hex"]]
    need(len(a) > 0 and len(b) > 0 and changes, "no instrumented changed Native input read")
    idx = changes[0]
    need(idx < len(a), "first changed read not in sham")
    keys = ("tick","method","start","end","ip","toss_sha256")
    need(all(a[idx][k] == b[idx][k] for k in keys), "preintervention Native read state drift")
    need(all(a[i] == b[i] for i in xrange(idx)), "preintervention input-read history drift")
    need(b[idx]["start"] <= first_diff < b[idx]["end"] or
         any(baseline[i] != alternative[i] for i in xrange(b[idx]["start"],b[idx]["end"])),
         "first mutated read does not include changed bytes")
    need(sham["j"]["operand"] == 61 and altered["j"]["operand"] == 0,
         "input suffix failed to control measured j operand")
    report = {"schema":"qa31c-original-native-stdin-splice-diagnostic-v1",
              "source_git_blob":SOURCE,"source_modified":False,"ip_relocated":False,
              "baseline_input_sha256":sha(baseline),"alternative_input_sha256":sha(alternative),
              "shared_prefix_bytes":first_diff,"first_changed_read_index":idx,
              "first_changed_tick":b[idx]["tick"],"sham":sham,"splice":altered,
              "qa31c_accepted":False,"stage1_complete":False,
              "global_input_ownership_proven":False}
    with open(os.path.join(output,"qa31c_read_probe.json"),"wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("QA31C_DIAGNOSTIC_NATIVE_ORIGINAL_FULL_STEPS", sham["step_count"]+altered["step_count"])
    print("QA31C_REAL_STDIN_READ_INTERVENTION",idx,b[idx]["tick"],first_diff)
    print("QA31C_PRE_J_OPERANDS",sham["j"]["operand"],altered["j"]["operand"])
    print("QA31C_NOT_ACCEPTED_STAGE1_OPEN")
if __name__=="__main__":
    need(len(sys.argv)==3, "usage: QA31C QA20_ROOT OUTDIR")
    main(sys.argv[1],sys.argv[2])
