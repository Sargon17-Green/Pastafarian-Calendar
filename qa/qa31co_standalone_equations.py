"""Exact source equations for day_count, save, and their two-dimensional shared implementation."""
import argparse
import json
from pathlib import Path

from qa31cf_independent_native_audit import git_blob
from qa31ch_scanner_induction import need
from qa31cm_kernel_equations import M, ORIGIN, SAVE_PIN, constant, execute, is_zero, positive, quotient, rem, var
from qa31cn_two_field_scanners import SPECS

SIGN, MAG, VALID = (7,1450), (11,1451), (13,1452)
B, P, A, U = (17,1453), (19,1454), (23,1455), (25,1456)
C, FLAG, RESULT = (29,1456), (31,1457), (37,1458)
MOD, DIGIT, RAW, SAVE, MIX, H = (41,1459), (43,1460), (47,1461), (53,1462), (59,1463), (61,1464)
GATE, FINAL = (1200,1550), (1200,1650)
ARROWS = {">":(1,0), "v":(0,1), "<":(-1,0), "^":(0,-1)}


def segment(lines, pos, direction, stack, memory, *, end, known_nonzero=(), names=None):
    stack, mem = list(stack), dict(memory)
    log, outs, gate_fetches = [], [], []
    names = names or {}
    width, height = max(map(len,lines)), len(lines)
    def glyph(p):
        x,y = p
        need(0<=x<width and 0<=y<height, "source ray escaped")
        if p in mem:
            need(p in (GATE,FINAL), "data executed")
            return constant(mem[p])
        return lines[y][x] if x<len(lines[y]) else 32
    def pop():
        need(bool(stack), "arithmetic stack underflow")
        return stack.pop()
    for tick in range(8000):
        if tick and pos == end:
            need(not stack and not outs, "unclean loop boundary")
            return log,outs,gate_fetches,tick,direction,()
        op = chr(glyph(pos))
        if pos in (GATE,FINAL):
            need(pos in mem and op in ">v", "unwritten or incorrect executable gate")
            gate_fetches.append((pos,op))
        if op in "0123456789abcdef":
            stack.append(int(op,16))
        elif op in "+-*/%`":
            right,left = pop(),pop()
            if op == "+": value=left+right
            elif op == "-": value=left-right
            elif op == "*": value=left*right
            elif op == "/": value=quotient(left,right)
            elif op == "%": value=rem(left,right)
            else: value=positive(left-right)
            stack.append(value)
        elif op == "!":
            v = pop()
            stack.append(0 if any(v == n for n in known_nonzero) else is_zero(v))
        elif op in "gp":
            y,x=constant(pop()),constant(pop())
            a=(x,y)
            if op == "p":
                value=pop()
                log.append((a,value))
                mem[a]=names.get(a,value)
            else:
                need(a in mem, "read of unowned memory")
                stack.append(mem[a])
        elif op == "x":
            y,x=constant(pop()),constant(pop())
            direction=(x,y)
        elif op in ARROWS:
            direction=ARROWS[op]
        elif op == ".":
            outs.append(pop())
        elif op == "@":
            need(end is None, "unexpected halt")
            return log,outs,gate_fetches,tick+1,direction,tuple(stack)
        else:
            raise ValueError("unsupported instruction %s at %r"%(op,pos))
        for _ in range(5000):
            pos=(pos[0]+direction[0],pos[1]+direction[1])
            if glyph(pos)!=32:
                break
        else:
            raise ValueError("blank ray bound")
    raise ValueError("source segment bound")


def initialization(name, rows):
    moves = set()
    ticks = set()
    for sclass,s in enumerate((0,1,2+var("above two"))):
        for nonzero,m in enumerate((0,var("positive magnitude"))):
            nz = ([s,s-1] if sclass == 2 else []) + ([m] if nonzero else [])
            writes,_,gates,k,d,_ = segment(rows,(3,0),(1,0),[s,m],{},end=GATE,
                                           known_nonzero=nz,names={GATE:62})
            valid = int(sclass == 0 or (sclass == 1 and nonzero))
            expected = [(MAG,m),(SIGN,s),(VALID,valid)]
            if name != "day_count":
                expected.append((C if name == "save" else MOD,M))
            expected.extend(((B,m),(P,1),(A,0)))
            if name == "interleaved_day_save":
                expected.append((U,0))
            expected.append((GATE,62+56*nonzero))
            need(writes == expected and not gates, "fresh sign/magnitude validation or accumulator")
            moves.add(d)
            ticks.add(k)
    need(len(moves) == len(ticks) == 1, "unexpected entry geometry")
    return moves.pop(),ticks.pop()


def iteration(name, rows, direction):
    b,p,a,u,digit,mix,q = map(var,("b","p","a","u","digit","mix","q"))
    low = rem(b,10)
    mem = {B:b,P:p,A:a,GATE:118}
    aliases = {B:q,GATE:62}
    if name == "day_count":
        expected = [(A,a+p*low),(B,quotient(b,10)),(P,p*10)]
    elif name == "save":
        mem[C] = M
        expected = [(A,rem(a+p*low,M)), (P,rem(p*10,M)), (B,quotient(b,10))]
    else:
        mem.update({MOD:M,U:u})
        aliases.update({MIX:mix,DIGIT:digit})
        expected = [(MIX,low+rem(u,97)),(DIGIT,mix-rem(u,97)),(A,a+p*digit),
                    (U,rem(u+p*digit,M)),(P,p*10),(B,quotient(b,10))]
    expected.append((GATE,118-56*is_zero(q)))
    writes,_,fetches,k,back,_ = segment(rows,GATE,direction,[],mem,end=GATE,names=aliases)
    need(writes == expected and back == direction and fetches == [(GATE,"v")], "numeric loop or back edge")
    # For b=10q+d with 0<=d<10 the exact value is invariant. Reducing this
    # identity modulo M gives the modular invariant, including reduced place values.
    need(a+p*(10*q+digit) == a+p*digit+10*p*q, "decimal invariant")
    need(low+rem(u,97)-rem(u,97) == low, "fused feedback cancellation")
    return k


