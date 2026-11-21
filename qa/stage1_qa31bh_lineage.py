"""QA31BH. Forward tagged replay and independent backward stack-slot queries."""
from copy import deepcopy
from functools import lru_cache
import sys

sys.setrecursionlimit(max(10000,sys.getrecursionlimit()))
LITERALS = "0123456789abcdef"
GATES = frozenset("pgxj_|")
NO_STACK = frozenset(" <>^v#@z")


class AuditError(ValueError):
    pass


def require(ok, condition):
    if not ok:
        raise AuditError(condition)


def literal(value):
    return (value,value,value,False)


def opcode(ev):
    require(not ev["string"], "stringmode outside checked grammar")
    return chr(ev["op"])


def forward_calc(op, a, b):
    if op == "+": return a+b
    if op == "-": return a-b
    if op == "*": return a*b
    if op == chr(96): return int(a>b)
    if b == 0: return 0
    require(a*b >= 0 or a % b == 0, "ambiguous negative nonintegral division")
    if op == "/": return a//b
    if op == "%": return a%b
    raise AuditError("unsupported arithmetic")


def forward(rows):
    root = rows[0]
    stack = [literal(v) for v in root["post"]]
    stack[-1] = (stack[-1][0],0,1,True)
    states = []
    for ev in rows[1:]:
        op = opcode(ev)
        if op in LITERALS or op in NO_STACK:
            n = 0
        elif op in ":$!j_|.,":
            n = 1
        elif op in "+-*/%gx\\" or op == chr(96):
            n = 2
        elif op == "p":
            n = 3
        else:
            raise AuditError(f"unsupported signed opcode {op!r} at {ev['t']}")
        require([s[0] for s in stack] == ev["pre"] and len(stack) >= n, "forward pre")
        args = stack[-n:] if n else []
        if n:
            del stack[-n:]
        if op in LITERALS:
            stack.append(literal(int(op,16)))
        elif op in "+-*/%" or op == chr(96):
            a,b = args
            stack.append((*[forward_calc(op,a[i],b[i]) for i in range(3)],a[3] or b[3]))
        elif op == "!":
            a = args[0]
            stack.append((int(not a[0]),int(not a[1]),int(not a[2]),a[3]))
        elif op == "g":
            # Every later g result is fixed to its authenticated physical receipt.
            stack.append(literal(ev["post"][-1]))
        elif op == ":":
            stack.extend([args[0],args[0]])
        elif op == "\\":
            stack.extend(reversed(args))
        require([s[0] for s in stack] == ev["post"], "forward post")
        states.append((args,tuple(stack)))
    return states


