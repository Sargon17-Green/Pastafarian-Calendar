#!/usr/bin/env python3
"""QA-only, source-locked statement checkpointing; NEVER Stage1 acceptance."""
from __future__ import annotations
import argparse, hashlib, json, pathlib, sys
from chunked_fx_probe import marker_write
from stage01_ec_probe import build_error_code_probe
from stage01_fx_prefix_probe import nested_fx_expression
from stage01_import_workspace import SOURCE_COMMIT, _codes, fx_definition_lines, load_locked_sources
from stage01_subtest_probe import LX_ENTRY

TARGETS=(("RunStage01OwnershipTests","QAStage01Ownership"),
         ("RunStage01OracleStateTests","QAStage01OracleState"),
         ("RunStage01YearTests","QAStage01Year"))
FINAL="APL_GERMAN_STATEMENT_DIAGNOSTIC_COMPLETE_NOT_STAGE01"

def decode_programs(data):
    lines=data.decode("cp1252").splitlines(keepends=True)
    found=[]
    for i,line in enumerate(lines):
        m=LX_ENTRY.fullmatch(line)
        if m:
            outer=m["serialized"].replace("{diamond}","⋄").replace("{quad}","⎕")
            if outer.count("⎕EC ⎕UCS ") in (31,34):
                found.append((i,m,outer))
    if len(found)!=1:
        raise ValueError("LX_NOT_UNIQUE")
    pos,match,outer=found[0]
    units=outer.split(" ⋄ ")
    if len(units) not in (31,34) or any(not x.startswith("⎕EC ⎕UCS ") for x in units):
        raise ValueError("EC_PROGRAM_COUNT_INVALID")
    programs=["".join(chr(int(n)) for n in unit[len("⎕EC ⎕UCS "):].split()) for unit in units]
    return lines,pos,match,programs

