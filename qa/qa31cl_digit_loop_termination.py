"""Source proof of the first shared digit loop, independently of its accumulator values."""
import argparse
import json
from pathlib import Path
from zipfile import ZipFile

from qa31cg_compare import ARROWS, sha256
from qa31cf_independent_native_audit import PIN, git_blob
from qa31ch_scanner_induction import SLOTS, integer, need
from qa31ci_native_scanner_and_valid_fork import ARCHIVE_SHA, GATE, step_groups
from qa31cj_first_arithmetic_join import SCRATCH
from qa31ck_first_gate_ownership import FIXED, MAGS, SIGNS, TARGETS, WRITER

DIGITS = {(37,1700), (41,1701), (43,1702), (47,1703)}
OPAQUE = "arbitrary integer"
ENTRY = (165,377)
PERIOD = 2326


def arithmetic(op, left, right):
    # Untracked values represent arbitrary integers. They cannot be used
    # as a direction, address, divisor, branch decision, or executable byte.
    if op in "/%":
        need(type(right) is int and right > 0, "nonpositive or unknown divisor")
        if op == "/" and left in ("B", "D"):
            need(right == 10, "rank divisor is not ten")
            return left + "/10"
        if type(left) is int and left >= 0:
            return left // right if op == "/" else left % right
        return OPAQUE
    if type(left) is int and type(right) is int:
        if op == "+":
            return left+right
        if op == "-":
            return left-right
        return left*right
    if op == "*" and (left == 0 or right == 0):
        return 0
    if (op in "+-" and right == 0) or (op == "*" and right == 1):
        return left
    if (op == "+" and left == 0) or (op == "*" and left == 1):
        return right
    return OPAQUE


def segment(lines, b_empty, d_empty):
    # Each quotient is either zero or positive. On entry the current
    # magnitudes are nonnegative and at least one is positive (live v).
    ip, delta = GATE, ENTRY
    memory = dict.fromkeys((*SIGNS, *FIXED), OPAQUE)
    memory.update({MAGS[0]:"B", MAGS[1]:"D", GATE:ord("v")})
    expected_zero = {"B/10":b_empty, "D/10":d_empty}
    stack, records, stores = [], [], []
    width, height = max(map(len, lines)), len(lines)

    def glyph(point):
        x,y = point
        need(0 <= x < width and 0 <= y < height, "loop ray escaped source")
        if point == GATE:
            return integer(memory[GATE])
        need(point not in TARGETS and point not in DIGITS and point != SCRATCH and
             not (y == 49 and x in SLOTS), "unowned executable value")
        return lines[y][x] if x < len(lines[y]) else 32

    for tick in range(PERIOD+1):
        op = chr(glyph(ip))
        current = (ip,delta,op,len(stack))
        access = None
        if tick and ip == GATE:
            expected = ">" if b_empty and d_empty else "v"
            need(tick == PERIOD and delta == ENTRY and not stack, "re-entry contract")
            need(op == expected, "wrong rewritten loop direction")
            need([memory[k] for k in MAGS] == ["B/10","D/10"], "remaining magnitudes")
            need(stores[-3:] == [(2049,MAGS[0]),(2133,MAGS[1]),(2306,GATE)], "rank and code writers")
            need(set(p for _,p in stores) == DIGITS | FIXED.keys() | set(MAGS) | {GATE}
                 and len(stores)==12, "iteration write ownership")
            records.append((current,access))
            return records
        if op in "0123456789abcdef":
            stack.append(int(op,16))
        elif op in "+-*/%":
            right,left = stack.pop(),stack.pop()
            stack.append(arithmetic(op,left,right))
        elif op == "!":
            value=stack.pop()
            if type(value) is int:
                stack.append(int(value==0))
            else:
                need(value in expected_zero, "unknown value at a zero test")
                stack.append(int(expected_zero[value]))
        elif op in ARROWS:
            delta=ARROWS[op]
        elif op == "x":
            dy,dx=integer(stack.pop()),integer(stack.pop())
            delta=dx,dy
        elif op in "pg":
            y,x=integer(stack.pop()),integer(stack.pop())
            dest=x,y
            if op == "p":
                need(dest in DIGITS or dest in FIXED or dest in MAGS or dest==GATE, "foreign write")
                memory[dest]=stack.pop()
                if dest == GATE:
                    need(ip==WRITER and type(memory[GATE]) is int, "wrong executable writer")
                stores.append((tick,dest))
            else:
                need(dest in memory, "read without an established owner")
                stack.append(memory[dest])
            access = (op,dest)
        else:
            raise ValueError(f"unsupported loop instruction {op!r} at {ip}")
        records.append((current,access))
        dx,dy=delta
        need(delta != (0,0), "loop zero delta")
        x,y=ip[0]+dx,ip[1]+dy
        while glyph((x,y))==32:
            x,y=x+dx,y+dy
        ip=x,y
    raise ValueError("loop did not rejoin")