def finish(name, rows, direction):
    s,a,u,h,r,f = map(var,("s","a","u","h","r","f"))
    day = 2*h*(1-2*f)+1-f
    saved = r+M*is_zero(r)
    results = {}
    for valid in (0,1):
        mem = {A:a,SIGN:s,VALID:valid,GATE:62}
        aliases = {}
        if name == "day_count":
            expected = [(C,ORIGIN+a*(1-2*s)),(FLAG,positive(0-h)),(RESULT,day)]
            aliases.update({C:h,FLAG:f})
            output = [day]
        elif name == "save":
            mem[C] = M
            expected = [(FLAG,a*is_zero(s)+(M-a)*is_zero(s-1)),(RESULT,saved)]
            aliases[FLAG] = r
            output = [saved]
        else:
            mem.update({U:u, MOD:M})
            expected = [(H,ORIGIN+a*(1-2*s)),(RAW,M*s+u*(1-2*s)),(FLAG,positive(0-h)),
                        (SAVE,saved),(RESULT,day)]
            aliases.update({H:h,RAW:r,FLAG:f})
            output = [day,saved]
        expected.append((FINAL,62+56*valid))
        writes,out,fetches,k,_,stack = segment(rows,GATE,direction,[],mem,end=None,names=aliases)
        need(writes == expected and out == (output if valid else [-1]*len(output)), "output or error sentinel")
        need(fetches == [(GATE,">"),(FINAL,"v" if valid else ">")], "output route")
        need(stack == ((h,) if name == "interleaved_day_save" else ()), "unexpected final private stack")
        results["valid" if valid else "invalid"] = k
    return results


def proof(name,source):
    rows=source.split(b"\n")
    direction,initial=initialization(name,rows)
    period=iteration(name,rows,direction)
    tails=finish(name,rows,direction)
    return {"source":git_blob(source),"initial_sign_magnitude_classes":6,"initial_steps":initial,
            "first_gate_direction":direction,"steps_per_decimal_digit":period,"exit_steps":tails,
            "output_fields":SPECS[name][2],"private_stack_cells_discarded_at_halt":int(name == "interleaved_day_save")}


def references(folder):
    def load(name,pin):
        raw=(folder/name).read_bytes()
        need(git_blob(raw)==pin,"independent BF98 reference identity")
        return raw.splitlines()
    day=load("day_count.b98","9560cc28f77e37ac9b0b9ba4c677a484745b5d89")
    save=load("save.b98",SAVE_PIN)
    m,s=var("m"),var("s")
    tests=[
        ((0,m), (), 2*(ORIGIN+m)+1, 1+rem(m+M-1,M)),
        ((0,0), (), 2*ORIGIN+1, M),
        ((1,0), (), -1,-1),
        ((1,m), ((m,1),(m-ORIGIN,-1)), 2*(ORIGIN-m)+1,M-rem(m,M)),
        ((1,ORIGIN), (), 1,M-ORIGIN),
        ((1,m), ((m,1),(m-ORIGIN,1)), 2*(m-ORIGIN),M-rem(m,M)),
        # Both BF98 references halt on a bad flag without asking for the magnitude.
        ((s,), ((s,1),(s-1,1)), -1,-1),
    ]
    for inputs,facts,count,residue in tests:
        for source,want in ((day,count),(save,residue)):
            out,_,_,_=execute(source,(0,0),(1,0),{},scope="reference",end=None,
                              inputs=inputs,sign_facts=facts)
            need(out==[want],"local normative reference equation")
    return len(tests)*2


def mutation_checks(name,source):
    rows=source.split(b"\n")
    sites=[(x,y) for y,row in enumerate(rows) for x,op in enumerate(row) if op==ord("%")]
    for x,y in sites:
        changed=rows.copy()
        changed[y]=changed[y][:x]+b"/"+changed[y][x+1:]
        try:
            proof(name,b"\n".join(changed))
        except ValueError as error:
            need(str(error)=="numeric loop or back edge","wrong arithmetic mutation rejection")
        else:
            raise ValueError("arithmetic mutation accepted")
    return sites


if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("originals",type=Path)
    parser.add_argument("references",type=Path)
    parser.add_argument("output",type=Path)
    args=parser.parse_args()
    result={}
    for name,(old,_,_) in SPECS.items():
        source=(args.originals/(name+".b98")).read_bytes()
        need(git_blob(source) == old,"source identity")
        result[name]=proof(name,source)
        result[name]["rejected_remainder_to_division_sites"]=mutation_checks(name,source)
    result["native_reference_source_equations"]=references(args.references)
    args.output.write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("Three complete two-field arithmetic kernels: entry, all digit loops, both output routes.")
