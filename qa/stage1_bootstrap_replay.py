"""Replay this branch's frozen fixtures and the uncovered direct gate/choice edges (Python 2.7)."""
from __future__ import print_function
import csv
import json
import sys

from stage1_native_diverse_geometry import native


def replay():
    rows=[]
    def exact(group,name,data,want):
        expected=[str(v) for v in want]
        got=native("reference/"+name+".b98",data+"\n")
        if got!=expected:
            raise ValueError("%s %s %r: wanted %r, got %r"%(group,name,data,expected,got))
        rows.append(dict(group=group,program=name,input=data,output=got))

    for label in ("PRIMITIVE","INTEGRATION"):
        with open("fixtures/REFERENCE_"+label+"_FIXTURES.tsv","rb") as f:
            for row in csv.DictReader(f,delimiter="\t"):
                exact(label,row["reference_file"][:-4],row["input_tokens"].strip(),row["expected_output_tokens"].split())
    origin=-15055671
    for raw,want in [("0 0",origin),("1 0",-1),("0 2 42 963",origin+1005),
                     ("1 2 42 963",origin-1005),("0 1 41",-1),("1 1 964",-1)]:
        exact("gate-walk","gate_walk",raw,[want])
    for target,want in [("1 42",[0,-1,-1,1,-1]),("1 41",[0,-1,0,0,0]),
                        ("0 0",[0,0,0,1,0]),("0 42",[0,1,1,1,1]),("0 43",[-1])]:
        exact("gate-lookup","gate_lookup","1 1 3 "+target+" 1 42 0 0 0 42",want)
    exact("gate-lookup","gate_lookup","0 0 2 0 0 0 0 0 0",[-1])
    m=2**127-1
    for name in ("choose_rank_short","choose_rank"):
        exact("short-choice",name,"1 0 1 13",[1])
        exact("short-choice",name,"12 1 1 13",[12])
    # With Bound=M+1, the first two answers 1,2 give base-M digits 0,1.
    for name in ("choose_rank_wide","choose_rank"):
        exact("wide-choice",name,"1 0 1 "+str(m+1),[m+1])
    counts={}
    for row in rows:
        group=row["group"]
        counts[group]=counts.get(group,0)+1
    if counts!={"PRIMITIVE":48,"INTEGRATION":20,"gate-walk":6,"gate-lookup":6,"short-choice":4,"wide-choice":2}:
        raise ValueError("incomplete Native corpus: "+str(counts))
    return dict(counts=counts,rows=rows)


if __name__=="__main__":
    result=replay()
    with open(sys.argv[1],"wb") as stream:
        stream.write(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("NATIVE_BOOTSTRAP_DOMAIN_REPLAY",result["counts"])
