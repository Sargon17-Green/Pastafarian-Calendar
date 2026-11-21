#!/usr/bin/env python3
"""QA31AM finite original-source counter-address arithmetic; no global/Native claim."""
import argparse,hashlib,json,math
from pathlib import Path
SHA="560d6aa5807a7f766213a33835cce85eab0fa40c"
D=(("E",1,0,">"),("W",-1,0,"<"),("S",0,1,"v"),("N",0,-1,"^"))
PURE=set("0123456789abcdef+-*/%!:$\\ "+chr(96))
N=8
def need(v,msg):
    if not v:raise AssertionError(msg)
def cell(rows,x,y):
    return chr(rows[y][x]) if 0<=y<len(rows) and 0<=x<len(rows[y]) else None
def original(raw):
    need(hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==SHA,"original source SHA mismatch")
    rows=raw.splitlines()
    need(len(rows)==2015 and rows[49]==b"","original source shape drift")
    sites=[(x,y) for y,row in enumerate(rows) for x,c in enumerate(row) if c==112]
    need(len(sites)==57 and sum(y<45 for x,y in sites)==13,"p glyph inventory drift")
    return rows,[site for site in sites if site[1]>=45]
def ray(rows,x,y):
    for name,dx,dy,arrow in D:
        for dist in range(1,61):
            ax,ay=x-dist*dx,y-dist*dy
            first=cell(rows,ax,ay)
            if first is None:break
            if first==arrow:
                seq="".join(cell(rows,ax+i*dx,ay+i*dy) for i in range(dist+1))
                if all(ch in PURE for ch in seq[1:-1]):
                    return {"direction":name,"anchor":[ax,ay],"steps":dist,"ops":seq}
                break
    return None
def const(k):return (k,(0,)*N)
def var(i):return (0,tuple(int(i==j) for j in range(N)))
def add(a,b,sgn=1):
    if a is None or b is None:return None
    return (a[0]+sgn*b[0],tuple(v+sgn*w for v,w in zip(a[1],b[1])))
def mul(a,b):
    if a is None or b is None or (any(a[1]) and any(b[1])):return None
    if not any(a[1]):return (a[0]*b[0],tuple(a[0]*i for i in b[1]))
    return (b[0]*a[0],tuple(b[0]*i for i in a[1]))
def symbolic(ops):
    st=[var(i) for i in range(N)]
    def pop():return st.pop() if st else const(0)
    for ch in ops[1:-1]:
        if ch in "0123456789abcdef":st.append(const(int(ch,16)))
        elif ch in "+-*"+chr(96):
            b,a=pop(),pop()
            if ch=="+":st.append(add(a,b))
            elif ch=="-":st.append(add(a,b,-1))
            elif ch=="*":st.append(mul(a,b))
            elif a is not None and b is not None and not any(a[1]) and not any(b[1]):st.append(const(int(a[0]>b[0])))
            else:st.append(None)
        elif ch in "/%":
            b,a=pop(),pop()
            if a is not None and b is not None and not any(a[1]) and not any(b[1]) and b[0]!=0:
                q=math.trunc(a[0]/b[0]);st.append(const(q if ch=="/" else a[0]-q*b[0]))
            else:st.append(None)
        elif ch=="!":
            a=pop();st.append(const(int(a[0]==0)) if a is not None and not any(a[1]) else None)
        elif ch==":":a=pop();st.extend((a,a))
        elif ch=="\\":a,b=pop(),pop();st.extend((a,b))
        elif ch=="$":pop()
        elif ch==" ":pass
        else:raise AssertionError("nonpure ray")
    y,x,v=pop(),pop(),pop()
    return y,x,v
def concrete(ops,initial):
    st=list(initial)
    def pop():return st.pop() if st else 0
    for ch in ops[1:-1]:
        if ch in "0123456789abcdef":st.append(int(ch,16))
        elif ch in "+-*"+chr(96):
            b,a=pop(),pop()
            st.append(a+b if ch=="+" else a-b if ch=="-" else a*b if ch=="*" else int(a>b))
        elif ch in "/%":
            b,a=pop(),pop();q=math.trunc(a/b) if b else 0
            st.append(q if ch=="/" else a-q*b if b else 0)
        elif ch=="!":st.append(int(pop()==0))
        elif ch==":":a=pop();st.extend((a,a))
        elif ch=="\\":a,b=pop(),pop();st.extend((a,b))
        elif ch=="$":pop()
        elif ch==" ":pass
        else:raise AssertionError("unexpected ray op")
    y,x,v=pop(),pop(),pop()
    return [x,y,v]
def witness(ops,y,x,site,desired_x):
    initial=[0]*N;initial[4]=201
    if y is None:
        used={6,7}
        if site==(96,480):initial[7],initial[6]=7,7
        elif site==(575,959):initial[7],initial[6]=4,11
        else:raise AssertionError("unpinned nonlinear site")
    else:
        used={i for i,k in enumerate(y[1]) if k}
        candidates=[(i,k) for i,k in enumerate(y[1]) if k and (49-y[0])%k==0]
        need(bool(candidates),"no linear witness")
        i,k=candidates[-1];initial[i]=(49-y[0])//k
    need(x is not None,"nonlinear x not modeled")
    diff=desired_x-x[0]-sum(k*initial[i] for i,k in enumerate(x[1]))
    choices=[(i,k) for i,k in enumerate(x[1]) if k and i not in used and diff%k==0]
    need(bool(choices),"no independent x seed")
    i,k=choices[-1];initial[i]+=diff//k
    output=concrete(ops,initial)
    need(output[:2]==[desired_x,49],"candidate address not realized")
    return {"incoming_stack_bottom_to_top":initial,"put":[desired_x,49,output[2]]}
