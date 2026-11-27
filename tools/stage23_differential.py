#!/usr/bin/env python3
"""Stage23 QA-only instrumented op40, exact signed-64 math, no stage acceptance."""
import hashlib
import itertools
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time
import stage23_measure as measure

E = Path("evidence/stage23_differential")
MIN, MAX = -(1 << 63), (1 << 63) - 1
EPOCH = -15055671
M = (1 << 127) - 1
PERMS = tuple(itertools.permutations(range(1, 7)))
RT = measure.RT

def save(x):
    assert x > 0
    r = x % M
    return r or M

def stones():
    table = [(17, 29, 43, 71, 101)]
    for i in range(2, 47):
        old = table[-1]
        table.append(tuple(save(old[j]**2 + (3,5,7,11,13)[j]*old[(j+1)%5] +
                                (i if j == 0 else old[j-1])) for j in range(5)))
    return table

def solve(c, t, st):
    assert MIN <= c <= MAX and MIN <= t <= MAX
    def count(x):
        delta = x-EPOCH
        return 2*abs(delta) + int(delta >= 0)
    C,T = count(c),count(t)
    counts = [C,T,abs(t-c)+1,C+T,2+int(t>c)-int(t<c)]
    hidden = []
    for i in range(1,8):
        weights=(2*i+1,3*i+1,4*i+2,4*i+4)
        v=save(C+sum(a*b for a,b in zip(weights,counts[1:]))+sum(st[i-1]))
        for j in range(1,8):
            v=save(v*v+3*v+st[i-1][(j-1)%5]+j)
        hidden.append(v)
    prime=(3,5,7,11,13,17,19,23,29,31,37,41,43,47)
    timeline={-i:hidden[i-1] for i in range(1,8)}
    visible=[]
    for i in range(46):
        a,b,d=(timeline[i-k] for k in (1,3,7))
        v=save(sum(x*y for x,y in zip(st[i],counts))+a+3*b+5*d+i+1)
        for j in range(11):
            j0,j1,j2,j3=prime[j:j+4]
            v=save(v*v+j0*v+j1*a+j2*b+j3*d+st[i][j%5])
        timeline[i]=v
        visible.append(v)
    initial=[save(C+i*T+sum(counts[2:])+p*p+i)
             for i,p in enumerate((17,19,23,29,31,37),1)]
    def transition(old, order, formula):
        # Iterate by permutation position, not by ID; scatter after all six calculations.
        rotated=[old[i-1] for i in order]
        new=[None]*6
        for p,bid in enumerate(order):
            new[bid-1]=formula(p,rotated[p],rotated[(p-1)%6],rotated[(p+1)%6])
        return new
    bowls=initial[:]
    for i,v in enumerate(visible,1):
        order=PERMS[(v-1)%720]
        def drop(p,x,l,r):
            aux=save(v*v+x*st[i-1][p]+i*(2*(p+1)+1)) if p<3 else 0
            return save(x*x+2*l+3*r+aux+v+st[i-1][p%5]+5*l*r+i*(p+1))
        bowls=transition(bowls,order,drop)
    order46=list(order)
    after46=bowls[:]
    for i in range(1,13):
        v=save(sum(bowls)+149*i)
        order=PERMS[(v-1)%720]
        bowls=transition(bowls,order,lambda p,x,l,r: save(x*x+3*l+5*r+v+i+(p+1)**2+7*l*r))
    return dict(pair=[c,t],counts=counts,hidden=hidden,visible=visible,initial=initial,
                after46=after46,order46=order46,finalBowls=bowls,returnOrder=order46[:])

def oracle():
    st=stones()
    baseline=json.loads(subprocess.check_output(
        ["node","tools/preintegration_op57_design_oracle.mjs"],timeout=30))
    assert st==[tuple(map(int,x)) for x in baseline["stones"]]
    for old in baseline["records"]:
        row=solve(*map(int,old["pair"]),st)
        for key,values in row.items():
            assert values==list(map(int,old[key])),(key,row["pair"])
    pairs=[(EPOCH,EPOCH),(MIN,MAX),(MAX,MIN),(MIN,MIN),(MAX,MAX),
           (MIN,MIN+1),(MIN+1,MIN),(MAX-1,MAX),(MAX,MAX-1)]
    rows=[solve(c,t,st) for c,t in pairs]
    anchors=[108913163550045184146698385533806010700,
             117012097572828239447606168473050643501,
             122587107707247212276635976649694797883,
             63932677393771579602414829294998841563]
    assert [r["finalBowls"][0] for r in rows[1:5]]==anchors
    assert [r["returnOrder"] for r in rows[1:5]]==[
        [6,1,2,3,4,5],[1,6,4,5,3,2],[3,5,1,4,2,6],[2,4,1,5,6,3]]
    assert rows[1]["counts"]==[18446744073679440274,18446744073739662957,
                              18446744073709551616,36893488147419103231,3]
    return st,rows

