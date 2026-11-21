#!/usr/bin/env python3
"""Stage19 source-pinned original-runtime Native gate; does not itself ACCEPT Stage19."""
import hashlib,json,os,re,subprocess,sys
from pathlib import Path
import stage19_bowl_position_fixture as fixture
E=Path("evidence/stage19_native");SOURCE=os.environ["SOURCE_PIN"];RUNTIME=os.environ["RUNTIME_PIN"]
LOCKED=("src/bigint.false","src/monster_bootstrap.false","test/stage19_bowl_position_design_vectors.json","tools/stage19_bowl_position_design_oracle.mjs","tools/stage19_bowl_position_fixture.py","tools/stage19_bowl_position_ci.py","RUN_STAGE19.md","STAGE_19_EXECUTION_STATUS.txt",".github/workflows/canonical-names-lock.yml",".github/workflows/false-arabic-stage19-native-bowl-position.yml")
def sha(data):return hashlib.sha256(data).hexdigest()
def source_bytes(path):
    expected=subprocess.check_output(["git","show",f"{SOURCE}:{path}"]);actual=Path(path).read_bytes()
    assert actual==expected,("SOURCE_DRIFT",path);return actual
def execute(label,code,seconds):
    program=E/(label+".false");program.write_bytes(code)
    try:
        p=subprocess.run(["upstream/false_int","-e",str(program)],capture_output=True,timeout=seconds);result=(p.returncode,p.stdout,p.stderr)
    except subprocess.TimeoutExpired as e:result=(124,e.stdout or b"",e.stderr or b"")
    (E/(label+".exit_code.txt")).write_text(str(result[0])+"\n");(E/(label+".stdout.txt")).write_bytes(result[1]);(E/(label+".stderr.txt")).write_bytes(result[2])
    return result
