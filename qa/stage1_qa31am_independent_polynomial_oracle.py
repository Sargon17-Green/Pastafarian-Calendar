#!/usr/bin/env python3
"""Independent polynomial/source oracle for QA31AM; no forward-module imports."""
import argparse,copy,hashlib,json,math
from pathlib import Path
SHA="560d6aa5807a7f766213a33835cce85eab0fa40c"
N=8
FIXED={(399,195),(1030,385),(860,846),(405,860),(195,1036),(480,1070),
       (876,1240),(986,1334),(1335,1354),(1430,1540),(670,1598)}
POSSIBLE={(860,99),(96,480),(1332,480),(384,575),(948,860),
          (195,958),(575,959),(860,1142),(292,1430),(577,1430)}
NONLINEAR={(96,480),(575,959)}
DIRS={"E":(1,0,">"),"W":(-1,0,"<"),"S":(0,1,"v"),"N":(0,-1,"^")}
def need(v,msg):
    if not v:raise AssertionError(msg)
def cell(rows,x,y):
    return chr(rows[y][x]) if 0<=y<len(rows) and 0<=x<len(rows[y]) else None
def source(raw):
    need(hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==SHA,"unpinned original source")
    rows=raw.splitlines()
    need(len(rows)==2015 and rows[49]==b"","original source shape")
    sites=[(x,y) for y,line in enumerate(rows) for x,c in enumerate(line) if c==112]
    need(len(sites)==57 and sum(y<45 for x,y in sites)==13,"original literal p list")
    return rows,{s for s in sites if s[1]>=45}
def const(num):return {():num} if num else {}
def var(i):return {(i,):1}
def sum_poly(a,b,sgn=1):
    out=dict(a)
    for k,v in b.items():out[k]=out.get(k,0)+sgn*v
    return {k:v for k,v in out.items() if v}
def mul_poly(a,b):
    out={}
    for aa,va in a.items():
        for bb,vb in b.items():
            key=tuple(sorted(aa+bb));out[key]=out.get(key,0)+va*vb
    return {k:v for k,v in out.items() if v}
def target_polynomials(seq):
    st=[var(i) for i in range(N)]
    def pop():return st.pop() if st else {}
    for op in seq[1:-1]:
        if op in "0123456789abcdef":st.append(const(int(op,16)))
        elif op in "+-*":
            b,a=pop(),pop()
            st.append(sum_poly(a,b) if op=="+" else sum_poly(a,b,-1) if op=="-" else mul_poly(a,b))
        elif op in "/%":
            b,a=pop(),pop()
            need(all(not k for k in a) and all(not k for k in b),"dynamic division unmodeled")
            aa,bb=a.get((),0),b.get((),0);q=math.trunc(aa/bb) if bb else 0
            st.append(const(q if op=="/" else aa-q*bb if bb else 0))
        elif op==chr(96):
            b,a=pop(),pop();need(all(not k for k in a) and all(not k for k in b),"dynamic compare unmodeled")
            st.append(const(int(a.get((),0)>b.get((),0))))
        elif op=="!":
            a=pop();need(all(not k for k in a),"dynamic not unmodeled")
            st.append(const(int(a.get((),0)==0)))
        elif op==":":a=pop();st.extend((a,a))
        elif op=="\\":a,b=pop(),pop();st.extend((a,b))
        elif op=="$":pop()
        elif op==" ":pass
        else:raise AssertionError("unsupported ray opcode")
    y,x,v=pop(),pop(),pop()
    return x,y,v
def calculate(poly,seed):
    total=0
    for mon,val in poly.items():
        t=val
        for ix in mon:t*=seed[ix]
        total+=t
    return total
def source_ray(rows,entry):
    site=entry["site"];r=entry["ray"]
    need(r["direction"] in DIRS,"bad ray direction")
    dx,dy,arrow=DIRS[r["direction"]]
    ax,ay=r["anchor"];steps=r["steps"]
    need(isinstance(steps,int) and 1<=steps<=60 and [ax+steps*dx,ay+steps*dy]==site,"ray endpoint")
    reconstructed="".join(cell(rows,ax+i*dx,ay+i*dy) for i in range(steps+1))
    need(reconstructed==r["ops"] and reconstructed[0]==arrow and reconstructed[-1]=="p","ray not in pinned original source")
    need(all(c in "0123456789abcdef+-*/%!:$\\ "+chr(96) for c in reconstructed[1:-1]),"non-pure ray")
    return reconstructed
