"""Check the original shared loop, output formulas and the branch's two Befunge references."""
import argparse
import json
from collections import defaultdict
from itertools import product
from pathlib import Path
from zipfile import ZipFile

from qa31cg_compare import ARROWS, read_archive, sha256
from qa31cf_independent_native_audit import PIN, git_blob
from qa31ch_scanner_induction import HANDOFF, READ, SITES, SLOTS, Scanner, base, need, prove as scan_fresh
from qa31ci_native_scanner_and_valid_fork import ARCHIVE_SHA, GATE, protected, step_groups
from qa31cj_first_arithmetic_join import SCRATCH, prove as prove_join
from qa31ck_first_gate_ownership import TARGETS, VALID, walk as walk_initial_gate
from qa31cl_digit_loop_termination import DIGITS, ENTRY, PERIOD, segment as walk_loop

M = 2**127 - 1
INV2 = 2**126
ORIGIN = 15055671
OUTPUT_GATE = (1500, 1860)
COUNT_PIN = "f941efc793c9eee4accf5d03873f8ed029b16725"
SAVE_PIN = "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44"
QA30B_SHA = "2b0de9ceccc9068ddbaf0bd5a86569a504ad3af65cd96b4e57ab6d1b79159a7c"
FRONTIER = {(10,32):">",(10,35):">",(57,32):"g",(57,35):"g",(113,32):"j",(127,35):"g",
            (152,35):"p",(174,32):"x",(199,35):"g",(211,29):"x",(235,23):"x",(235,32):"x",
            (248,35):"p",(286,5):"x",(309,35):"x"}
S1, S2, B, D, P, E1, E2, INC, DIFF, SUM, GAP, U, V, DAY1, DAY2, N1, N2, DIST, CONN, DIRECT, R1, R2, H, FLAG = (
    (13,1694), (17,1695), (23,1697), (29,1698), (31,1699), (37,1700), (41,1701),
    (43,1702), (47,1703), (53,1704), (59,1705), (61,1706), (67,1707), (71,1708),
    (73,1709), (79,1710), (83,1711), (89,1712), (97,1713), (101,1714), (103,1715),
    (107,1716), (109,1717), (113,1718))
OUTPUT_CELLS = (N1, N2, DIST, CONN, DIRECT, R1, R2)
DATA = (TARGETS | DIGITS | {DAY1, DAY2, *OUTPUT_CELLS, H, FLAG, OUTPUT_GATE})


class Polynomial:
    """Exact integer polynomial. Non-polynomial operations are distinct named atoms."""

    def __init__(self, terms):
        self.terms = tuple(sorted((key, value) for key, value in terms.items() if value))

    def __eq__(self, other):
        return isinstance(other, Polynomial) and self.terms == other.terms

    def __add__(self, other):
        result = defaultdict(int, self.terms)
        for key, value in terms(other):
            result[key] += value
        return pack(result)

    __radd__ = __add__

    def __mul__(self, other):
        result = defaultdict(int)
        for k1, v1 in self.terms:
            for k2, v2 in terms(other):
                result[tuple(sorted(k1 + k2))] += v1 * v2
        return pack(result)

    __rmul__ = __mul__

    def __sub__(self, other):
        return self + (-1)*other

    def __rsub__(self, other):
        return other + (-1)*self


def terms(value):
    return (((), value),) if type(value) is int else value.terms


def pack(mapping):
    result = Polynomial(mapping)
    if not result.terms:
        return 0
    if len(result.terms) == 1 and result.terms[0][0] == ():
        return result.terms[0][1]
    return result


def var(name):
    return Polynomial({(name,): 1})


def function(name, *operands):
    return var(name + repr(tuple(terms(v) for v in operands)))


def constant(value):
    need(type(value) is int, "symbolic direction, address or loop control")
    return value


def rem(value, modulus):
    need(type(modulus) is int and modulus > 0, "bad remainder divisor")
    return value % modulus if type(value) is int else function("rem", value, modulus)


def quotient(value, divisor):
    need(type(divisor) is int and divisor > 0, "bad quotient divisor")
    return value // divisor if type(value) is int else function("quotient", value, divisor)


def positive(value):
    return int(value > 0) if type(value) is int else function("positive", value)


