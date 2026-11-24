#!/usr/bin/env python3
"""Fresh six-pair comparison, corrected Ada and pinned original Python only."""
import hashlib,importlib.util,json,os,re,resource,signal,subprocess,sys,time
from pathlib import Path
BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
PYREF="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
BRANCH="qa/issue29-cross-year-changed-c-v193"
MSG="qa(issue29-v193): six fresh corrected Ada vs pinned Python boundary and changed-c cases"
PANEL=Path("qa/issue29/v193_cases.json")
E=Path("evidence")
REF=Path("original-python/tests/normative_reference.py").resolve()
TARGETS=[(-15055671,-15057703),(-15055671,-15053459),(-15055671,-15053458),(-15055672,-15055671),(-15055670,-15055671),(-15055629,-15055629)]
PATHS={".github/workflows/issue29-v193-cross-year.yml","issue29_v193_diff.gpr","tests/issue29_v193_diff.adb","qa/issue29/v193_cases.json","qa/issue29/v193_diff.py"}
PINS={"src/normative_oracle.adb":"0be8f8ab4ddef26d34963d5567707a511ebda50b",
"src/canonical_full_weave_gmp_v164.ads":"0b68edf7eddbc33869358bcfcc21e32465fc591e",
"src/canonical_full_weave_gmp_v164.adb":"845bd8905943a54e63d6aba0334404a5051fe666",
"src/canonical_wide_rank_gmp_v164.ads":"14b94e81534e98cfdb07be3824076bd7082385ea",
"src/canonical_wide_rank_gmp_v164.adb":"52b8814c2ab1924cdebafe893a65d97cd3ccfa61"}
def need(ok,msg):
    if not ok:raise RuntimeError(msg)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def git(*a):return subprocess.check_output(["git",*a],stderr=subprocess.DEVNULL).decode().strip()
def save(n,v): (E/n).write_text(json.dumps(v,indent=2,sort_keys=True)+"\n")
def cases():
    x=json.loads(PANEL.read_text())["cases"]
    need([(r["c"],r["t"]) for r in x]==TARGETS,"fixture drift")
    return x
def preflight():
    need(os.environ.get("GITHUB_ACTIONS")=="true" and os.environ.get("GITHUB_RUN_ATTEMPT")=="1","one CI attempt")
    need(os.environ.get("GITHUB_EVENT_NAME")=="push" and os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"wrong event/ref")
    need(git("rev-parse","HEAD")==os.environ.get("GITHUB_SHA") and git("rev-parse","HEAD^")==BASE,"wrong parent")
    need(json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())["head_commit"]["message"]==MSG,"wrong activation")
    need(set(git("diff","--name-only",BASE+"...HEAD").splitlines())==PATHS,"unexpected changes")
    for p,b in PINS.items():need(git("rev-parse","HEAD:"+p)==b,"source drift "+p)
    need(git("-C","original-python","rev-parse","HEAD")==PYREF,"reference commit")
    need(git("-C","original-python","rev-parse","HEAD:tests/normative_reference.py")=="d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53","reference blob")
    need(sha(REF)=="75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378","reference bytes")
    need(Path(".github/workflows/canonical-names-lock.yml").read_text().count("    if: "+"$"+"{{ false }}")==42,"legacy gates")
    cases()
    save("preflight.json",{"head":git("rev-parse","HEAD"),"base":BASE,"python_source":PYREF,"python_sha256":sha(REF),"pins":PINS,"panel_sha256":sha(PANEL),"targets":TARGETS,"legacy_gates":42})
def python_worker(c,t):
    need((c,t) in TARGETS,"outside whitelist")
    need(sha(REF)=="75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378","reference drift")
    spec=importlib.util.spec_from_file_location("v193_reference",REF)
    mod=importlib.util.module_from_spec(spec);sys.modules[spec.name]=mod;spec.loader.exec_module(mod)
    result=mod.NormativeCalendar().calendar_date_ids(c,t)
    print("ISSUE29_V193",c,t,result.year_number,result.cutlet_name_index,result.day_in_cutlet,result.month_name_index,result.day_in_month)
