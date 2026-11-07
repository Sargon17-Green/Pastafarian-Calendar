#!/usr/bin/env python3
"""QA31O: source-pinned conditional row38->41 analysis (no Native)."""
import argparse
import hashlib
import json
from pathlib import Path

BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"
R38 = "          >00a*0+a*0+a*0+a*0+a*1++00a*0+a*0+a*0+a*4+a*9++g00a*0+a*0+a*0+a*0+a*4++-!00a*0+a*0+a*0+a*6+a*1++       *j00a*0+a*0+a*1+a*6+a*5+-       00a*0+a*0+a*0+a*0+a*6++       x00a*0+a*0+a*2+a*2+a*6+-       00a*0+a*0+a*0+a*0+a*3++       x"
R41 = "          >00a*0+a*0+a*0+a*1+a*0++00a*0+a*0+a*0+a*4+a*9++g00a*0+a*0+a*0+a*1+a*1++00a*0+a*0+a*0+a*4+a*9++g00a*0+a*0+a*0+a*1+a*2++00a*0+a*0+a*0+a*4+a*9++g00a*0+a*0+a*0+a*1+a*3++00a*0+a*0+a*0+a*4+a*9++g00a*0+a*0+a*2+a*4+a*1+-00a*0+a*0+a*0+a*4+a*1+-x"

def require(flag, message):
    if not flag:
        raise AssertionError(message)

def load(path):
    if path is None:
        return {38: R38, 41: R41}, "fixture-only"
    raw = Path(path).read_bytes()
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
    require(blob == BLOB, "original source Git blob mismatch")
    lines = raw.splitlines()
    require(len(lines) > 41, "missing source row")
    rows = {38: lines[38].decode("ascii"), 41: lines[41].decode("ascii")}
    require(rows == {38: R38, 41: R41}, "source row drift")
    return rows, blob

def run(row, source, memory):
    stack, reads, x = [], [], 10
    def pop():
        require(bool(stack), "stack underflow")
        return stack.pop()
    for tick in range(300):
        require(0 <= x < len(source), "source segment exhausted")
        op = source[x]
        if op in " >":
            x += 1
            continue
        if op in "0123456789abcdef":
            stack.append(int(op, 16))
        elif op in "+-*"+chr(96):
            b, a = pop(), pop()
            stack.append(a+b if op=="+" else a-b if op=="-" else
                         a*b if op=="*" else int(a>b))
        elif op == "!":
            stack.append(int(pop() == 0))
        elif op == "g":
            y, a = pop(), pop()
            require((a,y) in memory, "explicit g hypothesis required")
            stack.append(memory[(a,y)])
            reads.append([x,a,y,memory[(a,y)]])
        elif op == "j":
            n = pop()
            require(0 <= n <= 61, "unmodeled jump")
            x += n+1
            continue
        elif op == "x":
            dy, dx = pop(), pop()
            return {"reads":reads,"x":[x,row],"next":[x+dx,row+dy],
                    "stack":stack}
        else:
            raise AssertionError("unmodeled opcode at %d,%d: %s" % (x,row,op))
        x += 1
    raise AssertionError("bounded model exceeded 300 cells")

def verify(rows):
    require([len(rows[38]),len(rows[41])]==[237,246], "row lengths")
    for row,opcode,expected in ((38,"g",[57]),(38,"j",[114]),
                                (38,"x",[175,236]),(41,"g",[57,104,151,198]),
                                (41,"x",[245])):
        require([i for i,c in enumerate(rows[row]) if c==opcode]==expected,
                "site mismatch at row %d" % row)
    cases=[]
    for m in (0,1,3,4,5):
        q=run(38,rows[38],{(1,49):m})
        target=[10,41] if m==4 else [10,44]
        require(q["next"]==target and q["stack"]==[], "row38 branch")
        require(q["x"]==([236,38] if m==4 else [175,38]),"row38 site")
        require(q["reads"]==[[57,1,49,m]],"row38 g")
        cases.append({"g_1_49":m,"next":target})
    for values in ((0,0,0,0),(1,2,3,4),(-1,10,-10,999)):
        q=run(41,rows[41],{(10+i,49):v for i,v in enumerate(values)})
        require(q["reads"]==[[57+i*47,10+i,49,v] for i,v in enumerate(values)],
                "row41 reader provenance")
        require(q["next"]==[4,0] and q["x"]==[245,41],"row41 return")
        require(q["stack"]==list(values),"row41 stack preservation")
        cases.append({"row41_values":values,"next":[4,0],"stack":q["stack"]})
    require(len(cases)==8, "case count")
    return cases

def hostile(rows):
    attacks=((38,57,"0"),(38,114,"+"),(38,175,"0"),(38,236,"0"),
             (38,90,"+"),(41,57,"0"),(41,104,"0"),(41,151,"0"),
             (41,198,"0"),(41,245,"0"))
    rejected=0
    for row,pos,new in attacks:
        broken=dict(rows)
        line=broken[row]
        require(line[pos]!=new,"ineffective mutation")
        broken[row]=line[:pos]+new+line[pos+1:]
        try:verify(broken)
        except (AssertionError,IndexError,ValueError,TypeError):
            rejected+=1
        else:raise AssertionError("hostile mutation escaped %d,%d" % (row,pos))
    require(rejected==10,"mutation count")
    return rejected

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("source",nargs="?")
    parser.add_argument("--out",default="qa31o_row41.json")
    args=parser.parse_args()
    rows,origin=load(args.source)
    cases=verify(rows)
    rejected=hostile(rows)
    report={"schema":"qa31o-conditional-row41-v1",
            "project_id":"PC-BRANCH-BEFUNGE98-KYRGYZ",
            "source_provenance":origin,"source_model_cases":cases,
            "cases_passed":len(cases),"hostile_rejected":rejected,
            "row41_read_cells":[[x,49] for x in range(10,14)],
            "conditional_gate":"row38 g(1,49) == 4",
            "row41_exit":[4,0],"new_native":0,
            "natural_input_witness_proven":False,
            "global_reachability_proven":False,"stage1_pass":False}
    Path(args.out).write_text(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("QA31O_CONDITIONAL_SOURCE_MODEL_8_OF_8")
    print("QA31O_HOSTILE_SOURCE_10_OF_10")
    print("QA31O_NO_NATIVE_NO_GLOBAL_PASS")

if __name__=="__main__":
    main()