def is_zero(value):
    if type(value) is int:
        return int(value == 0)
    if len(value.terms) == 1:
        monomial, factor = value.terms[0]
        if factor == 1 and len(monomial) == 1 and monomial[0].startswith(("positive(", "zero(")):
            return 1 - value
    return function("zero", value)


def loop_contract():
    start = {key:var(n) for key,n in zip((S1,S2,B,D,P,SUM,GAP,U,V),
                                         ("sign A","sign C","B","D","place","sum","gap","mod sum","mod gap"))}
    p = start[P]
    ea, ec, inc, diff, qb, qd = map(var, ("digit A","digit C","increment","difference","next B","next D"))
    writes = [
        (E1,start[S1]*rem(start[B],10),ea), (E2,start[S2]*rem(start[D],10),ec),
        (INC,p*(ea+ec),inc), (DIFF,p*(ea-ec),diff),
        (SUM,start[SUM]+inc,None), (GAP,start[GAP]+diff,None),
        (U,rem(start[U]+inc,M),None), (V,rem(start[V]+diff,M),None),
        (P,10*p,None), (B,quotient(start[B],10),qb), (D,quotient(start[D],10),qd),
        # Both possible arrow bytes are nonblank. This segment stops at the
        # next fetch before dispatch. CL proves both concrete directions.
        (GATE,56*is_zero(is_zero(qb)*is_zero(qd))+62,ord("v"))]
    start[GATE] = ord("v")
    return start, writes


def output_contract(valid):
    start = {k:var(n) for k,n in zip((SUM,GAP,U,V),("sum","gap","mod sum","mod gap"))}
    start[GATE], start[VALID] = ord(">"), int(valid)
    s, g, u, v = [start[p] for p in (SUM,GAP,U,V)]
    a, c, h, flag = map(var, ("day A","day C","shifted day","negative flag"))
    counts = list(map(var, ("action","target","distance","connection","direction","save A","save C")))
    ca, cc, distance, conn, direction, sa, sc = counts
    r = var("reduced residue")
    centered = lambda x: rem(rem(x, M)+M, M)
    work = 2*h*(1-2*flag) + 1-flag
    writes = [
        (DAY1,quotient(s+g,2),a), (DAY2,quotient(s-g,2),c),
        (H,a+ORIGIN,h), (FLAG,positive(0-h),flag), (N1,work,ca),
        (H,c+ORIGIN,h), (FLAG,positive(0-h),flag), (N2,work,cc),
        (FLAG,positive(0-g),flag), (DIST,g*(1-2*flag)+1,distance),
        (CONN,ca+cc,conn), (DIRECT,2+positive(0-g)-positive(g),direction),
        (R1,centered(INV2*(u+v)),r), (R1,r+M*is_zero(r),sa),
        (R2,centered(INV2*(u-v)),r), (R2,r+M*is_zero(r),sc),
        (OUTPUT_GATE,56*int(valid)+62,None)]
    return start, writes, counts if valid else [-1]*7


