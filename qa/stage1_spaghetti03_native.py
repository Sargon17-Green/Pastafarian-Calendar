from __future__ import print_function
import json,os,subprocess,tempfile,hashlib

PROD="src/interleaved_work_counts.b98"
PARENT="qa/spaghetti03_cascade_candidate.b98"
CHILD="qa/spaghetti03_arithmetic_braid_candidate.b98"
CMD=["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
VALID=["1 15055672 1 15055670","0 0 0 0","0 1 0 2","1 987654321 0 123456789"]
INVALID=["2 10 0 10","-0 1 0 1"]
MUTATIONS=[("first_p",20,3,"z"),("first_g",23,3,"z"),("second_p",72,3,"z"),("second_g",79,3,"z"),("third_p",130,3,"z"),("third_g",137,3,"z"),("braid_plus",121,3,"-")]
def run(path,inp,limit=50):
    cmd=["timeout","--kill-after=2s",str(limit)+"s"]+CMD+[path]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(inp+"\n")
    return (p.returncode,out.split(),err[-250:])
def git_blob(data):
    return hashlib.sha1("blob "+str(len(data))+"\0"+data).hexdigest()
with open(PARENT,"rb") as f:parent=f.read()
with open(CHILD,"rb") as f:child=f.read()
assert git_blob(parent)=="471e45cfec818d432cbb8e810204a865f8f04a97"
assert git_blob(child)=="2baa1795a9a5802f58ecbd87ac8f138a1e811066"
pr=parent.splitlines(); cr=child.splitlines(); crraw=child.splitlines(True)
assert len(pr)==len(cr)==2015
assert (cr[2][107:109],cr[3][111:145],cr[4][111])==("v>","e4gf4*3+4g+2/7f*6+4p7f*6+4g4c*-:1x"," ")
assert cr[4][14]==" " and cr[4][63]==" " and cr[4][144]=="<" and cr[4][108]=="^"
changes=[]
for y,(a,b) in enumerate(zip(pr,cr)):
    for x in range(max(len(a),len(b))):
        ca=a[x] if x<len(a) else " "
        cb=b[x] if x<len(b) else " "
        if ca!=cb:changes.append((x,y,ca,cb))
assert len(changes)==39,repr(changes)
mutants=[]
for name,x,y,replacement in MUTATIONS:
    assert cr[y][x] in "pg+",("wrong mutator",name,cr[y][x])
    cloned=list(crraw)
    row=bytearray(cloned[y])
    row[x]=ord(replacement)
    cloned[y]=bytes(row)
    fd,path=tempfile.mkstemp(prefix="bf98_spaghetti03_"+name+"_",suffix=".b98")
    f=os.fdopen(fd,"wb");f.write("".join(cloned));f.close()
    mutants.append((name,path))
evidence=[]
causal=dict((name,0) for name,x,y,r in MUTATIONS)
try:
    for inp in VALID+INVALID:
        prodrc,prod,prod_err=run(PROD,inp)
        parrc,par,par_err=run(PARENT,inp)
        rc,out,err=run(CHILD,inp)
        if prodrc or parrc or rc or not(prod==par==out):
            raise AssertionError("NATIVE_PARITY_FAIL %r %r %r %r"%(inp,prod,par,out))
        if inp in VALID:
            sc,mc,st,mt=inp.split()
            r1,a,e1=run("reference/work_counts.b98",inp)
            r2,b,e2=run("reference/save.b98",sc+" "+mc)
            r3,c,e3=run("reference/save.b98",st+" "+mt)
            if r1 or r2 or r3 or out!=a+b+c:
                raise AssertionError("ORACLE_FAIL %r got=%r reference=%r"%(inp,out,a+b+c))
        negatives={}
        if inp in VALID:
            for name,path in mutants:
                mrc,mout,merr=run(path,inp,8)
                changed=bool(mrc or mout!=out)
                causal[name]+=int(changed)
                negatives[name]={"changed_final_or_termination":changed,"rc":mrc}
        evidence.append({"input":inp,"valid":inp in VALID,"output":out,"negative_controls":negatives})
        print("NATIVE_SPAGHETTI03_SAMPLE",inp,negatives)
    assert all(count>=2 for count in causal.values()),"INSUFFICIENT_NATIVE_CAUSALITY "+repr(causal)
    print("NATIVE_SPAGHETTI03_ARITHMETIC_BRAID_PASS",causal)
finally:
    with open("/work/spaghetti03_native_receipt.json","w") as f:
        json.dump({"schema":"spaghetti03-arithmetic-braid-native-v1",
                   "parent_blob":"471e45cfec818d432cbb8e810204a865f8f04a97",
                   "child_blob":"2baa1795a9a5802f58ecbd87ac8f138a1e811066",
                   "production_modified":False,"stage1_complete":False,
                   "candidate_promoted":False,
                   "changed_cells":len(changes),
                   "observations":evidence,"causal_counts":causal},f,indent=2)
    for name,path in mutants:os.unlink(path)
