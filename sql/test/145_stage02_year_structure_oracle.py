#!/usr/bin/env python3
"""Compare full real PG17 record arrays and independent structural invariants."""
import argparse, collections, json, pathlib
p=argparse.ArgumentParser()
p.add_argument('--file',type=pathlib.Path,required=True)
p.add_argument('--case',required=True)
a=p.parse_args()
rows=[json.loads(x) for x in a.file.read_text().splitlines() if x.strip()]
assert len(rows)==1 and rows[0]['id']==a.case
rec=rows[0]
actual,expected=rec['actual'],rec['expected']
fields=('year_data','cutlet_count','cutlet_partition','cutlet_name_indices',
        'month_count','month_lengths','month_weaving','month_name_indices')
assert set(actual)==set(expected)==set(fields)
for f in fields: assert actual[f]==expected[f],f
y=expected['year_data']
g=int(y['close_gate_index']-y['open_gate_index'])
d=int(y['close_gate_day']-y['open_gate_day'])
c=expected['cutlet_count']
m=expected['month_count']
cp=expected['cutlet_partition'];cn=expected['cutlet_name_indices']
ml=expected['month_lengths'];mw=expected['month_weaving'];mn=expected['month_name_indices']
assert 6<=g and 252<=d<=5778 and 6<=c<=min(17,g) and len(cp)==c and sum(cp)==g
assert len(cn)==c and len(set(cn))==c and all(1<=x<=17 for x in cn)
assert (d+122)//123<=m<=min(47,d//4)
assert len(ml)==m and sum(ml)==d and all(4<=x<=123 for x in ml)
assert len(mw)==d and collections.Counter(mw)==collections.Counter({i+1:n for i,n in enumerate(ml)})
assert len(mn)==m and len(set(mn))==m and all(1<=x<=47 for x in mn)
print(f'slice24_actual_full_record={a.case} 1/1 PASS')
print(f'slice24_independent_python_structural={a.case} 1/1 PASS')