def execute(lines, ip, delta, memory, *, expected=None, inputs=(), scope, end, observe=None,
            nonzero=None, sign_facts=()):
    """Symbolic or concrete execution directly from live source, including move and memory owners."""
    memory = dict(memory)
    stack, output, fetches = [], [], []
    index = cursor = 0
    width, height = max(map(len,lines)), len(lines)
    backed = set(memory)
    need(not sign_facts or scope == "reference", "reference-only sign partition")

    def known_sign(value):
        return next((s for term,s in sign_facts if value == term), None)

    def glyph(point):
        x,y = point
        need(0 <= x < width and 0 <= y < height, "escaped source ray")
        if scope != "reference":
            need((point not in DATA or point in (GATE,OUTPUT_GATE)) and point != SCRATCH
                 and not (y == 49 and x in SLOTS), "fetch intersects a data owner")
        if point in memory:
            return constant(memory[point])
        return lines[y][x] if x < len(lines[y]) else 32

    def pop():
        need(bool(stack), "unexpected stack underflow")
        return stack.pop()

    for tick in range(6800):
        if scope == "loop" and tick and ip == GATE:
            need(tick == PERIOD and delta == ENTRY and not stack, "loop handoff")
            break
        op = chr(glyph(ip))
        before = ip, delta, op, len(stack)
        event = None
        advance = 1
        if ip in (GATE,OUTPUT_GATE):
            need(ip in backed, "unwritten gate fetch")
            fetches.append((tick,ip,op))
        if op in "0123456789abcdef":
            stack.append(int(op,16))
        elif op in "+-*/%`":
            right, left = pop(), pop()
            if op == "+": value = left+right
            elif op == "-": value = left-right
            elif op == "*": value = left*right
            elif op == "/": value = quotient(left,right)
            elif op == "%": value = rem(left,right)
            else:
                difference = left-right
                sign = known_sign(difference)
                value = positive(difference) if sign is None else int(sign > 0)
            stack.append(value)
        elif op == "!":
            value = pop()
            sign = known_sign(value)
            if sign is not None:
                stack.append(int(sign == 0))
            else:
                stack.append(0 if nonzero is not None and value == nonzero else is_zero(value))
        elif op in "pg":
            y,x = constant(pop()),constant(pop())
            point = x,y
            if scope != "reference":
                need(point in DATA, "out-of-scope data access")
            if op == "p":
                value = pop()
                if expected is None:
                    stored = value
                else:
                    need(index < len(expected), "unplanned write")
                    target, want, token = expected[index]
                    need(target == point and value == want, f"write equation {index} at {point}")
                    stored = value if token is None else token
                memory[point] = stored
                backed.add(point)
                index += 1
            else:
                need(point in backed, "read before an input owner or previous physical write")
                stack.append(memory[point])
                value = memory[point]
            event = op,point,value
        elif op in ARROWS:
            delta = ARROWS[op]
        elif op == "x":
            dy,dx = constant(pop()),constant(pop())
            delta = dx,dy
        elif op == "k":
            need(pop() == 1 and glyph((ip[0]+delta[0],ip[1]+delta[1])) == ord("+"), "k target")
            stack.append(pop()+pop())
        elif op == "&":
            need(scope == "reference" and cursor < len(inputs), "unexpected integer read")
            stack.append(inputs[cursor])
            cursor += 1
        elif op in "|_":
            value = pop()
            sign = known_sign(value)
            value = constant(value) if sign is None else sign
            delta = ((0,-1) if value else (0,1)) if op == "|" else ((-1,0) if value else (1,0))
        elif op == "#":
            advance = 2
        elif op == ":":
            value = pop()
            stack.extend((value,value))
        elif op == "$":
            pop()
        elif op == "\\":
            top, below = pop(), pop()
            stack.extend((top,below))
        elif op == ".":
            output.append(pop())
        elif op != "@":
            raise ValueError(f"unsupported {scope} opcode {op!r} at {ip}")
        if observe:
            observe(before,event)
        if op == "@":
            need(scope != "loop" and (scope == "reference" or not stack), "wrong termination")
            break
        dx,dy = delta
        need(delta != (0,0), "stationary IP")
        x,y = ip[0]+dx*advance,ip[1]+dy*advance
        while glyph((x,y)) == 32:
            x,y = x+dx,y+dy
        ip = x,y
    else:
        raise ValueError("source segment exceeded bound")
    need(expected is None or index == len(expected), "missing expected writes")
    need(cursor == len(inputs) and (end is None or ip == end), "terminal location or input consumption")
    return output, fetches, tick, memory


def prove_payload(lines, observe=None):
    initial, equations = loop_contract()
    output, gates, _, _ = execute(lines,GATE,ENTRY,initial,expected=equations,scope="loop",end=GATE)
    need(not output and gates == [(0,GATE,"v")], "loop output or secondary fetch")
    out = []
    for valid, last in ((0,(1530,1860)),(1,(1500,2014))):
        initial, equations, expected_output = output_contract(valid)
        output, gates, tick, _ = execute(lines,GATE,ENTRY,initial,expected=equations,scope="tail",
                                         end=last,observe=observe)
        need(output == expected_output and len(gates) == 2 and gates[0] == (0,GATE,">") and
             gates[1][1:] == (OUTPUT_GATE, "v" if valid else ">"), "emitted fields or gate lineage")
        need(tick == (6133 if valid else 6009), "terminal path length")
        out.append({"valid":bool(valid),"steps_after_east_through_halt":tick,
                    "second_gate_fetch_after_east":gates[1][0],"fields":len(output)})
    # Quotient/remainder is the Euclidean decomposition of two nonnegative integers.
    # This identity proves the inductive rational-free accumulator postcondition.
    q,t,b,d,p,s,r,alpha,beta = map(var,("q","t","digit B","digit D","P","S","R","alpha","beta"))
    for sign, old in ((1,s),(-1,r)):
        addition = p*(alpha*b+sign*beta*d)
        need(old+p*(alpha*(10*q+b)+sign*beta*(10*t+d))
             == old+addition+10*p*(alpha*q+sign*beta*t), "inductive payload identity")
    a,c = var("A"),var("C")
    need((a+c)+(a-c) == 2*a and (a+c)-(a-c) == 2*c and 2*INV2 == M+1, "exact and modular unmixing")
    return out


