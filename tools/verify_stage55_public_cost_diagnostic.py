#!/usr/bin/env python3
"""Attribute warm public-converter cost using existing source trace; not a performance acceptance gate."""
import json, pathlib, re, sys
out=pathlib.Path(sys.argv[1])
summary=json.loads((out/'summary.json').read_text())
assert summary['pass'] and summary['verified_calls']==6
records=[json.loads(x) for x in (out/'session1.jsonl').read_text().splitlines()]
log=(out/'session1.log').read_text()
segments=re.split(r'PUBLIC_CALL_BEGIN session=1 index=(\d+) target=(-?\d+)\s*',log)
assert len(segments)==19, len(segments)
results=[]
for k in range(6):
    idx,target,body=segments[1+3*k:4+3*k]
    r=records[k]
    assert int(idx)==r['index']==k+1 and int(target)==r['target']
    def phase(label):
        hits=re.findall(r'^'+label+r'(?: GATES=(\d+))? SECONDS=([0-9.]+)\s*$',body,re.M)
        assert len(hits)==1,(label,idx,hits)
        return int(hits[0][0]) if hits[0][0] else None,float(hits[0][1])
    gates,chain=phase('STAGE_54_YEAR_CHAIN_READY')
    _,structure=phase('STAGE_54_YEAR_STRUCTURE_READY')
    final_gates,finish=phase('STAGE_54_INTEGRATION_RESULT_READY')
    assert gates is not None and final_gates>=gates
    assert 0<=chain<=structure<=finish<=r['seconds']+0.01
    builds=len(re.findall(r'^STAGE_54_STRUCTURE_BEGIN ',body,re.M))
    results.append(dict(index=k+1,target=r['target'],public_seconds=r['seconds'],
        chain_seconds=chain,post_chain_to_structure_seconds=structure-chain,
        post_structure_seconds=finish-structure,overhead_seconds=r['seconds']-finish,
        gates_at_chain=gates,gates_at_finish=final_gates,structure_builds=builds))
report=dict(source_sha=summary['source_sha'],stage55_accepted=False,diagnostic_only=True,rows=results)
(out/'cost_diagnostic.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
