#!/usr/bin/env python3
"""Rebuild the exact QA10 17D BeQunge 208-opcode specimen from pinned QA09A history."""
import hashlib,json
from pathlib import Path

SPEC=Path("qa/spaghetti10_17d_dual_worker_macro_candidate.beq")
META=Path("qa/SPAGHETTI10_17D_MACRO_MANIFEST.json")
PARENT=Path("qa/spaghetti09_nd17_two_worker_rendezvous_fixture.beq")
EXPECTED="010efd012ae52a60740aa97750b5a02519912e92"

def dec(n,width=0):
    return "0"+"".join("a*"+c+"+" for c in str(n).zfill(width))

def lit(n):
    return format(n,"x") if n<=15 else dec(n)

def addr(n):
    return dec(n)+"0"*16

def generate():
    fixture=PARENT.read_text(encoding="ascii").rstrip("\r\n").splitlines()
    off=[j for j,x in enumerate(fixture) if x.startswith("Lines 1,Origin 233:-2,")]
    assert len(off)==1,"Original QA09A finishing panel disappeared"
    fixture.pop(off[0]+1)
    fixture.pop(off[0])
    panels=[]
    traps=[]
    history=[]
    loc=[233,-2]+[0]*15
    x=233
    cross=addr(10001)+"g"+lit(31)+"-"+addr(10003)+"g"+lit(33)+"-+"
    for axis in range(1,17):
        tri=axis*(axis+1)//2
        first=(addr(10001)+"g."+addr(10003)+"g."+"&:"+"0"*17+"p0"
               if axis==1 else "")
        def con(n):
            return ":"+lit(tri)+"-"+cross+"+:*"+lit(n)+"+"
        a=":"+"0"*17+"g+"+cross+"+2%a*68*+"
        complement=":"+"0"*17+"g+"+cross+"+1+2%a*68*+"
        factor=":"+"0"*17+"g+"+cross+"+2%"+lit(50)+"+"
        emit=[a,con(36),complement,con(36),factor,con(42),factor,con(47),
              con(58),con(36),con(58),con(36),con(62)]
        tail=lit(axis)+"."+lit(axis)+"Z"
        fixed=len(first)+len(lit(axis))+1+sum(map(len,emit))+len(tail)
        width=4
        for _ in range(10):
            target=x+fixed+13*(2*(1+4*width+16)+3)-1
            later=max(4,len(str(target)))
            if later==width:
                break
            width=later
        body=first+lit(axis)+"+"
        targets=[]
        for k in range(13):
            vec=loc.copy()
            vec[0]=target
            for dim in range(1,axis):
                vec[dim]=13
            vec[axis]=k+1
            arg=dec(target,width)+"".join(map(lit,vec[1:]))
            assert len(arg)==1+4*width+16
            body+=emit[k]+arg+"p"+arg+"g."
            targets.append(vec)
            traps.append((vec,"@"))
        body+=tail
        assert len(body)==target-x+1
        panels.append((loc.copy(),body))
        history.append({"axis":axis,"source_pos":loc.copy(),"source_x":x,
                        "source_length":len(body),"target_x":target,
                        "target_positions":targets})
        loc=targets[-1].copy()
        loc[0]=target+1
        x=target+1
    panels.append((loc.copy(),"*.@"))
    beq="\n".join(fixture)+"\n"
    for vec,source in panels+traps:
        beq+=("Lines 1,Origin %d:%d,Coord %s:\n%s\n"%
              (vec[0],vec[1],":".join(map(str,vec[2:])),source))
    return beq.encode("ascii"),history

def main():
    original,stages=generate()
    digest=hashlib.sha1(("blob %d\0"%len(original)).encode()+original).hexdigest()
    assert digest==EXPECTED,("Deterministic QA10 builder drift",digest)
    assert SPEC.read_bytes()==original,"Real BeQunge specimen does not equal builder result"
    manifest=json.loads(META.read_text("utf-8"))
    assert manifest["stages"]==stages,"Stage axes/geometries changed"
    assert manifest["source_bytes"]==len(original)
    assert manifest["generated_opcode_count"]==16*13
    assert manifest["source_blocks"]==236
    print("QA10_17D_SOURCE_REPRODUCIBILITY_PASS",digest,
          "bytes",len(original),"stages",len(stages),"traps",208)

if __name__=="__main__":
    main()
