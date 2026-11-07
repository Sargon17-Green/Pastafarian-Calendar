#!/usr/bin/env python3
"""QA31F physical q(1,49) source write/guard probe. Bounded model, NOT Native."""
import hashlib
import json
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "src/interleaved_work_counts.b98"
BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"

def load():
    b = SOURCE.read_bytes()
    sha = hashlib.sha1(b"blob " + str(len(b)).encode() + b"\0" + b).hexdigest()
    assert sha == BLOB, ("source blob drift", sha)
    rows = b.decode("ascii").splitlines()
    for y, x, ch in [(2,106,"p"),(11,57,"g"),(11,113,"j"),(11,174,"x"),
                     (11,235,"x"),(14,200,"p"),(14,248,"p"),(26,248,"p"),
                     (26,344,"p"),(35,248,"p"),(23,57,"g"),(23,113,"j")]:
        assert rows[y][x] == ch, (x,y,ch)
    return rows

def segment(rows, row, memory):
    x,y,dx,dy = 10,row,1,0
    stack,puts,gets,jumps = [],[],[],[]
    mem = dict(memory)
    def pop():
        return stack.pop() if stack else 0
    for tick in range(1,600):
        assert y == row and 0 <= x < len(rows[y]), ("escape",x,y)
        op = rows[y][x]
        if "0" <= op <= "9":
            stack.append(int(op))
        elif "a" <= op <= "f":
            stack.append(10+ord(op)-ord("a"))
        elif op in ("+","-","*",chr(96)):
            b,a = pop(),pop()
            stack.append(a+b if op=="+" else a-b if op=="-" else
                         a*b if op=="*" else int(a>b))
        elif op == "g":
            gy,gx = pop(),pop()
            v = mem.get((gx,gy),32)
            stack.append(v)
            gets.append((x,gx,gy,v))
        elif op == "p":
            py,px,v = pop(),pop(),pop()
            mem[(px,py)] = v
            puts.append((x,px,py,v))
        elif op == "j":
            delta = pop()
            jumps.append((x,delta))
            x += dx*delta
            y += dy*delta
        elif op == "x":
            dy,dx = pop(),pop()
        elif op == ">":
            dx,dy = 1,0
        elif op != " ":
            raise AssertionError(("unsupported opcode",x,y,op))
        x += dx
        y += dy
        if y != row:
            assert x == 10 and not stack, ("exit/stack",x,y,stack)
            return (x,y,tick,mem,puts,gets,jumps)
    raise AssertionError(("segment bound",row))

def gate(rows,q):
    x,y,t,mem,puts,gets,jumps = segment(rows,11,{(1,49):q})
    assert (x,y,t) == (10,14 if q<=3 else 44,165), (q,x,y,t)
    assert gets == [(57,1,49,q)] and jumps == [(113,0 if q<=3 else 61)]
    assert not puts

def writer(rows,row,q,m,c0,c2):
    x,y,t,mem,puts,gets,jumps = segment(
        rows,row,{(0,49):c0,(1,49):q,(2,49):c2,(3,49):m})
    assert (x,y,t) == {14:(10,5,300),26:(10,5,396),
                       35:(10,38,300)}[row], (row,x,y,t)
    wantq = q if row==14 else q+1
    wantm = 1 if row==14 else 0 if row==26 else m
    assert mem[(1,49)] == wantq and mem[(3,49)] == wantm, (row,q,m)
    assert (248,3 if row==14 else 1,49,
            1 if row==14 else q+1) in puts, (row,puts)
    assert len(puts) == {14:2,26:4,35:2}[row] and not jumps

def audit(rows):
    x,y,t,mem,puts,gets,jumps = segment(rows,2,{})
    assert (x,y) == (10,5) and puts == [
        (58+48*i,i,49,0) for i in range(4)], puts
    for q in range(10):
        gate(rows,q)
    n=0
    for q in range(7):
        for m in (0,1):
            for c0 in (48,49,57):
                for c2 in (0,7):
                    for row in (14,26,35):
                        writer(rows,row,q,m,c0,c2)
                        n+=1
    assert n==252
    rejected=0
    for row,x,test in [(11,113,lambda r:gate(r,4)),
                       (26,248,lambda r:writer(r,26,0,1,48,0)),
                       (35,248,lambda r:writer(r,35,0,1,48,0))]:
        damaged=list(rows)
        line=list(damaged[row])
        line[x]=" "
        damaged[row]="".join(line)
        try:
            test(damaged)
        except AssertionError:
            rejected+=1
        else:
            raise AssertionError(("mutation was accepted",x,row))
    assert rejected==3
    return {"schema":"qa31f-original-q149-source-guard-v1",
            "source_blob":BLOB,"bounded_model_cases":263,
            "hostile_mutations_rejected":rejected,
            "q_above_3_row11_exit":[10,44],"q_at_most_3_exit":[10,14],
            "row14_sets_m_1_without_q_increment":True,
            "row26_increments_q_and_resets_m":True,
            "row35_increments_q_and_preserves_m":True,
            "new_native_executions":0,"historical_qa20_rescans":0,
            "natural_input_witness":False,"global_owner_proven":False,
            "stage1_complete":False}

if __name__ == "__main__":
    print(json.dumps(audit(load()),indent=2))
