#!/usr/bin/env python3
"""One corrected Ada process per authorized target. No original F, no soak."""
import hashlib, importlib.util, json, os, re, resource, signal, subprocess, time
from pathlib import Path

BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
PARENT="0468411bcecc340b1c396daebdb0ca37f39c1ceb"
BRANCH="qa/issue29-corrected-ada-nine-date-panel-v192"
MESSAGE="qa(issue29-v192): run bounded corrected Ada nine-date panel, stop on first failure"
PANEL="qa/issue29/v191_panel.json"
VALIDATOR="qa/issue29/v191_validate_panel.py"
PATHS={".github/workflows/issue29-v192-nine-date-panel.yml","issue29_v192_panel.gpr","tests/issue29_v192_panel.adb","qa/issue29/v192_run_panel.py"}
PINS={PANEL:"4e7a8b466e7e27c6c8ddaf8773db46ad29143792",VALIDATOR:"bb8905f5ff8d357700b6cbb1b7b7894d808f6881",
"src/normative_oracle.adb":"0be8f8ab4ddef26d34963d5567707a511ebda50b",
"src/canonical_full_weave_gmp_v164.ads":"0b68edf7eddbc33869358bcfcc21e32465fc591e",
"src/canonical_full_weave_gmp_v164.adb":"845bd8905943a54e63d6aba0334404a5051fe666",
"src/canonical_wide_rank_gmp_v164.ads":"14b94e81534e98cfdb07be3824076bd7082385ea",
"src/canonical_wide_rank_gmp_v164.adb":"52b8814c2ab1924cdebafe893a65d97cd3ccfa61"}
E=Path("evidence")
TARGETS=[-15055658,-15056671,-15054671,-15057702,-15057696,-15057695,-15056944,-15056943,-15055670]
def need(ok,message):
    if not ok:raise RuntimeError(message)
def git(*args):
    return subprocess.check_output(["git",*args],stderr=subprocess.DEVNULL).decode().strip()
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,data):
    (E/name).write_text(json.dumps(data,indent=2,sort_keys=True)+"\n")
def preflight():
    need(os.environ.get("GITHUB_ACTIONS")=="true","CI only")
    need(os.environ.get("GITHUB_EVENT_NAME")=="push" and os.environ.get("GITHUB_RUN_ATTEMPT")=="1","one push attempt only")
    need(os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"branch mismatch")
    need(git("rev-parse","HEAD")==os.environ.get("GITHUB_SHA"),"HEAD mismatch")
    need(json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text()).get("head_commit",{}).get("message")==MESSAGE,"activation mismatch")
    need(git("rev-parse","HEAD^")==PARENT,"wrong panel parent")
    need(git("merge-base",BASE,"HEAD")==BASE,"wrong source ancestor")
    need(set(git("diff","--name-only",PARENT+"...HEAD").splitlines())==PATHS,"wrong QA change set")
    need(not git("diff",BASE,"HEAD","--","src"),"production src changed")
    for p,h in PINS.items():need(git("rev-parse","HEAD:"+p)==h,"source blob mismatch "+p)
    lock=Path(".github/workflows/canonical-names-lock.yml").read_text()
    need(lock.count("    if: "+"$"+"{{ false }}")==42,"legacy gates not disabled")
    panel=json.loads(Path(PANEL).read_text())
    cases=[x for x in panel["cases"] if x["run_new"]]
    need([x["t"] for x in cases]==TARGETS,"case order or set differs")
    need(all(x["c"]==-15055671 and len(x["expected"])==5 for x in cases),"wrong case fields")
    need(len(panel["cases"])==10 and all(x["t"]!=-15055671 for x in cases),"foundation excluded")
    spec=importlib.util.spec_from_file_location("v191_validator",VALIDATOR)
    v=importlib.util.module_from_spec(spec);spec.loader.exec_module(v)
    need(v.selftest(panel)["negative"]==6,"offline validator selftest failed")
    write("preflight.json",{"head":git("rev-parse","HEAD"),"parent":PARENT,"base":BASE,"pins":PINS,
         "targets":TARGETS,"panel_sha256":digest(Path(PANEL)),"legacy_native_gates_disabled":42,"original_F_calls":0})
    return panel,v,cases
def limits():
    resource.setrlimit(resource.RLIMIT_AS,(1073741824,1073741824))
    resource.setrlimit(resource.RLIMIT_CPU,(180,180))
    resource.setrlimit(resource.RLIMIT_FSIZE,(2097152,2097152))
def execute():
    panel,validator,cases=preflight()
    binary=Path("bin_v192/issue29_v192_panel").resolve()
    need(binary.is_file(),"compiled native binary missing")
    results=[]; records=[]
    verdict={"schema":"ISSUE29_V192_CORRECTED_ADA_NINE_DATE_PANEL/1","head":git("rev-parse","HEAD"),
        "base":BASE,"run_id":os.environ["GITHUB_RUN_ID"],"run_attempt":1,"binary_sha256":digest(binary),
        "expected_cases":9,"cases":results,"status":"INCOMPLETE","original_F_calls":0,
        "new_python_F_calls":0,"year_credit":0}
    write("verdict.json",verdict)
    try:
        for i,x in enumerate(cases,1):
            tag=f"case-{i:02d}"
            row={"c":x["c"],"t":x["t"],"expected":x["expected"],"basis":x["basis"],"status":"STARTED"}
            results.append(row);write("verdict.json",verdict)
            start=time.monotonic()
            with (E/(tag+".stdout")).open("wb") as out,(E/(tag+".stderr")).open("wb") as err:
                proc=subprocess.Popen(["/usr/bin/time","-v","-o",str(E/(tag+".time")),str(binary),str(x["t"])],
                    stdout=out,stderr=err,preexec_fn=limits,start_new_session=True)
                try: code=proc.wait(timeout=180)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid,signal.SIGKILL);proc.wait();code=124
            row.update(exit_code=code,elapsed_seconds=round(time.monotonic()-start,4))
            raw=(E/(tag+".stdout")).read_bytes();err=(E/(tag+".stderr")).read_bytes()
            row.update(stdout_sha256=hashlib.sha256(raw).hexdigest(),stderr_sha256=hashlib.sha256(err).hexdigest(),stderr_bytes=len(err))
            need(code==0 and not err and len(raw)<=16384,"native process failure at "+tag)
            line=raw.decode("ascii").strip()
            need(re.fullmatch(r"ISSUE29_V191_CORRECTED_ADA(?:\s+-?\d+){7}",line) is not None,"invalid native record")
            c,t,*fields=map(int,line.split()[1:])
            row["actual"]=fields
            need((c,t)==(x["c"],x["t"]),"native returned wrong input")
            need(fields==x["expected"],"numerical mismatch at "+tag)
            row["status"]="MATCH";records.append(line);write("verdict.json",verdict)
            (E/"matched-records.txt").write_text("\n".join(records)+"\n")
        need(validator.validate(panel,records)["matched"]==9,"panel validator mismatch")
        verdict["status"]="PASS_NINE_CORRECTED_ADA_DATES_NOT_YEAR"
    except BaseException as ex:
        if results:results[-1]["status"]="FAILED"
        verdict["status"]="FAIL_STOP_FIRST";verdict["error"]=str(ex)
        raise
    finally:
        verdict["attempted"]=len(results);verdict["matched"]=sum(r["status"]=="MATCH" for r in results)
        write("verdict.json",verdict)
if __name__=="__main__":
    E.mkdir(exist_ok=True)
    if len(__import__("sys").argv)==2 and __import__("sys").argv[1]=="preflight":preflight()
    else:execute()