def compound(rows):
    seq="".join(cell(rows,x,575) for x in range(385,368,-1))
    need(seq=="<p71a*6+a*9+a*2+p","compound source changed")
    examples=[]
    for xx,yy in ((1500,1800),(1600,1850)):
        st=[0]*12;st[-1]=yy;st[-2]=xx;st[-3]=227;st[-4]=32
        stack=list(st);writes=[]
        def pop():return stack.pop() if stack else 0
        for ix,op in enumerate(seq[1:],1):
            if op in "0123456789abcdef":stack.append(int(op,16))
            elif op in "+-*":
                b,a=pop(),pop();stack.append(a+b if op=="+" else a-b if op=="-" else a*b)
            elif op=="p":
                y,x,v=pop(),pop(),pop();writes.append([385-ix,575,x,y,v])
            else:raise AssertionError("compound unmodeled op")
        need(writes[0][:4]==[384,575,xx,yy] and writes[1][:4]==[369,575,7,1692],"compound target drift")
        examples.append({"incoming_stack_bottom_to_top":st,"writes":writes})
    return {"source_sequence":seq,"p_sites":[[384,575],[369,575]],"second_put_xy":[7,1692],"benign_first_put_examples":examples,"arbitrary_first_put":"UNKNOWN","other_ingress":"UNKNOWN"}
def ingress(rows):
    result=[]
    for y in (20,23,29,32):
        need(cell(rows,10,y)==">","entry byte drift")
        dirs={}
        for name,dx,dy in (("north",0,-1),("south",0,1),("west",-1,0)):
            blanks=0;stop=None
            for dist in range(1,13):
                x1,y1=10+dx*dist,y+dy*dist;op=cell(rows,x1,y1)
                if op==" ":blanks+=1
                else:stop={"distance":dist,"cell":[x1,y1],"opcode":op};break
            dirs[name]={"empty_prefix":blanks,"first_nonspace_within_12":stop,"physical_witness":None}
        result.append({"entry":[10,y],"directions":dirs,"natural_input_witness":None})
    return result
def main():
    a=argparse.ArgumentParser();a.add_argument("--source",required=True);a.add_argument("--out",required=True);z=a.parse_args()
    rows,sites=original(Path(z.source).read_bytes())
    items=[];fixed=excluded=possible=nonlinear=0
    for site in sites:
        seg=ray(rows,*site)
        if seg is None:
            need(site==(369,575),"unmodeled unanchored source p");continue
        y,x,v=symbolic(seg["ops"])
        if y is not None and not any(y[1]):
            need(y[0]!=49,"fixed original counter y49 unexpected")
            fixed+=1;continue
        item={"site":list(site),"ray":seg,"stack_seed_length":N}
        if y is None:
            nonlinear+=1;item.update({"kind":"nonlinear","conditional_y49_possible":True})
        else:
            g=math.gcd(*map(abs,y[1]));need(g>0,"missing affine coefficient")
            rem=(49-y[0])%g;ok=rem==0
            if ok:possible+=1
            else:excluded+=1
            item.update({"kind":"affine","constant":y[0],"coefficients":list(y[1]),"gcd":g,"mod_residue":rem,"conditional_y49_possible":ok})
        if item["conditional_y49_possible"]:
            item["hypothetical_counter_address_witnesses"]=[witness(seg["ops"],y,x,site,q) for q in (1,3)]
        items.append(item)
    need((len(sites),fixed,excluded,possible,nonlinear,len(items))==(44,11,22,8,2,32),"original source partition changed")
    obj={"schema":"qa31am-conditional-counter-addresses-v1","project_id":"PC-BRANCH-BEFUNGE98-KYRGYZ","source_git_blob":SHA,
         "outer_source_p_glyphs":44,"previous_static_exclusions":11,"formerly_unknown_y_corridors":32,
         "new_affine_congruence_exclusions":excluded,"affine_feasible_y49":possible,"nonlinear_feasible_y49":nonlinear,
         "hypothetical_counter_address_witness_count":20,"rays":items,"compound_two_put_path":compound(rows),
         "alternate_entry_geometry":ingress(rows),"unrestricted_physical_write_targets":"UNKNOWN",
         "real_natural_input_witness":None,"native_runs":0,"stage1_pass":False}
    Path(z.out).write_text(json.dumps(obj,sort_keys=True,ensure_ascii=False,separators=(",",":"))+"\n",encoding="utf-8")
    print("QA31AM_SOURCE_PASS 32_RAYS 22_AFFINE_CONGRUENCE_EXCLUDED 8_AFFINE_Y49 2_NONLINEAR_Y49 20_STACK_WITNESSES")
    print("QA31AM_COMPOUND_SOURCE_PATH_SECOND_P 369,575->7,1692; NO_NATIVE_OR_STAGE1_PASS")
if __name__=="__main__":main()
