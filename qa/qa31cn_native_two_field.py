"""Run unmodified PyFunge-98 on baseline, corrected BF98 source and two BF98 oracles (Python 2.7)."""
from __future__ import print_function
import hashlib
import json
import os
import StringIO
import sys

from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.program import Program


def need(condition, message):
    if not condition:
        raise AssertionError(message)


def native(code, raw, trace=False):
    out = StringIO.StringIO()
    platform = BufferedPlatform([], {}, stdin=StringIO.StringIO(raw), stdout=out)
    program = Program(Befunge98, platform=platform)
    program.load_code(code)
    program.create_ip()
    real_step = program.execute_step
    route = hashlib.sha256()
    tally = {"total": 0, "suffix": 0, "get": 0, "put": 0}

    def step(self):
        tally["total"] += 1
        need(tally["total"] <= 400000 and len(self.ips) == 1, "native bound or IP count")
        ip = self.ips[0]
        pos = tuple(ip.position)
        if trace and (tally["suffix"] or pos == (3, 0)):
            opcode = self.space.get(ip.position)
            event = [list(pos), list(ip.delta), opcode, list(ip.offset),
                     bool(ip.stringmode), [list(frame) for frame in ip.stack]]
            if not ip.stringmode and opcode in (ord("p"), ord("g")):
                stack = list(ip.stack[-1])
                need(len(stack) >= (3 if opcode == ord("p") else 2), "memory operand underflow")
                address = type(ip.position)([stack[-2]+ip.offset[0], stack[-1]+ip.offset[1]])
                event += [list(address), self.space.get(address)]
                tally["put" if opcode == ord("p") else "get"] += 1
            route.update(json.dumps(event, separators=(",", ":"))+"\n")
            tally["suffix"] += 1
        return real_step()

    program.execute_step = step.__get__(program, program.__class__)
    program.execute()
    need(not program.ips, "expected a clean native termination")
    return {"output": out.getvalue().split(), "steps": tally["total"],
            "suffix_steps": tally["suffix"], "suffix_sha256": route.hexdigest(),
            "suffix_g": tally["get"], "suffix_p": tally["put"]}


def read(directory, name):
    with open(os.path.join(directory, name+".b98"), "rb") as stream:
        return stream.read()


def main():
    candidates, outfile = sys.argv[1:]
    names = ("day_count", "save", "interleaved_day_save")
    before = dict((n, read("src", n)) for n in names)
    after = dict((n, read(candidates, n)) for n in names)
    refs = [read("reference", n) for n in names[:2]]
    # Whitespace, EOF without newline, semantic sign rejection, internal anchor, moduli and large integers.
    pairs = [
        ("0 0\n","0 0"), ("0 1","0 1"), ("\t1\r\n1 \t","1 1"),
        ("1 15055671\n","1 15055671"), ("1 15055672","1 15055672"),
        ("0 170141183460469231731687303715884105727\n","0 170141183460469231731687303715884105727"),
        ("1 "+("9"*81),"1 "+("9"*81)), ("1 0\n","1 0"), ("2 10\r\n","2 10"),
    ]
    malformed = ["0 -1\n","0 +1\n","0 1 7\n","0 x1\n","-0 1\n","",
                 "0","0\n","1 2x","0 1\x00","0 1\xff","0\v1","0\f1"]
    parity, rejections = [], []
    for raw, normal in pairs:
        expected = [native(ref, normal+"\n")["output"] for ref in refs]
        need(all(len(row) == 1 for row in expected), "independent reference width")
        for name, tokens in zip(names, [expected[0], expected[1], expected[0]+expected[1]]):
            old = native(before[name], normal+"\n", True)
            new = native(after[name], raw, True)
            for key in ("output","suffix_steps","suffix_sha256","suffix_g","suffix_p"):
                need(old[key] == new[key], "%s: arithmetic suffix differs for %r in %s"%(name, raw, key))
            need(new["output"] == tokens and new["suffix_steps"] > 1, "reference/entry mismatch")
            parity.append({"name":name,"raw_hex":raw.encode("hex"),"original":old,
                           "candidate":new,"native_reference":tokens})
    for index, raw in enumerate(malformed):
        for name, width in zip(names, (1,1,2)):
            new = native(after[name], raw, True)
            need(new["output"] == ["-1"]*width and not new["suffix_steps"], "raw bytes accepted")
            row = {"name":name,"raw_hex":raw.encode("hex"),"candidate":new}
            if index < 5:
                # These five inputs contain two numeric tokens under the old & reader.
                old = native(before[name], raw, True)
                need(old["output"] != ["-1"]*width and old["suffix_steps"], "missing historical RED")
                row["original"] = old
            rejections.append(row)
    report = {"exact_suffixes":parity, "lexical_rejections":rejections}
    with open(outfile,"wb") as stream:
        stream.write(json.dumps(report, sort_keys=True, indent=2)+"\n")
    print("NATIVE_TWO_FIELD_SCANNERS_PASS",len(parity),"suffix comparisons",
          len(rejections),"rejections",sum("original" in r for r in rejections),"original RED")


if __name__ == "__main__":
    main()