def compound_check(obj,rows):
    true="".join(cell(rows,x,575) for x in range(385,368,-1))
    need(true==obj["source_sequence"]=="<p71a*6+a*9+a*2+p","compound source changed")
    need(obj["p_sites"]==[[384,575],[369,575]] and obj["second_put_xy"]==[7,1692],"compound wrong targets")
    need(obj["arbitrary_first_put"]=="UNKNOWN" and obj["other_ingress"]=="UNKNOWN","compound global overclaim")
    samples=obj["benign_first_put_examples"]
    need(len(samples)==2,"compound sample count")
    for e in samples:
        st=list(e["incoming_stack_bottom_to_top"]);w=[]
        def pop():return st.pop() if st else 0
        for k,op in enumerate(true[1:],1):
            if op in "0123456789abcdef":st.append(int(op,16))
            elif op in "+-*":
                b,a=pop(),pop();st.append(a+b if op=="+" else a-b if op=="-" else a*b)
            elif op=="p":
                y,x,v=pop(),pop(),pop();w.append([385-k,575,x,y,v])
            else:raise AssertionError("compound unhandled")
        need(w==e["writes"] and w[0][2:4] in ([1500,1800],[1600,1850]) and w[1][2:4]==[7,1692],"compound puts incorrect")
def ingress_check(arr,rows):
    need(len(arr)==4,"missing ingress sites")
    for ent,y in zip(arr,(20,23,29,32)):
        need(ent["entry"]==[10,y] and cell(rows,10,y)==">","entry opcode mismatch")
        for name,dx,dy in (("north",0,-1),("south",0,1),("west",-1,0)):
            got=ent["directions"][name];n=0;stop=None
            for k in range(1,13):
                xx,yy=10+dx*k,y+dy*k;op=cell(rows,xx,yy)
                if op==" ":n+=1
                else:stop={"distance":k,"cell":[xx,yy],"opcode":op};break
            need(got=={"empty_prefix":n,"first_nonspace_within_12":stop,"physical_witness":None},"source-local ingress drift")
        need(ent["natural_input_witness"] is None,"fabricated physical witness")