def compose(lines):
    scanner = Scanner(lines)
    front = scan_fresh(scanner)
    visited, targets, deltas, live = set(), set(), set(), set()
    parents, children = defaultdict(set), defaultdict(set)
    previous = None

    def observe(step, access):
        nonlocal previous
        ip, delta, op, depth = step
        need(not protected(*ip), "post-handoff scanner re-entry")
        visited.add(ip)
        deltas.add(delta)
        if access:
            address = access[1]
            need(not protected(*address), "post-handoff scanner read/write")
            targets.add(address)
        if ip in (GATE,OUTPUT_GATE):
            live.add((ip,op))
        if previous is not None:
            parents[ip].add(previous)
            children[previous].add(ip)
        previous = None if op == "@" else ip

    joins, _ = prove_join(lines)
    for walk in joins:
        previous = None
        need(walk[0][0][:3] == (HANDOFF,(-241,-41),">"), "scanner-to-arithmetic join")
        for step, access in walk:
            observe(step,access)
    moves={}
    for key in product(range(3),range(2),range(3),range(2)):
        previous = None
        walk, _, _ = walk_initial_gate(lines,key,moves)
        expected = "v" if key[1] or key[3] else ">"
        need(walk[0][0]==joins[key[0]][-1][0] and walk[-1][0]==(GATE,ENTRY,expected,0),
             "prefix-to-iteration state")
        for step, access in walk:
            observe(step,access)
    for z,w in product((False,True),repeat=2):
        previous = None
        walk=walk_loop(lines,z,w)
        need(walk[0][0]==(GATE,ENTRY,"v",0) and walk[-1][0]==(GATE,ENTRY,">" if z and w else "v",0),
             "iteration-to-iteration state")
        for step, access in walk:
            observe(step,access)
    previous = None
    tails=prove_payload(lines,observe)
    need(live=={(gate,op) for gate in (GATE,OUTPUT_GATE) for op in (">","v")}, "both live directions at both gates")
    all_sites=scanner.visited | visited
    need(not all_sites.intersection(SITES), "old scanner sites executed on a later entry")
    original={(x,y) for y,line in enumerate(lines) for x,v in enumerate(line) if v!=32}
    writes_and_reads=targets | scanner.put_cells
    need(not original.intersection(writes_and_reads), "a data write could replace a nonblank source opcode")
    need(all_sites & writes_and_reads == {GATE,OUTPUT_GATE}, "other writable cells execute as code")
    need(set(FRONTIER)-all_sites==SITES and not writes_and_reads.intersection(FRONTIER),
         "historical fifteen source-byte classification")
    # Demonstrate that all twelve positive classifications occur on one valid
    # canonical day pair, using the exact seven bytes and EOF (no final LF).
    shown=set()
    sc=Scanner(lines)
    def record(model):
        if model[0] in FRONTIER:
            need(model[2]==ord(FRONTIER[model[0]]),"original frontier glyph identity")
            shown.add(model[0])
    mem=base(sc,record)
    for byte in (*b"0 0 0 0",None):
        stop, parsed, _ = sc.segment(READ,mem,byte,record)
    need(stop=="handoff" and parsed==[0,0,0,0] and shown==set(FRONTIER)-SITES,"canonical frontier witness")
    inventory={}
    for op in "xjpg{}ukw[]r_|t()?":
        candidates={(x,y) for y,line in enumerate(lines) for x,v in enumerate(line) if v==ord(op)}
        missing=sorted(candidates-all_sites)
        inventory[op]={"in_original":len(candidates),"reached":len(candidates)-len(missing),"unreached":missing}
    forks={p for p,v in children.items() if len(v)>1}
    joins={p for p,v in parents.items() if len(v)>1}
    return tails,{"scanner_transitions":front["transitions"],"fresh_visited_positions":len(all_sites),
                  "distinct_arithmetic_positions":len(visited),"arithmetic_memory_targets":sorted(targets),
                  "arithmetic_incoming_directions":len(deltas),"source_opcode_inventory":inventory,
                  "source_nonblank_count":len(original),"original_nonblank_fetched":len(original & all_sites),
                  "original_nonblank_unreachable":len(original-all_sites),"executed_writable_cells":sorted(all_sites & writes_and_reads),
                  "arithmetic_fork_positions":sorted(forks),"arithmetic_join_positions":sorted(joins),
                  "arithmetic_dual_positions":sorted(forks & joins),
                  "historical_fifteen_reached_on_30203020302030_hex":sorted(shown),
                  "no_post_handoff_scanner_execution_or_access":True,"unreached_scanner_frontier":sorted(SITES)}


