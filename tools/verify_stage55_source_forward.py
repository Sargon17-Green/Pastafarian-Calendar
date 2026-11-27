import hashlib,json,os
from pathlib import Path
d=Path('logs/stage55_source_forward')
assert (d/'oracle.exit').read_text().strip()=='0'
for stem,ext,h in [('count','txt','c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8'),('rank','txt','160ca5c4a8ee5d0ec29c583a0d7ab91a71d8be4b7dc4c139ebaae066596dcff3'),('word','json','76396b8dc72b209c9f273d7ebbab3c6a09b3424eff8ee71acd1566680641786e')]:
    a=(d/f'oracle_{stem}.{ext}').read_bytes(); b=(d/f'native_{stem}.{ext}').read_bytes()
    assert a==b and hashlib.sha256(a).hexdigest()==h,stem
r=json.loads((d/'native_report.json').read_text())
assert r['sha']==os.environ['GITHUB_SHA'] and r['positions']==4244 and r['production_used'] and r['places']==177
assert 0<r['rss_kib']<3*1024*1024 and 0<r['elapsed']<9600
print('SOURCE_FORWARD_DIFFERENTIAL_PASS 4244/4244; Stage55 OPEN')