def main():
    E.mkdir(parents=True,exist_ok=True)
    assert (E/"source_observed.txt").read_text().strip()==SOURCE and (E/"runtime_observed.txt").read_text().strip()==RUNTIME
    assert (E/"compiler_exit_code.txt").read_text().strip()=="0" and (E/"preflight.txt").read_text().strip()=="ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    blobs={p:source_bytes(p) for p in LOCKED};source=blobs["src/monster_bootstrap.false"].decode()
    assert "z;36=~" in source and "E_BOWL_POSITION_LENGTH" in source
    prefix=blobs["src/bigint.false"]+b"\n"+blobs["src/monster_bootstrap.false"]+b"\n"
    # One-case memory/call diagnostic. This is evidence only; it does not gate or ACCEPT Stage19.
    diagnostic_lines = [
        "{ Stage19 tuple/table layout diagnostic; no acceptance claim. }",
        "z;d:6a;!1a;!2a;!3a;!4a;!5a;!6a;!",
        'd;g;!6=["STAGE19_DIAG_TABLE_HEADER_OK"10,]?',
        'd;g;!6=~["STAGE19_DIAG_TABLE_HEADER_BAD"10,]?',
        'd;1+g;!1=["STAGE19_DIAG_TABLE_CELL1_OK"10,]?',
        'd;1+g;!1=~["STAGE19_DIAG_TABLE_CELL1_BAD"10,]?',
        'd;2+g;!2=["STAGE19_DIAG_TABLE_CELL2_OK"10,]?',
        'd;2+g;!2=~["STAGE19_DIAG_TABLE_CELL2_BAD"10,]?',
        'd;3+g;!3=["STAGE19_DIAG_TABLE_CELL3_OK"10,]?',
        'd;3+g;!3=~["STAGE19_DIAG_TABLE_CELL3_BAD"10,]?',
        'd;4+g;!4=["STAGE19_DIAG_TABLE_CELL4_OK"10,]?',
        'd;4+g;!4=~["STAGE19_DIAG_TABLE_CELL4_BAD"10,]?',
        'd;5+g;!5=["STAGE19_DIAG_TABLE_CELL5_OK"10,]?',
        'd;5+g;!5=~["STAGE19_DIAG_TABLE_CELL5_BAD"10,]?',
        'd;6+g;!6=["STAGE19_DIAG_TABLE_CELL6_OK"10,]?',
        'd;6+g;!6=~["STAGE19_DIAG_TABLE_CELL6_BAD"10,]?',
        "z;b:d;a;!1a;!b;s:b;36h;!!o:",
        'b;g;!d;=["STAGE19_DIAG_TUPLE_TABLE_OK"10,]?',
        'b;g;!d;=~["STAGE19_DIAG_TUPLE_TABLE_BAD"10,]?',
        'b;1+g;!1=["STAGE19_DIAG_TUPLE_BOWL_OK"10,]?',
        'b;1+g;!1=~["STAGE19_DIAG_TUPLE_BOWL_BAD"10,]?',
        'o;0=["STAGE19_DIAG_RESULT_ZERO"10,]?',
        'o;1=["STAGE19_DIAG_RESULT_ONE"10,]?',
        'o;2=["STAGE19_DIAG_RESULT_TWO"10,]?',
        'o;3=["STAGE19_DIAG_RESULT_THREE"10,]?',
        'o;4=["STAGE19_DIAG_RESULT_FOUR"10,]?',
        'o;5=["STAGE19_DIAG_RESULT_FIVE"10,]?',
        'o;6=["STAGE19_DIAG_RESULT_SIX"10,]?',
        '"STAGE19_DIAG_RESULT="o;48+,10,',
        'd;g;!6=["STAGE19_DIAG_POST_HEADER_OK"10,]?',
        'b;g;!d;=["STAGE19_DIAG_POST_TUPLE_TABLE_OK"10,]?',
        'b;1+g;!1=["STAGE19_DIAG_POST_TUPLE_BOWL_OK"10,]?',
        '"STAGE19_DIAG_DONE"10,',
    ]
    diagnostic_code = prefix + ("\n".join(diagnostic_lines) + "\n").encode()
    diagnostic_exit, diagnostic_out, diagnostic_err = execute("tuple_diagnostic", diagnostic_code, 30)
    tuple_diagnostic = dict(exit_code=diagnostic_exit,
                            stdout=diagnostic_out.decode("utf-8", "replace"),
                            stderr=diagnostic_err.decode("utf-8", "replace"))
    summary=fixture.integrity();assert len(summary)==6 and sum(x["cases"] for x in summary)==4320
    positive=[];verified=True
    for start,orders in fixture.chunks():
        program,wanted,order_wanted,final,checks=fixture.positive_fixture(orders,start)
        assert sha(program.encode())==next(x["sha256"] for x in summary if x["start_order"]==start)
        code,out,err=execute("positive_"+str(start),prefix+program.encode(),300);txt=out.decode("utf-8","replace")
        labels=re.findall(r"STAGE19_CASE_\d{4}_OK",txt);errors=re.findall(r"STAGE19_[A-Z0-9_]+_FAIL",txt);order_labels=re.findall(r"STAGE19_ORDER_\d{3}_OK",txt)
        passed=code==0 and err==b"" and labels==wanted and order_labels==order_wanted and not errors and txt.count(final)==1 and txt.rstrip().endswith(final)
        positive.append(dict(start_order=start,orders=len(orders),cases=len(wanted),assertions=checks,exit_code=code,labels_seen=len(labels),order_markers_seen=len(order_labels),passed=passed,generated_fixture_sha256=sha(program.encode())))
        verified=verified and passed
        if not passed:
            if start == 0:
                # Independent on-failure original-runtime diagnostic, not a PASS or a production mutation.
                first_program = fixture.positive_fixture(orders[:1], start)[0]
                anchor = "36h;!!o:\n"
                assert first_program.count(anchor) == 6
                traced = ('36h;!!o:\n'
                          'o;0=["STAGE19_DIAG_RESULT_ZERO"10,]?\n'
                          'o;1=["STAGE19_DIAG_RESULT_ONE"10,]?\n'
                          'o;2=["STAGE19_DIAG_RESULT_TWO"10,]?\n'
                          'o;6=["STAGE19_DIAG_RESULT_SIX"10,]?\n'
                          'o;6>["STAGE19_DIAG_RESULT_GT6"10,]?\n'
                          'o;0<["STAGE19_DIAG_RESULT_NEGATIVE"10,]?\n'
                          'd;g;!6=["STAGE19_DIAG_HEADER_SIX"10,]?\n'
                          'b;g;!d;=["STAGE19_DIAG_ORDER_ARGUMENT_MATCH"10,]?\n'
                          'b;1+g;!1=["STAGE19_DIAG_BOWL_ONE"10,]?\n'
                          '"STAGE19_DIAG_ASCII_RESULT="o;48+,10,\n')
                first_program = first_program.replace(anchor, traced, 1)
                execute("diagnostic_first_scalar", prefix + first_program.encode(), 30)
            break
    parsed=json.loads(Path("test/stage19_bowl_position_design_vectors.json").read_text(encoding="utf-8"))
    probe_program,probe_wanted,probe_final,probe_checks=fixture.probe_fixture(parsed["probes"])
    probe_code,probe_out,probe_err=execute("positive_probes",prefix+probe_program.encode(),60);probe_txt=probe_out.decode("utf-8","replace")
    probe_labels=re.findall(r"STAGE19_PROBE_\d{3}_OK",probe_txt)
    probes_passed=probe_code==0 and probe_err==b"" and probe_labels==probe_wanted and not re.findall(r"STAGE19_[A-Z0-9_]+_FAIL",probe_txt) and probe_txt.count(probe_final)==1 and probe_txt.rstrip().endswith(probe_final)
    mutants={}
    for name,marker in (("wrong_expected","STAGE19_CASE_0000_POSITION_FAIL"),("wrong_duplicate_last","STAGE19_PROBE_005_POSITION_FAIL")):
        if name=="wrong_expected":mp=fixture.positive_fixture(fixture.chunks()[0][1][:1],0,mutant=name)[0]
        else:mp=fixture.probe_fixture(parsed["probes"],mutant=name)[0]
        mc,mo,me=execute("mutant_"+name,prefix+mp.encode(),30);mt=mo.decode("utf-8","replace")
        mutants[name]=dict(exit_code=mc,rejected=mc==1 and marker in mt,expected_error=marker,observed_stdout=mt)
    bad_lengths={}
    for length in (5,7):
        lc,lo,le=execute("bad_length_"+str(length),prefix+fixture.invalid_length_fixture(length).encode(),30);lt=(lo+le).decode("utf-8","replace")
        bad_lengths[str(length)]=dict(exit_code=lc,rejected=lc==1 and "E_BOWL_POSITION_LENGTH" in lt,observed=lt)
    passed=verified and len(positive)==6 and all(x["passed"] for x in positive) and probes_passed and all(x["rejected"] for x in mutants.values()) and all(x["rejected"] for x in bad_lengths.values())
    receipt=dict(project_id=os.environ["PROJECT_ID"],stage=19,reference_operation=53,production_operation=36,github_sha=os.getenv("GITHUB_SHA"),github_run_id=os.getenv("GITHUB_RUN_ID"),source_pin=SOURCE,runtime_pin=RUNTIME,source_sha256={p:sha(v) for p,v in blobs.items()},combined_source_sha256=sha(prefix),fixture_generation=summary,tuple_diagnostic=tuple_diagnostic,positive=positive,positive_cases=sum(x["cases"] for x in positive),positive_assertions=sum(x["assertions"] for x in positive),probes=dict(cases=len(probe_wanted),assertions=probe_checks,exit_code=probe_code,labels_seen=len(probe_labels),passed=probes_passed),mutants=mutants,invalid_length_controls=bad_lengths,native_gate_passed=passed,stage19_accepted=False,physical_pointer_safety_assessed=False)
    (E/"evidence.json").write_text(json.dumps(receipt,sort_keys=True,indent=2)+"\n");print(json.dumps(receipt,sort_keys=True))
    if not passed:sys.exit("STAGE19_NATIVE_GATE_NOT_VERIFIED")
if __name__=="__main__":main()