def verify_frontier(archives, source):
    original, *native = archives
    need(sha256(original.read_bytes())==QA30B_SHA,"QA30B historical candidate archive pin")
    with ZipFile(original) as pack:
        need(pack.testzip() is None,"QA30B CRC")
        old=json.loads(pack.read("qa30b_live_source_frontier.json"))
    snapshots=[s for row in old["records"] for s in row["live_state_snapshots"]]
    need(old["production_git_blob"]==PIN and len(snapshots)==22,"QA30B source/22 observations")
    for s in snapshots:
        need({tuple(d["coordinate"]):chr(d["static_original_value"]) for d in
              s["fetched_source_candidate_live_values"]}==FRONTIER,"original candidate manifest")
    evidence=[]
    for i,path in enumerate(native):
        rows, receipt, meta = read_archive(path,i,source)
        hits={}
        for row in rows:
            ip=tuple(row["ip"])
            if row["pg"]:
                need(tuple(row["pg"]["target"]) not in FRONTIER,"Native candidate memory access")
            if ip in FRONTIER:
                need(not row["string"] and row["op"]==ord(FRONTIER[ip]),"Native source-byte identity")
                hits.setdefault(ip,row["t"])
        need(set(hits)==set(FRONTIER)-SITES and receipt["raw_hex"]==f"1 {i} 0 100".encode().hex(),
             "archived original frontier coverage and no-LF input")
        evidence.append({"artifact":meta["artifact"],"zip_sha256":meta["sha256"],"raw_hex":receipt["raw_hex"],
                         "first_native_contacts":[[*ip,tick] for ip,tick in sorted(hits.items())]})
    return evidence


def check_references(counts, save):
    # The seven-field protocol calls work_counts only on valid inputs.
    # Compute its complete polynomial output for all four sign combinations.
    for sa in (0,1):
        for sc in (0,1):
            b,d=var("b"),var("d")
            a,c=(1-2*sa)*b,(1-2*sc)*d
            def count(day):
                h=day+ORIGIN
                neg=positive(0-h)
                return 2*h*(1-2*neg)+1-neg
            ca,cc=count(a),count(c)
            diff=c-a
            want=[ca,cc,diff*(1-2*positive(0-diff))+1,ca+cc,2+positive(c-a)-positive(a-c)]
            out,_,_,_=execute(counts,(0,0),(1,0),{},scope="reference",end=None,inputs=(sa,b,sc,d))
            need(out == want, "normative work_counts equations")
    mag=var("positive magnitude")
    for flag,v,want in ((0,mag,1+rem(mag+M-1,M)),(0,0,M),
                        (1,mag,M-rem(mag,M)),(1,0,-1)):
        out,_,_,_=execute(save,(0,0),(1,0),{},scope="reference",end=None,inputs=(flag,v),
                          nonzero=mag if v == mag else None)
        need(out == [want], "normative SAVE equations")


def check_mutations(lines):
    cases = [((860,205),"%","+", "write equation 6 at (61, 1706)"),
             ((1149,385),"-","+", "write equation 9 at (89, 1712)"),
             ((1240,841),"%","+", "write equation 12 at (103, 1715)"),
             ((1474,101),"1","2", "k target"),
             ((1503,1860),"1","2", "emitted fields or gate lineage")]
    for (x,y),old,new,why in cases:
        changed=lines.copy()
        need(changed[y][x]==ord(old),"hostile mutation anchor")
        changed[y]=changed[y][:x]+new.encode()+changed[y][x+1:]
        try:
            prove_payload(changed)
        except ValueError as error:
            need(str(error)==why, f"unexpected mutation rejection {(x,y)}: {error}")
        else:
            raise ValueError("accepted detached source mutation")
    return cases