def limits():
    resource.setrlimit(resource.RLIMIT_AS,(1073741824,1073741824))
    resource.setrlimit(resource.RLIMIT_CPU,(180,180))
    resource.setrlimit(resource.RLIMIT_FSIZE,(2097152,2097152))
def invoke(tag,cmd,c,t,row):
    start=time.monotonic()
    with (E/(tag+".stdout")).open("wb") as out,(E/(tag+".stderr")).open("wb") as err:
        p=subprocess.Popen(["/usr/bin/time","-v","-o",str(E/(tag+".time")),*cmd],stdout=out,stderr=err,preexec_fn=limits,start_new_session=True)
        try:code=p.wait(timeout=180)
        except subprocess.TimeoutExpired:
            os.killpg(p.pid,signal.SIGKILL);p.wait();code=124
    raw=(E/(tag+".stdout")).read_bytes();err=(E/(tag+".stderr")).read_bytes()
    row.update(exit_code=code,elapsed_seconds=round(time.monotonic()-start,4),stdout_sha256=hashlib.sha256(raw).hexdigest(),stderr_sha256=hashlib.sha256(err).hexdigest(),stderr_bytes=len(err))
    need(code==0 and not err and len(raw)<=16384,"process failure "+tag)
    line=raw.decode("ascii").strip()
    need(re.fullmatch(r"ISSUE29_V193(?:\s+-?\d+){7}",line) is not None,"malformed result "+tag)
    x,y,*fields=map(int,line.split()[1:]);need((x,y)==(c,t),"wrong input")
    need(1<=fields[1]<=17 and 1<=fields[2]<=5778 and 1<=fields[3]<=47 and 1<=fields[4]<=123,"field range")
    row["fields"]=fields
    return fields
def run():
    preflight()
    binary=Path("bin_v193/issue29_v193_diff").resolve()
    need(binary.is_file(),"binary absent")
    verdict={"schema":"ISSUE29_V193_NATIVE_CROSS_YEAR_CHANGED_C/1","head":git("rev-parse","HEAD"),"base":BASE,"run_id":os.environ["GITHUB_RUN_ID"],"binary_sha256":sha(binary),"python_commit":PYREF,"cases":[],"status":"INCOMPLETE","historical_ada_calls":0,"year_credit":0}
    save("verdict.json",verdict)
    try:
        for i,x in enumerate(cases(),1):
            c,t=x["c"],x["t"];tag=f"case-{i:02d}"
            row={**x,"status":"STARTED","python":{},"ada":{}}
            verdict["cases"].append(row);save("verdict.json",verdict)
            py=invoke(tag+"-python",[sys.executable,"-B",__file__,"worker",str(c),str(t)],c,t,row["python"])
            save("verdict.json",verdict)
            if "year" in x:need(py[0]==x["year"],"reference boundary mismatch")
            if i==3:need(py[2]==1 and py[4]==1,"first day projection")
            ad=invoke(tag+"-ada",[str(binary),str(c),str(t)],c,t,row["ada"])
            need(py==ad,"first numerical difference "+tag+": "+repr([py,ad]))
            row["status"]="MATCH";save("verdict.json",verdict)
        verdict["status"]="PASS_SIX_FRESH_PAIRS_NOT_YEAR"
    except BaseException as ex:
        if verdict["cases"]:verdict["cases"][-1]["status"]="FAILED"
        verdict["status"]="FAIL_STOP_FIRST";verdict["error"]=str(ex);raise
    finally:
        verdict["matched"]=sum(x["status"]=="MATCH" for x in verdict["cases"])
        save("verdict.json",verdict)
if __name__=="__main__":
    if len(sys.argv)==4 and sys.argv[1]=="worker":python_worker(int(sys.argv[2]),int(sys.argv[3]))
    else:
        E.mkdir(exist_ok=True)
        if sys.argv[1:]==["preflight"]:preflight()
        else:run()
