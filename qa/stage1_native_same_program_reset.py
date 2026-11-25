#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Befunge-98 exact SAME PyFunge Program object reset/replay.

This exercises an explicitly defined reset between executions: replace the
completed Program's mutable Funge-space, fresh I/O platform, and create a new
IP. Reuse the SAME Program object identity across every call. Merely calling
Program.load_code on previously mutated Funge-space is NOT a reset.

No Python computation of calendar reference values. Every expected output is
obtained from an independent native CLI PyFunge-98 process running exactly
the same Befunge code. Dedicated native reference/fixture suites test math.
"""
from __future__ import print_function
import StringIO
import hashlib
import json
import subprocess
import sys

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from qa31cm_retired_space_guard import RetiredSpaces

SOURCES = [
    "src/interleaved_work_counts.b98",
    "qa/interleaved_work_counts_pre_lexical_baseline.b98",
]
OUTPUT_WIDTH = {
    "src/base_context.b98": 4, "src/base_validator.b98": 1, "src/bootstrap.b98": 1,
    "src/day_count.b98": 1, "src/error_wrapper.b98": 1, "src/interleaved_day_save.b98": 2,
    "src/interleaved_work_counts.b98": 7, "src/logging_shell.b98": 2,
    "src/metrics_shell.b98": 2, "src/runtime_contract.b98": 1, "src/save.b98": 1,
}
CODES = {}
for path in set(SOURCES) | set(OUTPUT_WIDTH):
    with open(path,"rb") as stream:
        CODES[path] = stream.read()

CMD = ["timeout","--kill-after=2s","50s",
       "pyfunge","--disable-fprint","--no-concurrent",
       "--no-filesystem","-v98","-d2"]

def run_cli(path,input_text):
    proc=subprocess.Popen(CMD+[path],stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=proc.communicate(input_text)
    if proc.returncode:
        raise AssertionError("native baseline process error %s rc=%d stderr=%r" %
                             (path,proc.returncode,err[-500:]))
    result=out.split()
    if len(result)!=OUTPUT_WIDTH.get(path,7):
        raise AssertionError("native CLI unexpected output width for %s: %r" % (path,result))
    return result

def fresh_platform(raw):
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    return platform,stdout

BASE_POSITIONS=((0,0),(5,0),(10,49),(500,1500),(100,500),(1528,2014))

def sample(space,vector_cls,positions):
    return tuple(space.get(vector_cls(p)) for p in positions)

def replay(program,source_path,raw,iteration,previous,guard,ownership,receipts=None):
    if program.ips:
        raise AssertionError("prior native IP was not fully terminated")

    old_space=program.space
    guard.check(old_space, "before-reset")
    old_semantics=program.semantics
    object_id=id(program)
    if previous:
        old_snapshot,old_vector_type,old_positions=previous
        if sample(old_space,old_vector_type,old_positions)!=old_snapshot:
            raise AssertionError("prior completed Funge-space changed before reset")
    platform,stdout=fresh_platform(raw)

    # A Program holds *two* relevant references: its mutable Funge-space
    # and its semantics instance, whose platform performs native I/O.
    # Assigning program.platform alone does NOT update semantics.platform
    # and can send all stdout to the stale stream. The existing Program
    # object is explicitly reinitialized via PyFunge's own constructor.
    # This refreshes semantics, Funge-space, IP queue, and I/O together.
    Program.__init__(program,Befunge98,platform=platform)
    guard.check(program.space, "after-reset")
    if id(program)!=object_id:
        raise AssertionError("reset replaced the original Program identity")
    if program.semantics is old_semantics:
        raise AssertionError("reset retained stale opcode semantics")
    if program.semantics.platform is not platform:
        raise AssertionError("reset failed to bind semantics to new input/output")
    if program.space is old_space:
        raise AssertionError("new run reused previous mutable Funge-space")
    if program.ips:
        raise AssertionError("program reinitialization retained old IPs")
    program.load_code(CODES[source_path])
    program.create_ip()
    if len(program.ips)!=1:
        raise AssertionError("reset failed to create one fresh instruction pointer")
    ip=program.ips[0]
    vector_cls=ip.position.__class__
    if tuple(ip.position)!=(0,0) or tuple(ip.delta)!=(1,0):
        raise AssertionError("fresh IP initial position/direction corrupted")
    if len(ip.stack[0])!=0:
        raise AssertionError("new IP stack not empty at execution start")
    if program.space.get(vector_cls((0,0)))!=ord(CODES[source_path][0:1]):
        raise AssertionError("source entry is not freshly loaded")

    if len(stdout.getvalue())!=0:
        raise AssertionError("unexpected output before execute")
    space=program.space
    cls=type(space)
    original_put=cls.put
    written={}
    def observed_put(receiver,*args,**kwargs):
        if receiver is not space or len(args)<2:
            raise AssertionError("foreign or unrecognized native memory write")
        address=tuple(int(v) for v in args[0])
        result=original_put(receiver,*args,**kwargs)
        value=int(args[1])
        if len(address)!=2 or int(receiver.get(args[0]))!=value:
            raise AssertionError("native write value or dimension mismatch")
        writes=written.get(address,(0,None))[0]
        written[address]=(writes+1,str(value))
        return result
    cls.put=observed_put
    try:
        program.execute()
    finally:
        cls.put=original_put
    guard.check(space, "after-execute")
    if program.ips:
        raise AssertionError("native Program.execute left unclean IP list")
    got=stdout.getvalue().split()
    expected=run_cli(source_path,raw)
    if got!=expected:
        raise AssertionError("same Program reset/replay %d %r got=%r expected=%r" %
                             (iteration,raw,got,expected))
    # Previous Funge-space object must remain untouched by the new run.
    if previous:
        if sample(old_space,old_vector_type,old_positions)!=old_snapshot:
            raise AssertionError("new Program run contaminated old Funge-space")
    code=CODES[source_path]
    blob=hashlib.sha1("blob %d\0"%len(code)+code).hexdigest()
    record=guard.retain(space,vector_cls,BASE_POSITIONS,written)
    record.update(path=source_path, source_blob=blob, input=raw, output=got,
                  native_fresh_cli=expected,
                  writes=[[list(pos),count,last] for pos,(count,last) in sorted(written.items())])
    ownership.append(record)
    # Preserve the legacy receipt format. The separate record above covers every run.
    positions=tuple(sorted(set(BASE_POSITIONS) | (set(written) if receipts is not None else set())))
    snapshot=sample(program.space,vector_cls,positions)
    if receipts is not None:
        receipts.append({"path":source_path,"input":raw,"output":got,"native_fresh_cli":expected,
                         "source_blob":blob,
                         "written_addresses":[list(p) for p in sorted(written)],
                         "previous_addresses_checked":len(old_positions) if previous else 0,
                         "retained_addresses":len(positions)})
    return snapshot,vector_cls,positions

qa=SOURCES[0]
original=SOURCES[1]
CASES=[
    (qa,"1 15055672 1 15055670\n"),
    (qa,"2 10 0 10\n"),
    (qa,"0 -1 0 1\n"),
    (qa,"0 0 0 0\n"),
    (qa,"1 15055671 1 15055671\n"),
    (original,"0 1 0 1\n"),
    (qa,"0 -1 0 1\n"),
    (original,"0 -1 0 1\n"),
    (qa,"0 123456789 1 987654321\n"),
    (qa,"1 987654321 0 123456789\n"),
    (qa,"0 170141183460469231731687303715884105727 1 1\n"),
    (qa,"1 0 0 0\n"),
    (qa,"0 1 0 2\n"),
    (qa,"0 2 0 1\n"),
    (original,"1 15055672 1 15055670\n"),
    (qa,"0 1 0 1\n"),
]
if run_cli(original,"0 -1 0 1\n")!=run_cli(original,"0 1 0 1\n"):
    raise AssertionError("old source no longer exhibits the lexical bug")
if run_cli(qa,"0 -1 0 1\n")==run_cli(qa,"0 1 0 1\n"):
    raise AssertionError("QA source still accepts the forbidden sign")

platform,output=fresh_platform("")
program=Program(Befunge98,platform=platform)
identity=id(program)
previous=None
guard=RetiredSpaces()
ownership=[]
print("NATIVE_SAME_PROGRAM_RESET_PREFLIGHT_PASS")
for iteration,(source_path,raw) in enumerate(CASES):
    previous=replay(program,source_path,raw,iteration,previous,guard,ownership)
    if id(program)!=identity:
        raise AssertionError("test accidentally replaced Program object")
    print("NATIVE_SAME_PROGRAM_OBJECT_REPLAY_PASS",iteration,
          source_path,repr(raw.strip()))
print("NATIVE_SAME_PROGRAM_OBJECT_RESET_PASS",len(CASES),
      "runs in exact same object with clean spaces/IPs/streams")
print("SCOPE: explicit reset contract. In-place no-reset execution is NOT safe.")

# Switch between all eleven Stage-1 production entry points on the same Program.
# The final stateless invocation also checks the last stateful snapshot.
extra_cases=[
    ("base_context",""), ("bootstrap","10"), ("base_validator","1 0"),
    ("interleaved_day_save","1 15055672"), ("metrics_shell","42 7"),
    ("day_count","0 0"), ("error_wrapper","1 42"), ("save","1 1"),
    ("runtime_contract",""), ("logging_shell","42 7"),
    ("interleaved_work_counts","0 0 0 1"), ("day_count","1 0"),
    ("interleaved_day_save","0 0"), ("save","0 0"), ("base_context",""),
]
receipts=[]
for index,(name,raw) in enumerate(extra_cases):
    name="src/"+name+".b98"
    previous=replay(program,name,raw+"\n",index,previous,guard,ownership,receipts)
    if id(program)!=identity:
        raise AssertionError("lost the original Program identity")
    if index and receipts[-1]["previous_addresses_checked"]!=receipts[-2]["retained_addresses"]:
        raise AssertionError("missed addresses written by the previous execution")
stateful={"src/"+n+".b98" for n in ("bootstrap","day_count","save","interleaved_day_save","interleaved_work_counts")}
if {r["path"] for r in receipts}!=set(OUTPUT_WIDTH):
    raise AssertionError("incomplete Stage-1 entry-point coverage")
if {r["path"] for r in receipts if r["written_addresses"]}!=stateful:
    raise AssertionError("unexpected production state owner")
if len(sys.argv)>1:
    with open(sys.argv[1],"wb") as stream:
        stream.write(json.dumps(receipts,indent=2,sort_keys=True)+"\n")
if len(sys.argv)>2:
    with open(sys.argv[2],"wb") as stream:
        stream.write(json.dumps({"runs":ownership,"phases":guard.checks},
                                sort_keys=True, separators=(",",":"))+"\n")
if len(ownership)!=31 or len(guard.checks)!=93 or sum(r["retired"] for r in guard.checks)!=1395:
    raise AssertionError("incomplete all-spaces native ownership record")
print("NATIVE_ALL_RETIRED_SPACES_PASS",len(ownership),len(guard.checks),
      sum(r["cells"] for r in guard.checks),"cell comparisons")
print("NATIVE_STAGE1_ALL_ENTRYPOINTS_EXPLICIT_RESET_PASS",len(OUTPUT_WIDTH),"sources",
      len(receipts),"executions",len(stateful),"physical writers")