def calibrate(path, lines, counts, save):
    need(sha256(path.read_bytes()) == ARCHIVE_SHA, "geometry archive pin")
    cases = []
    with ZipFile(path) as archive:
        need(archive.testzip() is None,"geometry CRC")
        for c in json.loads(archive.read("diverse_manifest.json"))["cases"]:
            fields=c["fields"]
            sa,b,sc,d=fields
            valid = sa in (0,1) and sc in (0,1) and b>=sa and d>=sc
            need(type(c["valid"]) is bool and c["valid"] == valid, "independent input family")
            raw=archive.read(c["trace_file"])
            need(sha256(raw)==c["trace_sha256"], "native trace pin")
            it=step_groups(raw)
            row,events=next(pair for pair in it if pair[0][2:4]==GATE)
            first=row[0]
            state={B:b,D:d,S1:1-2*sa,S2:1-2*sc,P:1,SUM:0,GAP:0,U:0,V:0,VALID:int(c["valid"]),
                   GATE:ord("v" if b or d else ">")}
            def observe(step, access):
                nonlocal row,events
                ip,delta,op,depth=step
                need(row[1:]==(1,*ip,*delta,ord(op),depth), "Native payload step")
                if access:
                    kind,point,value=access
                    tags=[b"WRITE_BEFORE",b"WRITE_AFTER"] if kind=="p" else [b"READ_BEFORE",b"READ_AFTER"]
                    need([k for k,_ in events]==tags and all(e[:2]==point for _,e in events)
                         and events[-1][1][-1]==value,"Native payload memory value")
                else:
                    need(not events,"unexpected Native payload memory event")
                if op != "@":
                    row,events=next(it)
            while state[GATE]==ord("v"):
                _,_,_,state=execute(lines,GATE,ENTRY,state,scope="loop",end=GATE,observe=observe)
            output,_,_,_=execute(lines,GATE,ENTRY,state,scope="tail",end=None,observe=observe)
            ref_output = []
            if valid:
                for program, args in ((counts, fields), (save, [sa,b]), (save, [sc,d])):
                    part, _, _, _ = execute(program,(0,0),(1,0),{},scope="reference",end=None,inputs=args)
                    ref_output.extend(part)
            else:
                ref_output = [-1]*7
            need(next(it,None) is None and output==ref_output==list(map(int,c["output"])),
                 "physical Native and executed normative Befunge seven-field output")
            cases.append({"case":c["case"],"steps":row[0]-first+1,"valid":c["valid"],"output":output})
    need(len({r["case"] for r in cases})==len(cases)==17,"17 complete tails")
    return cases


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source",type=Path)
    ap.add_argument("work_counts",type=Path)
    ap.add_argument("save",type=Path)
    ap.add_argument("--geometry",type=Path)
    ap.add_argument("--frontier",type=Path,nargs=4,metavar=("QA30B","CB","CD","CF"))
    ap.add_argument("--output",type=Path,required=True)
    args=ap.parse_args()
    blobs=[p.read_bytes() for p in (args.source,args.work_counts,args.save)]
    need([git_blob(b) for b in blobs]==[PIN,COUNT_PIN,SAVE_PIN],"source or reference pin")
    lines,counts,save=[b.splitlines() for b in blobs]
    tails,geometry=compose(lines)
    check_references(counts,save)
    hostile=check_mutations(lines)
    cases=calibrate(args.geometry,lines,counts,save) if args.geometry else []
    frontier=verify_frontier(args.frontier,blobs[0]) if args.frontier else []
    result={"source_git_blob":PIN,"normative_counts":COUNT_PIN,"normative_save":SAVE_PIN,
            "modulus":M,"origin_offset":ORIGIN,"inverse_two":INV2,"tail_paths":tails,"native_cases":cases,
            "composed_geometry":geometry,"hostile_mutations":hostile,
            "archived_native_frontier":frontier,
            "native_steps_from_first_gate":sum(c["steps"] for c in cases),"stage1_accepted":False}
    args.output.write_text(json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("QA31CM PASS | shared exact and modular equations, both output paths, two original references |",
          result["native_steps_from_first_gate"],"Native STEPs")


if __name__=="__main__":
    main()
