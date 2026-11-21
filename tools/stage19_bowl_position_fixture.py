#!/usr/bin/env python3
"""Stage19 deterministic Native fixture generator; independent Python itertools enumeration."""
import hashlib, itertools, json
from pathlib import Path
VECTORS=Path("test/stage19_bowl_position_design_vectors.json")
PERMS=list(itertools.permutations(range(1,7)))
assert len(PERMS)==720 and len(set(PERMS))==720
def literal(n):
    assert isinstance(n,int)
    return f"{-n}_" if n<0 else str(n)
def position(order,bowl_id):
    found=0
    for i,value in enumerate(order,1):
        if value==bowl_id: found=i
    return found
def order_block(order,order_index,mutant=None):
    code=["z;d:6a;!"+"".join(literal(x)+"a;!" for x in order)]
    labels=[];checks=0
    for bowl_id in range(1,7):
        case_index=order_index*6+bowl_id-1
        tag=f"STAGE19_CASE_{case_index:04d}"
        expected=position(order,bowl_id)
        if mutant=="wrong_expected" and case_index==0: expected=2
        code.append(f"z;b:d;a;!b;{literal(bowl_id)}a;!b;s:b;36h;!!o:")
        code.append(f'o;{literal(expected)}=~["{tag}_POSITION_FAIL"0 0/]?')
        code.append(f'b;g;!d;-0=~["{tag}_ORDER_HANDLE_FAIL"0 0/]?')
        code.append(f'b;1+g;!{literal(bowl_id)}=~["{tag}_BOWL_ID_FAIL"0 0/]?')
        code.append(f'"{tag}_OK"10,')
        labels.append(tag+"_OK");checks+=3
    for pos,value in enumerate([6,*order]):
        cell="d;g;!" if pos==0 else f"d;{pos}+g;!"
        code.append(f'{cell}{literal(value)}=~["STAGE19_ORDER_{order_index:03d}_CELL_{pos}_FAIL"0 0/]?')
        checks+=1
    marker=f"STAGE19_ORDER_{order_index:03d}_OK";code.append(f'"{marker}"10,')
    return code,labels,marker,checks
def positive_fixture(orders,start,mutant=None):
    code=["{ Stage19 exhaustive Native cases generated from Python itertools. }"]
    labels=[];markers=[];checks=0
    for off,order in enumerate(orders):
        block,case_labels,marker,n=order_block(order,start+off,mutant)
        code.extend(block);labels.extend(case_labels);markers.append(marker);checks+=n
    final=f"STAGE19_CHUNK_{start:03d}_OK"
    code.extend([f'"{final}"10,',"[z;0>][%z;1-z:]#"])
    return "\n".join(code)+"\n",labels,markers,final,checks
def probe_fixture(probes=None,mutant=None):
    if probes is None:
        parsed=json.loads(VECTORS.read_text(encoding="utf-8"))
        assert parsed["project_id"]=="PC-BRANCH-FALSE-ARABIC" and parsed["stage"]==19 and parsed["scope"]=="DESIGN_ONLY"
        probes=parsed["probes"]
    code=["{ Stage19 non-permutation and not-found semantic probes. }"];labels=[];checks=0
    for i,item in enumerate(probes):
        order=item["order"];bowl=item["bowl_id"];expected=item["expected"]
        if mutant=="wrong_duplicate_first" and item["label"]=="duplicate-last-match":expected=1
        tag=f"STAGE19_PROBE_{i:03d}"
        code.append("z;d:6a;!"+"".join(literal(x)+"a;!" for x in order))
        code.append(f"z;b:d;a;!b;{literal(bowl)}a;!b;s:b;36h;!!o:")
        code.append(f'o;{literal(expected)}=~["{tag}_POSITION_FAIL"0 0/]?')
        code.append(f'b;g;!d;-0=~["{tag}_ORDER_HANDLE_FAIL"0 0/]?')
        code.append(f'b;1+g;!{literal(bowl)}=~["{tag}_BOWL_ID_FAIL"0 0/]?')
        for pos,value in enumerate([6,*order]):
            cell="d;g;!" if pos==0 else f"d;{pos}+g;!"
            code.append(f'{cell}{literal(value)}=~["{tag}_TABLE_{pos}_FAIL"0 0/]?');checks+=1
        code.append(f'"{tag}_OK"10,');labels.append(tag+"_OK");checks+=3
    final="STAGE19_PROBES_OK";code.extend([f'"{final}"10,',"[z;0>][%z;1-z:]#"])
    return "\n".join(code)+"\n",labels,final,checks
def invalid_length_fixture(length):
    code=["{ Stage19 invalid direct-table header control. }",
          "z;d:"+literal(length)+"a;!1a;!2a;!3a;!4a;!5a;!6a;!",
          "z;b:d;a;!b;1a;!b;s:b;36h;!!o:",
          '"STAGE19_BAD_LENGTH_ACCEPTED"10,',"[z;0>][%z;1-z:]#"]
    return "\n".join(code)+"\n"
def chunks():return [(start,PERMS[start:start+120]) for start in range(0,720,120)]
def integrity():
    rows=[]
    for start,orders in chunks():
        program,labels,markers,final,checks=positive_fixture(orders,start)
        assert len(labels)==len(set(labels))==720 and len(markers)==120
        rows.append(dict(start_order=start,orders=len(orders),cases=len(labels),assertions=checks,final=final,sha256=hashlib.sha256(program.encode()).hexdigest()))
    assert len(rows)==6 and sum(x["orders"] for x in rows)==720 and sum(x["cases"] for x in rows)==4320
    return rows
if __name__=="__main__":print(json.dumps(integrity(),indent=2))