def backward(rows):
    # Index post-stack slots by (record, depth from bottom). A demand follows
    # unchanged buried slots backward until it finds the instruction that made one.
    # The trace's measured stack depths determine the popped interval.
    @lru_cache(maxsize=None)
    def slot(i, j):
        e = rows[i]
        require(0 <= j < len(e["post"]), "reverse slot")
        if i == 0:
            v = e["post"][j]
            return (v,0,1,True) if j+1 == len(e["post"]) else (v,v,v,False)
        code = e["op"]
        added = pushes(code)
        base = len(e["post"])-added
        if j < base:
            return slot(i-1,j)
        if code in (58,92):  # duplicate or swap
            src = -1 if code == 58 or j == base else -2
            return slot(i-1,len(e["pre"])+src)
        if code == 103:  # g uses the fixed signed receipt
            v = e["post"][-1]
            return (v,v,v,False)
        if 48 <= code <= 57 or 97 <= code <= 102:
            v = code-48 if code < 58 else code-87
            return (v,v,v,False)
        b = slot(i-1,len(e["pre"])-1)
        if code == 33:
            return (int(b[0]==0),int(b[1]==0),int(b[2]==0),b[3])
        a = slot(i-1,len(e["pre"])-2)
        def evaluate(x,y):
            if code == 43: return x+y
            if code == 45: return x-y
            if code == 42: return x*y
            if code == 96: return int(x>y)
            if y == 0: return 0
            q = (abs(x)//abs(y)) * (-1 if (x<0)!=(y<0) else 1)
            require(code in (47,37),"reverse arithmetic")
            return q if code == 47 else x-y*q
        return (*[evaluate(a[p],b[p]) for p in range(3)],a[3] or b[3])

    def pushes(code):
        if code in (58,92): return 2
        if 48 <= code <= 57 or 97 <= code <= 102 or code in (33,37,42,43,45,47,96,103):
            return 1
        require(code in (32,35,36,44,46,60,62,64,94,95,106,112,118,120,122,124),
                "reverse unknown opcode")
        return 0

    try:
        for i in range(1,len(rows)):
            e = rows[i]
            keep = len(e["post"])-pushes(e["op"])
            require(0 <= keep <= len(e["pre"]), "reverse arity")
            args = [slot(i-1,j) for j in range(keep,len(e["pre"]))]
            result = tuple(slot(i,j) for j in range(len(e["post"])))
            require([s[0] for s in result] == e["post"], "reverse post")
            yield args,result
    finally:
        slot.cache_clear()


def project(words, index):
    return [w[index] for w in words]


def destination(e, args):
    op = opcode(e)
    if op == "x":
        dx,dy = args
    elif op == "j":
        dx,dy = e["delta"]
        dx *= args[0]+1
        dy *= args[0]+1
    elif op == "|":
        dx,dy = 0, (1 if args[0]==0 else -1)
    elif op == "_":
        dx,dy = (1 if args[0]==0 else -1),0
    else:
        return None
    return [e["ip"][0]+dx,e["ip"][1]+dy]


def signed_route(e, args):
    op = opcode(e)
    raw = destination(e,args)
    if raw is None:
        return
    # These audited control sites must land directly without a wrap/blank skip.
    require(raw == e["next"],"signed branch target")
    if op == "x":
        require(args == e["next_delta"],"signed x delta")
    if op == "j":
        require(e["delta"] == e["next_delta"],"signed j delta")


def same_state(a,b):
    require(a == b, "independent stack lineage disagreement")


def analyze(rows, boundary_t):
    root = rows[0]
    require(root["op"] == 103 and not root["string"] and root["ip"] == [174,195]
            and root["pre"][-2:] == [43,1702] and
            root["post"] == root["pre"][:-2]+[root["post"][-1]], "second g43")
    require(root["t"] < boundary_t <= rows[-1]["t"] <= boundary_t+512, "BH bounds")
    for a,b in zip(rows,rows[1:]):
        require(b["t"] == a["t"]+1, "tick")
        require((a["next"],a["next_delta"],a["post"]) == (b["ip"],b["delta"],b["pre"]),
                "signed step continuity")
    first = first_gate = vanished = divergence = None
    gates = []
    boundary_slot = None
    result = None
    for e,fw,rv in zip(rows[1:],forward(rows),backward(rows),strict=True):
        same_state(fw,rv)
        args,result = fw
        op = opcode(e)
        actual,zero,one,deps = (project(args,i) for i in range(4))
        signed_route(e,actual)
        cf_ok = divergence is None
        actual_target = destination(e,actual)
        zero_target = destination(e,zero) if op in "xj_|" else None
        one_target = destination(e,one) if op in "xj_|" else None
        if op in ("p","g"):
            left_trace = zero[-2:] != actual[-2:] or one[-2:] != actual[-2:]
        else:
            left_trace = actual_target is not None and (
                zero_target != actual_target or one_target != actual_target)
        if left_trace and cf_ok:
            divergence = {"t":e["t"],"op":op,"ip":e["ip"]}
        if e["t"] == boundary_t:
            slots = [i for i,v in enumerate(result) if v[3]]
            require(len(slots) == 1 and result[slots[0]][1] != result[slots[0]][2],
                    "QA31BG live boundary value")
            require(divergence is None, "changed path before boundary")
            boundary_slot = slots[0]
        if e["t"] <= boundary_t:
            continue
        observation = dict(t=e["t"],ip=e["ip"],op=op,operands=actual,dependent=deps,
                           conditional_0=zero if cf_ok else None,
                           conditional_1=one if cf_ok else None)
        if first is None and any(deps):
            first = dict(observation)
        if vanished is None and not any(v[3] for v in result):
            vanished = {"t":e["t"],"ip":e["ip"],"op":op}
        if op in GATES:
            if op in ("x","j","_","|"):
                changed = zero_target != one_target
            else:
                changed = zero != one
            observation.update(conditional_changed=changed if cf_ok else None,
                physical_next=e["next"],physical_next_delta=e["next_delta"],
                physical_g_value=e["post"][-1] if op=="g" else None,
                direct_target_0=zero_target if cf_ok else None, direct_target_1=one_target if cf_ok else None)
            gates.append(observation)
            if first_gate is None and any(deps):
                first_gate = dict(observation)
    require(result is not None and boundary_slot is not None, "missing boundary")
    return dict(boundary_slot=boundary_slot,first_consumer=first,first_dependent_gate=first_gate,
                stack_lineage_extinguished=vanished,divergence=divergence,gates=gates,
                final_dependent_slots=[i for i,v in enumerate(result) if v[3]])


def negative_controls(rows, bound, window):
    """Record specific rejections; never count an unexpected exception as success."""
    x = next(i for i,e in enumerate(rows[:-1]) if e["op"] == 120 and e["t"] > bound)
    j = next(i for i,e in enumerate(rows) if e["t"] == bound)
    controls = []
    def test(label,tag,edit):
        sample = deepcopy(rows)
        edit(sample)
        require(sample != rows,"noop hostile mutation")
        try:
            analyze(sample,bound)
        except AuditError as error:
            require(str(error) == tag, "unexpected rejection "+label+": "+str(error))
        else:
            raise AuditError("accepted corrupt evidence "+label)
        controls.append(label)
    test("root-opcode","second g43",lambda r:r[0].update(op=112))
    test("root-ip","second g43",lambda r:r[0].update(ip=[175,195]))
    test("root-address","second g43",lambda r:r[0]["pre"].__setitem__(-1,1703))
    test("root-string-mode","second g43",lambda r:r[0].update(string=True))
    test("boundary-tick","tick",lambda r:r[j].update(t=r[j]["t"]+1))
    test("boundary-stack","signed step continuity",lambda r:r[j]["post"].append(123))
    test("extension-input-direction","signed step continuity",lambda r:r[j+1].update(delta=[88,99]))
    test("physical-next-ip","signed step continuity",lambda r:r[x].update(next=[-10000,-10001]))
    def linked_ip(r):
        r[x]["next"] = [-10000,-10001]
        r[x+1]["ip"] = r[x]["next"][:]
    def linked_delta(r):
        r[x]["next_delta"] = [-10000,-10001]
        r[x+1]["delta"] = r[x]["next_delta"][:]
    test("coherent-link-wrong-x-displacement","signed branch target",linked_ip)
    test("coherent-link-wrong-x-direction","signed x delta",linked_delta)
    def wrong_literal(r):
        i = next(i for i in range(j+1,len(r)-1) if chr(r[i]["op"]) in LITERALS)
        r[i]["op"] = 49 if r[i]["op"] != 49 else 50
    test("literal-with-original-stacks","forward post",wrong_literal)
    def linked_stack(r):
        i = next(i for i in range(j+1,len(r)-1) if chr(r[i]["op"]) in LITERALS)
        r[i]["post"][-1] += 5
        r[i+1]["pre"][-1] += 5
    test("coherent-link-wrong-arithmetic-stack","forward post",linked_stack)
    # Exercise the same independent comparison used on every real gate.
    first = next(g for g in window["gates"] if g["op"]=="x")
    words = list(zip(first["operands"],first["conditional_0"],first["conditional_1"],first["dependent"]))
    for field,title in ((0,"observed-operand"),(1,"zero-case"),(2,"one-case"),(3,"taint-bit")):
        bad = list(words)
        v = list(bad[0])
        v[field] = not v[field] if field==3 else v[field]+1
        bad[0] = tuple(v)
        require(bad != words,"noop oracle control")
        try: same_state(bad,words)
        except AuditError as error:
            require(str(error)=="independent stack lineage disagreement","unexpected crosscheck rejection")
        else: raise AuditError("forged oracle agreed")
        controls.append("independent-"+title)
    return controls
