"""Independent Python integer oracle for Stage10, README A/D/E/F.
No Pascal imports or external implementation fixtures. ASCII TSV, exact comparisons.
"""
import sys
from pathlib import Path
M = (1 << 127) - 1
F = -15055671
COEFF = [(3,4,6,8),(5,7,10,12),(7,10,14,16),(9,13,18,20),
         (11,16,22,24),(13,19,26,28),(15,22,30,32)]
ANCHOR = [119390830530032782664128530203002080344,
          11877236279154673426874867061566696749,
          24217814924229232987463457533828175476,
          166629231917547214614573522551290204247,
          81202913407267092008896220686064041568,
          73551520026920072430116213847585486272,
          6164285870955721082771365327359496898]
DAYS = [F-1,F,F+1,0,1,-278522,F-M,F+M,F+(1<<255),F-(1<<255)]
def save(x):
    return (x-1)%M+1
def tag(d):
    return 2*(F-d) if d<F else 2*(d-F)+1
def stone_rows():
    rows = [(17,29,43,71,101)]
    for i in range(2,8):
        a,b,c,d,e = rows[-1]
        rows.append(tuple(map(save,(a*a+3*b+i,b*b+5*c+a,c*c+7*d+b,
                                    d*d+11*e+c,e*e+13*a+d))))
    return rows
def generate():
    rows = stone_rows()
    header = ['c','t']+[f'k{k}_r{r}' for k in range(1,8) for r in range(8)]+[f'p{p}' for p in range(-6,1)]
    normative, seeded = [header], [header]
    for c in DAYS:
        for t in DAYS:
            a,b = tag(c),tag(t)
            d,s,q = abs(t-c)+1,a+b,1 if t<c else 2 if t==c else 3
            trace, hidden = [],[]
            for row,(ka,kb,kc,kd) in zip(rows,COEFF):
                x = save(a+ka*b+kb*d+kc*s+kd*q+sum(row))
                trace.append(x)
                for r,stone in enumerate((*row,*row[:2]),1):
                    x = save(x*(x+3)+stone+r)
                    trace.append(x)
                hidden.append(x)
            if c==F and t==F and hidden!=ANCHOR:
                raise ValueError('canonical hidden anchor')
            if not all(1<=x<=M for x in trace):
                raise ValueError('SAVE range')
            normative.append([c,t,*trace,*reversed(hidden)])
            seeded.append([c,t,*trace,*hidden])
    return normative,seeded
def encode(rows):
    return ''.join('\t'.join(map(str,row))+'\n' for row in rows).encode('ascii')
def main():
    if len(sys.argv) not in (3,4):
        raise SystemExit('usage: oracle.py generate EXPECTED | verify EXPECTED OBSERVED')
    mode,path = sys.argv[1:3]
    normative,seeded = generate()
    expected=encode(normative)
    if mode=='generate' and len(sys.argv)==3:
        Path(path).write_bytes(expected)
        return
    if mode!='verify' or len(sys.argv)!=4:
        raise SystemExit('invalid mode')
    if Path(path).read_bytes()!=expected:
        raise ValueError('expected artifact mismatch')
    raw=Path(sys.argv[3]).read_bytes()
    if raw!=encode(seeded):
        raise ValueError('observed output differs from exact seeded-order prediction')
    trace_match=slot_match=slot_red=0
    print('c\tt\tposition\texpected\tobserved\tstatus')
    for n,o in zip(normative[1:],seeded[1:]):
        if n[:58]!=o[:58]:
            raise ValueError('unexpected trace mismatch')
        trace_match+=56
        for p,e,v in zip(range(-6,1),n[58:],o[58:]):
            status='MATCH' if e==v else 'SEEDED_RED'
            if e==v: slot_match+=1
            else: slot_red+=1
            print(n[0],n[1],p,e,v,status,sep='\t')
    if (trace_match,slot_match,slot_red)!=(5600,100,600):
        raise ValueError(f'unexpected counts {(trace_match,slot_match,slot_red)}')
    print('100 pairs; 5600 trace MATCH; 600 SEEDED_RED slots; 100 slot MATCH; 0 unexpected',file=sys.stderr)
if __name__=='__main__':
    main()