def verify(d,rows,sites):
    need(d["schema"]=="qa31am-conditional-counter-addresses-v1" and d["source_git_blob"]==SHA and d["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ","identity")
    need(d["outer_source_p_glyphs"]==44 and d["previous_static_exclusions"]==11 and d["formerly_unknown_y_corridors"]==32,"coverage")
    arr=d["rays"];need(len(arr)==32,"32 rays expected")
    wanted=sites-FIXED-{(369,575)}
    need(set(tuple(x["site"]) for x in arr)==wanted and len(wanted)==32,"outer source ray set incomplete")
    excluded=possible=nonlinear=witnesses=0
    for a in arr:
        site=tuple(a["site"]);ops=source_ray(rows,a)
        xx,yy,val=target_polynomials(ops)
        degree=max((len(m) for m in yy),default=0)
        if degree>=2:
            need(site in NONLINEAR and a["kind"]=="nonlinear","unexpected nonlinear expression")
            nonlinear+=1;can=True
        else:
            need(a["kind"]=="affine","missing affine classification")
            constval=yy.get((),0);coeffs=[yy.get((i,),0) for i in range(N)]
            gcd=math.gcd(*map(abs,coeffs))
            need(gcd>0 and a["constant"]==constval and a["coefficients"]==coeffs and a["gcd"]==gcd,"independent polynomial coefficient mismatch")
            residue=(49-constval)%gcd
            need(a["mod_residue"]==residue,"wrong modular obstruction")
            can=(residue==0)
            if can:possible+=1
            else:excluded+=1
        need((site in POSSIBLE)==can and a["conditional_y49_possible"] is can,"wrong conditional counter feasibility")
        if can:
            w=a["hypothetical_counter_address_witnesses"];need(len(w)==2,"missing both conditional counter witnesses")
            for entry,target in zip(w,(1,3)):
                seed=entry["incoming_stack_bottom_to_top"];need(len(seed)==N and all(isinstance(t,int) for t in seed),"bad seed")
                result=[calculate(xx,seed),calculate(yy,seed),calculate(val,seed)]
                need(result==entry["put"] and result[:2]==[target,49],"hypothetical put not reconstructed")
                witnesses+=1
        else:need("hypothetical_counter_address_witnesses" not in a,"false impossible witness")
    need((excluded,possible,nonlinear,witnesses)==(22,8,2,20),"QA31AM independent population")
    for key,value in (("new_affine_congruence_exclusions",22),("affine_feasible_y49",8),("nonlinear_feasible_y49",2),("hypothetical_counter_address_witness_count",20)):
        need(d[key]==value,"reported aggregate mismatch "+key)
    compound_check(d["compound_two_put_path"],rows)
    ingress_check(d["alternate_entry_geometry"],rows)
    need(d["unrestricted_physical_write_targets"]=="UNKNOWN" and d["real_natural_input_witness"] is None and d["native_runs"]==0 and d["stage1_pass"] is False,"false physical or Stage1 claim")
    return witnesses
def hostile(d,rows,sites):
    funcs=[
      lambda a:a.__setitem__("source_git_blob","0"),
      lambda a:a.__setitem__("new_affine_congruence_exclusions",21),
      lambda a:a["rays"].pop(),
      lambda a:a["rays"][0]["ray"].__setitem__("ops","^p"),
      lambda a:a["rays"][0].__setitem__("site",[1,1]),
      lambda a:a["rays"][0].__setitem__("conditional_y49_possible",False),
      lambda a:a["rays"][0]["hypothetical_counter_address_witnesses"][0]["incoming_stack_bottom_to_top"].__setitem__(7,0),
      lambda a:a["rays"][1].__setitem__("gcd",1),
      lambda a:a["compound_two_put_path"].__setitem__("second_put_xy",[1,49]),
      lambda a:a["compound_two_put_path"]["benign_first_put_examples"][0]["writes"][1].__setitem__(3,49),
      lambda a:a["alternate_entry_geometry"][0].__setitem__("entry",[9,20]),
      lambda a:a["alternate_entry_geometry"][0]["directions"]["west"].__setitem__("physical_witness","YES"),
      lambda a:a.__setitem__("real_natural_input_witness","invented"),
      lambda a:a.__setitem__("native_runs",1),
      lambda a:a.__setitem__("stage1_pass",True)
    ]
    rejected=0
    for i,fun in enumerate(funcs):
        bad=copy.deepcopy(d);fun(bad)
        try:verify(bad,rows,sites)
        except (AssertionError,KeyError,IndexError,TypeError,ValueError):rejected+=1
        else:raise AssertionError("hostile mutated report accepted "+str(i))
    need(rejected==15,"hostile total")
    return rejected
def main():
    a=argparse.ArgumentParser()
    for key in ("source","forward","out"):a.add_argument("--"+key,required=True)
    o=a.parse_args();rows,sites=source(Path(o.source).read_bytes())
    f=json.loads(Path(o.forward).read_text(encoding="utf-8"))
    n=verify(f,rows,sites);h=hostile(f,rows,sites)
    out={"schema":"qa31am-independent-polynomial-v1","source_git_blob":SHA,
         "conditional_rays_verified":32,"affine_excluded":22,"possible_rays":10,
         "conditional_counter_address_witnesses_verified":n,"compound_second_p_target":[7,1692],
         "mutated_reports_rejected":h,"native_runs":0,"stage1_pass":False}
    Path(o.out).write_text(json.dumps(out,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("QA31AM_INDEPENDENT_POLYNOMIAL_PASS 32_RAYS 22_MODULAR_EXCLUSIONS 20_CONDITIONAL_WITNESSES 15_HOSTILE_REJECTED")
if __name__=="__main__":main()
