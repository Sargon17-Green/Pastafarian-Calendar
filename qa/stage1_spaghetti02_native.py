from __future__ import print_function
import json,os,subprocess,tempfile,hashlib

PROD="src/interleaved_work_counts.b98"
PARENT="qa/spaghetti01_interleaved_work_counts_candidate.b98"
CHILD="qa/spaghetti02_cascade_candidate.b98"
CMD=["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
VALID=["1 15055672 1 15055670","0 0 0 0","0 1 0 2","1 987654321 0 123456789"]
INVALID=["2 10 0 10","-0 1 0 1"]
MUTATIONS=[("first_p",20,3,"z"),("first_g",23,3,"z"),("second_p",72,3,"z"),("second_g",79,3,"z")]
def run(path,inp,limit=50):
    cmd=["timeout","--kill-after=2s",str(limit)+"s"]+CMD+[path]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(inp+"\n")
    return (p.returncode,out.split(),err[-250:])
def git_blob(data):
    return hashlib.sha1("blob "+str(len(data))+"\0"+data).hexdigest()
with open(PARENT,"rb") as f:parent=f.read()
with open(CHILD,"rb") as f:child=f.read()
assert git_blob(parent)=="948cb9332332f6abf35274ecc4be69bbc8c79115"
assert git_blob(child)=="471e45cfec818d432cbb8e810204a865f8f04a97"
pr=parent.splitlines(); cr=child.splitlines(); crraw=child.splitlines(True)
assert len(pr)==len(cr)==2015
assert (cr[2][59:61],cr[3][63:87],cr[4][63])==("v>","e4gf4*3+4pf4*3+4g4c*-:1x"," ")
assert cr[4][14]==" " and cr[4][86]=="<" and cr[4][60]=="^"
changes=[]
for y,(a,b) in enumerate(zip(pr,cr)):
    for x in range(max(len(a),len(b))):
        ca=a[x] if x<len(a) else " "
        cb=b[x] if x<len(b) else " "
        if ca!=cb:changes.append((x,y,ca,cb))
assert len(changes)==29,repr(changes)
mutants=[]
for name,x,y,replacement in MUTATIONS:
    assert cr[y][x] in "pg",("wrong mutator",name,cr[y][x])
    cloned=list(crraw)
    row=bytearray(cloned[y])
    row[x]=ord(replacement)
    cloned[y]=bytes(row)
    fd,path=tempfile.mkstemp(prefix="bf98_spaghetti02_"+name+"_",suffix=".b98")
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
        print("NATIVE_SPAGHETTI02_SAMPLE",inp,negatives,flush=True)
    assert all(count>=2 for count in causal.values()),"INSUFFICIENT_NATIVE_CAUSALITY "+repr(causal)
    print("NATIVE_SPAGHETTI02_CASCADE_PASS",causal,flush=True)
finally:
    with open("/work/spaghetti02_native_receipt.json","w") as f:
        json.dump({"schema":"spaghetti02-cascade-native-v1",
                   "parent_blob":"948cb9332332f6abf35274ecc4be69bbc8c79115",
                   "child_blob":"471e45cfec818d432cbb8e810204a865f8f04a97",
                   "production_modified":False,"stage1_complete":False,
                   "candidate_promoted":False,
                   "changed_cells":len(changes),
                   "observations":evidence,"causal_counts":causal},f,indent=2)
    for name,path in mutants:os.unlink(path)