def build_statement_probe(raw,root,marker):
    root=pathlib.Path(root).resolve()
    base,base_receipt=build_error_code_probe(raw,root,marker)
    lines,pos,match,old=decode_programs(base)
    if (len(old)!=31 or base_receipt["source_commit"]!=SOURCE_COMMIT or
        base_receipt["function_count"]!=95 or base_receipt["chunk_count"]!=23):
        raise ValueError("LOCKED_EC_BASE_INVALID")
    locked=load_locked_sources(root)
    blocks={b["name"]:b for b in locked["blocks"]}
    p=pathlib.PureWindowsPath(marker)
    copies=[]; fx_records=[]; tests=[]
    for index,(name,alias) in enumerate(TARGETS,5):
        b=blocks[name]
        definition=fx_definition_lines(b)
        if not definition[0].startswith(name+";"):
            raise ValueError("UNSUPPORTED_TEST_HEADER:"+name)
        modified=[alias+definition[0][len(name):]]
        retained=[]; statements=[]
        for offset,line in enumerate(definition[1:],1):
            if not line.strip() or line.lstrip().startswith("⍝"):
                modified.append(line);retained.append(line);continue
            if "⋄" in line or line.lstrip().startswith(":"):
                raise ValueError("COMPOUND_OR_CONTROL_LINE:"+name)
            seq=len(statements)+1
            source_line=b["start_line"]+offset
            marks={}
            for phase in ("start","end"):
                token=(f"APL_GERMAN_STMT_V1|SOURCE={SOURCE_COMMIT}|TEST={index:02d}"
                       f"|SEQ={seq:03d}|LINE={source_line:04d}|PHASE={phase.upper()}")
                path=str(p.with_name(f"{p.stem}_stmt_{index:02d}_{seq:03d}_{phase}.txt"))
                marks[phase+"_path"]=path;marks[phase+"_token"]=token
            indent=line[:len(line)-len(line.lstrip())]
            modified.extend([indent+marker_write(marks["start_token"],marks["start_path"]),
                             line,indent+marker_write(marks["end_token"],marks["end_path"])])
            retained.append(line)
            statements.append(dict(sequence=seq,source_line=source_line,
                source_text=line,source_sha256=hashlib.sha256(line.encode()).hexdigest(),**marks))
        if [name+modified[0][len(alias):]]+retained != definition:
            raise ValueError("SOURCE_STATEMENTS_CHANGED")
        if len(statements)<5:
            raise ValueError("INSUFFICIENT_STATEMENTS")
        fx_token=(f"APL_GERMAN_STMT_FX_V1|SOURCE={SOURCE_COMMIT}"
                  f"|INDEX={index:02d}|ALIAS={alias}|PHASE=COMPILED")
        fx_path=str(p.with_name(f"{p.stem}_stmt_{index:02d}_fx.txt"))
        copies.append("95 Stage01ChunkAssert 0 ⋄ ⎕FX "+nested_fx_expression(modified)+
                      " ⋄ "+marker_write(fx_token,fx_path))
        fx_records.append(dict(index=index,name=name,alias=alias,fx_token=fx_token,
                               fx_path=fx_path,code_sha256=hashlib.sha256(
                                   "\n".join(modified).encode()).hexdigest()))
        tests.append(dict(index=index,name=name,alias=alias,
                          statement_count=len(statements),statements=statements))
    calls=[]; call_receipts=[]
    for index,(_,alias) in enumerate(TARGETS,5):
        prior=base_receipt["probes"][index-1]
        captured_token=(f"APL_GERMAN_STMT_EC_V1|SOURCE={SOURCE_COMMIT}"
                        f"|INDEX={index:02d}|ALIAS={alias}|PHASE=CAPTURED_NOT_PASS")
        captured_path=str(p.with_name(f"{p.stem}_stmt_{index:02d}_captured.txt"))
        code_path=str(p.with_name(f"{p.stem}_stmt_{index:02d}_code.txt"))
        v=f"QAStmtEC{index:02d}"
        calls.append("95 Stage01ChunkAssert 0 ⋄ "+
          marker_write(prior["start_token"],prior["start_path"])+
          f" ⋄ {v}←⎕EC ⎕UCS {_codes(alias)}"+
          f" ⋄ (⍕{v}[1]) ⎕NAPPEND ((⎕UCS {_codes(code_path)}) ⎕NCREATE 0)"+
          " ⋄ "+marker_write(captured_token,captured_path))
        call_receipts.append(dict(index=index,name=prior["name"],alias=alias,
                                 start_path=prior["start_path"],start_token=prior["start_token"],
                                 captured_path=captured_path,captured_token=captured_token,
                                 code_path=code_path,message_code_path=None))
    final="95 Stage01ChunkAssert 0 ⋄ "+marker_write(FINAL,marker)
    programs=old[:23]+copies+old[23:27]+calls+[final]
    outer=" ⋄ ".join("⎕EC ⎕UCS "+_codes(x) for x in programs)
    escaped=outer.replace("⎕","{quad}").replace("⋄","{diamond}")
    if not escaped.isascii() or "'" in escaped or '"' in escaped or escaped.replace(
        "{quad}","⎕").replace("{diamond}","⋄")!=outer:
        raise ValueError("WORKSPACE_SERIALIZATION_UNSAFE")
    lines[pos]=(f"{match['prefix']}{len(outer)} 1 {len(outer)} "
                f"'{escaped}'{match['ending']}")
    candidate="".join(lines).encode("cp1252")
    receipt=dict(schema="APL_GERMAN_STAGE01_STATEMENT_DIAGNOSTIC_V1",
                 stage01="NOT_ACCEPTED",status="GENERATED_NOT_NATIVE_VALIDATED",
                 source_commit=SOURCE_COMMIT,function_count=95,chunk_count=23,
                 chunk_records=base_receipt["chunk_records"],
                 import_program_sha256=base_receipt["import_program_sha256"],
                 source_manifest_sha256=base_receipt["source_manifest_sha256"],
                 instrumented_copies=fx_records,tests=tests,calls=call_receipts,
                 final_original_stage01_tests_executed=False,
                 original_stage01_acceptance_token_present=False,
                 marker_token=FINAL,marker_path=marker,program_count=len(programs),
                 candidate_sha256=hashlib.sha256(candidate).hexdigest())
    return candidate,receipt

def main():
    p=argparse.ArgumentParser()
    for arg in ("repo-root","source","candidate","receipt","marker"):
        p.add_argument("--"+arg,required=True)
    a=p.parse_args();target=pathlib.Path(a.receipt)
    try:
        data,rec=build_statement_probe(pathlib.Path(a.source).read_bytes(),a.repo_root,a.marker)
        pathlib.Path(a.candidate).write_bytes(data)
        target.write_text(json.dumps(rec,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
        print("STATEMENT_CANDIDATE_GENERATED_NOT_NATIVE",rec["candidate_sha256"])
        return 0
    except Exception as e:
        target.write_text(json.dumps(dict(status="GENERATION_FAILED",stage01="NOT_ACCEPTED",
            error=f"{type(e).__name__}:{e}")),encoding="utf-8")
        print("STATEMENT_GENERATION_FAILED",e,file=sys.stderr)
        return 2

if __name__=="__main__":
    raise SystemExit(main())