def instrument(src, st, row):
    # Only alter an in-memory copy of op40. No extra heap allocations or scratch registers.
    marker='z;40=~["E_OP57_LAYOUT"0 0/]?'
    assert src.count(marker)==1
    before,tail=src.split(marker)
    count=checks=0
    def eq(expr,value,tag):
        nonlocal checks
        checks+=1
        return expr+measure.lit(value)+'-0=~["S23_DIFF_'+tag+'"0 0/]?'
    def scalar(expr,value,tag,big=True):
        nonlocal count
        count+=1
        if not big:
            return [eq(expr,value,tag)]
        return [eq(expr+str(i)+'+g;!',v,tag+'_CELL_'+str(i))
                for i,v in enumerate(measure.limbs(value))]
    def table(handle,values,tag,direct=False):
        out=[eq(handle+'g;!',len(values),tag+'_LENGTH')]
        for i,value in enumerate(values,1):
            out+=scalar(handle+str(i)+'+g;!',value,tag+'_'+str(i),not direct)
        return out
    def insert(anchor,lines):
        nonlocal tail
        assert tail.count(anchor)==1,anchor
        tail=tail.replace(anchor,anchor+'\n  '+'\n  '.join(lines),1)
    lines=[eq('y;g;!',5,'COUNTS_LENGTH')]
    for i,value in enumerate(row['counts'],1):
        lines+=scalar(f'y;{i}+g;!',value,f'COUNTS_{i}',i!=5)
    insert('x;f;!y:',lines)
    lines=[eq('w;g;!',46,'STONES_LENGTH')]
    for i,values in enumerate(st,1):
        lines+=table(f'w;{i}+g;!',values,f'STONES_{i}')
    insert('z;b:0a;!b;24h;!!w:',lines)
    insert('z;b:y;a;!w;a;!b;29h;!!v:',table('v;',row['hidden'],'HIDDEN'))
    insert('z;b:y;a;!w;a;!v;a;!b;31h;!!u:',table('u;',row['visible'],'VISIBLE'))
    insert('z;b:y;a;!b;37h;!!t:',table('t;',row['initial'],'INITIAL'))
    insert('s;1+g;!p:s;2+g;!o:',table('p;',row['after46'],'AFTER46')+
           table('o;',row['order46'],'ORDER46',True))
    insert('z;b:1a;!p;a;!b;39h;!!n:',table('n;',row['finalBowls'],'FINAL'))
    assert count==312
    # Existing external fixture independently checks the returned six order cells,
    # final bigint raw cells, frame, original input cells and freshness/alias.
    return before+marker+tail,checks,count+6

def main():
    E.mkdir(parents=True,exist_ok=True)
    pin=os.environ.get('SOURCE_PIN') or subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
    assert subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()==pin
    st,rows=oracle()
    (E/'boundary_oracle.json').write_text(json.dumps(dict(stones=st,records=rows),indent=2)+'\n')
    src=Path('src/monster_bootstrap.false').read_text()
    instr,checks,scalar_count=instrument(src,st,rows[0])
    assert scalar_count==318
    body,outer_checks=measure.fixture(rows[0])
    program=Path('src/bigint.false').read_bytes()+b'\n'+instr.encode()+b'\n'+body.encode()
    path=E/'epoch_instrumented.false'
    path.write_bytes(program)
    # QA program and each original source blob are archived separately.
    sources={}
    for name in ('src/bigint.false','src/monster_bootstrap.false','test/normative_reference.false',
                 'tools/stage23_measure.py','tools/preintegration_op57_design_oracle.mjs',
                 'tools/stage23_differential.py','.github/workflows/false-arabic-stage23-differential.yml'):
        p=Path(name)
        if not p.exists():
            assert name.endswith('.yml') and '--prepare-only' in os.sys.argv
            continue
        data=p.read_bytes()
        assert data==subprocess.check_output(['git','show',pin+':'+name])
        dest=E/'source'/name
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(data)
        sources[name]=measure.sha(data)
    report=dict(project_id='PC-BRANCH-FALSE-ARABIC',source_pin=pin,runtime_pin=RT,
                source_sha256=sources,scalar_checkpoints=scalar_count,
                inline_cell_shape_assertions=checks,outer_assertions=outer_checks,
                math_boundary_pairs=8,overlap_oracle_pairs=48,
                program_sha256=measure.sha(program),stage_acceptance=False,
                integrated_intermediate_pass=False,boundary_native=False,
                replay_native=False,malformed_native=False,mutants_native=False)
    if '--prepare-only' in os.sys.argv:
        (E/'receipt.json').write_text(json.dumps(report,indent=2)+'\n')
        print(json.dumps(report))
        return
    assert os.environ['RUNTIME_PIN']==RT
    assert (E/'runtime_observed.txt').read_text().strip()==RT
    measure.E=E
    measure.framing_preflight()
    # GNU time measures this single interpreter process; AS and watchdog inherited.
    cmd=['/usr/bin/time','-v','-o',str(E/'time.txt'),'upstream/false_int','-e',str(path)]
    started=time.monotonic()
    with subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                          start_new_session=True,preexec_fn=measure.limits) as p:
        try:
            out,err=p.communicate(timeout=600)
            code=p.returncode
        except subprocess.TimeoutExpired:
            os.killpg(p.pid,signal.SIGKILL)
            out,err=p.communicate()
            code=124
    elapsed=time.monotonic()-started
    (E/'stdout.txt').write_bytes(out)
    (E/'stderr.txt').write_bytes(err)
    (E/'exit_code.txt').write_text(str(code)+'\n')
    heap=measure.parse_heap(out)
    timing=(E/'time.txt').read_text() if (E/'time.txt').exists() else ''
    m=re.search(r'Maximum resident set size \(kbytes\):\s*(\d+)',timing)
    rss=int(m.group(1)) if m else None
    passed=code==0 and not err and heap is not None and heap>0 and rss is not None and elapsed<=600
    report.update(exit_code=code,elapsed_seconds=round(elapsed,3),heap_cells=heap,
                  peak_rss_kib=rss,address_space_limit_bytes=measure.LIMIT,timeout_seconds=600,
                  stdout_sha256=measure.sha(out),stderr_sha256=measure.sha(err),
                  integrated_intermediate_pass=passed)
    (E/'receipt.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))
    if not passed:
        raise SystemExit(1)

if __name__=='__main__':
    main()