def verify_native(path, models):
    need(sha256(path.read_bytes())==ARCHIVE_SHA, "geometry archive pin")
    result=[]
    with ZipFile(path) as z:
        need(z.testzip() is None, "geometry CRC")
        for c in json.loads(z.read("diverse_manifest.json"))["cases"]:
            raw=z.read(c["trace_file"])
            need(sha256(raw)==c["trace_sha256"], "native member pin")
            it=step_groups(raw)
            first=next(g for g in it if g[0][2:4]==GATE)
            g=first
            b,d=c["fields"][1],c["fields"][3]
            expected_loops=len(str(max(b,d))) if max(b,d)>0 else 0
            count=0
            while b or d:
                q,t=b//10,d//10
                model=models[q==0,t==0]
                live={MAGS[0]:b,MAGS[1]:d,GATE:ord("v")}
                for i,(step,access) in enumerate(model[:-1]):
                    row,events=g
                    ip,delta,op,depth=step
                    need(row==(first[0][0]+count*PERIOD+i,1,*ip,*delta,ord(op),depth), "native loop motion")
                    if access:
                        mode,address=access
                        labels=[b"WRITE_BEFORE",b"WRITE_AFTER"] if mode=="p" else [b"READ_BEFORE",b"READ_AFTER"]
                        need([tag for tag,_ in events]==labels and all(e[:2]==address for _,e in events),
                             "native memory owner")
                        if address in live:
                            old=live[address]
                            if mode=="p":
                                new={MAGS[0]:q,MAGS[1]:t,GATE:ord("v" if q or t else ">")}[address]
                                need(events[0][1]==(*address,old,new) and events[1][1]==(*address,new),
                                     "native rank/code write")
                                live[address]=new
                            else:
                                need(all(e==(*address,old) for _,e in events), "native rank read")
                    else:
                        need(not events,"unexpected native memory event")
                    g=next(it)
                b,d=q,t
                count+=1
            need(count==expected_loops and g[0]==(first[0][0]+count*PERIOD,1,*GATE,*ENTRY,ord(">"),0)
                 and not g[1], "native final east fetch")
            result.append({"case":c["case"],"loops":count,"first_gate_tick":first[0][0],"east_gate_tick":g[0][0]})
    need(len({c["case"] for c in result})==len(result)==17,"native cases")
    return result


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source",type=Path)
    ap.add_argument("geometry_zip",nargs="?",type=Path)
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    src=args.source.read_bytes()
    need(git_blob(src)==PIN,"production source pin")
    lines=src.splitlines()
    models={(z,w):segment(lines,z,w) for z in (False,True) for w in (False,True)}
    first=models[False,False]
    need(all(m[:-1]==first[:-1] for m in models.values()),"control path changed inside iteration")
    need(sum(a is not None and a[0]=="g" for _,a in first)==23,"read site count")
    hostile=[]
    for (x,y),old,new,why in (((1338,670),"a","9","rank divisor is not ten"),
                              ((663,1050),"a","b","rank divisor is not ten"),
                              ((200,1335),"7","0","wrong rewritten loop direction")):
        changed=lines.copy()
        need(changed[y][x]==ord(old),"control mutation anchor")
        changed[y]=changed[y][:x]+new.encode()+changed[y][x+1:]
        try:
            for z,w in models:
                segment(changed,z,w)
        except ValueError as error:
            need(str(error)==why,"unexpected rejection: "+str(error))
        else:
            raise ValueError("accepted a changed loop")
        hostile.append([x,y,old,new,why])
    cases=verify_native(args.geometry_zip,models) if args.geometry_zip else []
    loops=sum(c["loops"] for c in cases)
    out={"source_git_blob":PIN,"rank_update":"(B,D) -> (floor(B/10),floor(D/10))",
         "rank":"max(B,D)","period":PERIOD,"cases":cases,"archived_iterations":loops,
         "physical_iteration_steps":loops*PERIOD,"archived_final_east_fetches":len(cases),
         "geometry_sha256":ARCHIVE_SHA if cases else None,"writes":12,"reads":23,
         "exit":"east iff both quotients are zero; same IP, incoming delta and empty stack",
         "source_mutations_rejected":hostile,"payload_arithmetic":"not evaluated symbolically beyond rank/control",
         "stage1_accepted":False}
    args.output.write_text(json.dumps(out,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("QA31CL PASS | four quotient classes |",loops,"archived loop iterations |",loops*PERIOD,"STEPs")


if __name__=="__main__":
    main()
