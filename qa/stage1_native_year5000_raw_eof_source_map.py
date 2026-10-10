#!/usr/bin/env python3
"""Exact native candidate source-space bridge; no executable cell drift."""
import hashlib
from pathlib import Path
BASE=Path("qa/year5000_integrated_lf_eof_grammar.b98").read_bytes()
NEW=Path("qa/year5000_raw_eof_candidate.b98").read_bytes()
IMMUTABLE="fb6513605febc92c4cd1b453295253cb1cb49740"
def gh(b):return hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+b"\\0"+b).hexdigest()
def require(v,m):
    if not v:raise AssertionError(m)
def prove(old,new):
    require(gh(old)==IMMUTABLE,"prior Native qualified integrated BF98 changed")
    rows=old.split(b"\\n")
    require(len(rows)==3 and rows[2]==b"" and len(rows[0])==953 and
            rows[0][28:31]==b"0j~" and len(rows[1])==949 and
            rows[1].index(b">")==945,
            "frozen BF98 control-vector origins changed")
    expect0=rows[0][:28]+b"1"+rows[0][29:30]+b"v"+rows[0][30:]
    expect1=b" "*30+b">a^"+b" "*(946-33)+b">1.@"
    require(new==expect0+b"\\n"+expect1+b"\\n",
            "Native EOF candidate edited outside exact 5-point bridge")
    return len(expect0),len(expect1)
def main():
    x,y=prove(BASE,NEW)
    mutations=(
      ("boot_jump",28,b"0"),("catcher",30,b">"),
      ("read",31,b"&"),("read_body",40,b"x"),
      ("eof_entry",len(NEW)-950+30,b"<"),
      ("fake_lf",len(NEW)-950+31,b"9"),
      ("rejoin",len(NEW)-950+32,b"v"),
      ("former_accept",len(NEW)-5,b"<"),
      ("new_accept",len(NEW)-4,b"0"),
      ("source_start",0,b"1")
    )
    refused=[]
    for name,index,replacement in mutations:
        c=bytearray(NEW);require(c[index:index+1]!=replacement,"inert "+name)
        c[index:index+1]=replacement
        try:prove(BASE,bytes(c))
        except AssertionError:refused.append(name)
        else:raise AssertionError("modified BF98 passed exact map "+name)
    try:prove(BASE,NEW+b"x")
    except AssertionError:refused.append("appended")
    else:raise AssertionError("appended cell accepted")
    print("NATIVE_YEAR5000_RAW_EOF_CANDIDATE_SOURCE_MAP_PASS",
          "rows=%s"%((x,y),),"tamper_source_mutants=%d"%len(refused),
          "stage1_acceptance=NO")
if __name__=="__main__":main()
