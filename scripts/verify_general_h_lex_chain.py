#!/usr/bin/env python3
"""QA only: independently verify every native H record, then full native word.
Usage: python3 scripts/verify_general_h_lex_chain.py --self-test
       python3 scripts/verify_general_h_lex_chain.py FIXTURES CASE NEW_DIR
FIXTURES is the output of prepare_general_lex_ranks.js; no Foundation rerun.
"""
import argparse, hashlib, itertools, json, math, pathlib, re, shutil, subprocess, tempfile

PINS = {
    'year4999': '6a1f8b7536eb8fa908c9472a289c36b6c2e80ab8a882110b2fa39f95a742d675',
    'year5001': '48065ca44d184f2fe002edfcc79ff4ba1612b828dfed71a8afbacf4be1dcee24',
    'creation_minus1234': '705e7e4245ddde6b91291e1d78789b78243127a68d40621d2c256b81035c132a',
    'creation_plus1234': '13fe3563f6f829f1af164b11c847a24f3ba59302a1a4805a92daedfb7daa839b',
    'year5002': '93a05ffb9b7d66bf5d06e5e229fc69bc73bfba19ec5b3324247ef4f8a14ca200',
}
RANK_PINS = dict(zip(PINS, ['1f1db813c0d3c7932b7ce4d106f57e68af1ff29d87a50f1484e094d7c892abb7','5b18428fecea6764dc90476754a2d54c4b22d90bdc075b829797e6d15f8d6efe','0488e6cd82f84be3f32cd008d15de6bc492187c65982855333099fac95b02182','6312280c94133462d4604997cfd632115216af7992358b53d887dc78a6af2b2b','c64b94729890ca9773c115f48e0fbfaa60d4ee6c0aa917295714f9b623c8f211']))
RECORD = re.compile(rb'[0-9a-f]{8192}\n')

def require(ok, msg):
    if not ok: raise ValueError(msg)

def sha(b): return hashlib.sha256(b).hexdigest()
def blob(p):
    b=p.read_bytes(); return hashlib.sha1(f'blob {len(b)}\0'.encode()+b).hexdigest()

def rows(lengths):
    require(1<=len(lengths)<=47 and all(4<=x<=123 for x in lengths) and sum(lengths)<=5778,'geometry bounds')
    caps=list(itertools.accumulate(x-1 for x in lengths))
    nxt=[1]*(caps[-1]+1)
    yield nxt
    for s in range(len(lengths)-2,-1,-1):
        v=lengths[s+1]; running=0; row=[]
        for n in range(caps[s]+1):
            running+=math.comb(n+v-2,v-2)*nxt[n+v-1]; row.append(running)
        yield row
        nxt=row

def verify_table(path,lengths,expected):
    caps=list(itertools.accumulate(x-1 for x in lengths)); count=sum(x+1 for x in caps)
    require(path.stat().st_size==count*8193,'H size')
    digest=hashlib.sha256(); i=0
    with path.open('rb') as f:
        for row in rows(lengths):
            for x in row:
                b=f.read(8193); require(RECORD.fullmatch(b) is not None,f'H format record {i}')
                require(int(b[:-1],16)==x,f'H mismatch record {i}')
                digest.update(b); i+=1
        require(not f.read(1) and i==count,'H count')
    require(row[lengths[0]-1].to_bytes(4096,'big')==expected,'host root mismatch')
    return {'records':i,'tableSHA256':digest.hexdigest()}

def verify_word(b,lengths,pin):
    require(len(b)==sum(lengths) and sha(b)==pin,'word length or digest')
    require(all(1<=x<=len(lengths) for x in b),'word label range')
    require([b.count(x) for x in range(1,len(lengths)+1)]==lengths,'word multiplicity')
    first=[b.index(x) for x in range(1,len(lengths)+1)]; last=[b.rindex(x) for x in range(1,len(lengths)+1)]
    require(first==sorted(first) and last==sorted(last),'word order')

def self_test():
    with tempfile.TemporaryDirectory() as t:
        p=pathlib.Path(t)/'H'; l=[4,4,4]; rr=list(rows(l)); e=rr[-1][3].to_bytes(4096,'big')
        b=b''.join(f'{x:08192x}\n'.encode() for r in rr for x in r); p.write_bytes(b)
        require(verify_table(p,l,e)['records']==21,'control count')
        for bad in (b[:-1],b+b'0',b'X'+b[1:],b[:8191]+b'2'+b[8192:]):
            p.write_bytes(bad)
            try: verify_table(p,l,e)
            except ValueError: pass
            else: raise AssertionError('mutation escaped')
        p.write_bytes(b)
        try: verify_table(p,l,bytes(4096))
        except ValueError: pass
        else: raise AssertionError('root mutation escaped')
        w=bytes([1]*4+[2]*4+[3]*4); verify_word(w,l,sha(w))
        for bad in (w[:-1],w[::-1],bytes([1]*5+[2]*3+[3]*4)):
            try: verify_word(bad,l,sha(bad))
            except ValueError: pass
            else: raise AssertionError('word mutation escaped')
    print('HOST_CHAIN_SELF_TEST_PASS positive=2 negative=8 NATIVE_NOT_RUN')

def run(cmd,log,seconds):
    with log.open('wb') as out:
        p=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT,timeout=seconds,check=False)
    require(p.returncode==0,f'nonzero exit {p.returncode}: {log}')
    return log.read_text(errors='replace')

def main():
    p=argparse.ArgumentParser(); p.add_argument('--self-test',action='store_true'); p.add_argument('fixtures',nargs='?',type=pathlib.Path); p.add_argument('case',nargs='?',choices=PINS); p.add_argument('directory',nargs='?',type=pathlib.Path); a=p.parse_args()
    if a.self_test: self_test(); return
    require(a.fixtures and a.case and a.directory,'required arguments')
    f=a.fixtures.resolve(); d=a.directory.resolve(); d.mkdir(); name=a.case
    geo=f/(name+'.geometry'); root=f/(name+'.expected'); rank=f/(name+'.rank')
    g=geo.read_bytes(); nums=list(map(int,g.split())); lengths=nums[1:]; require(nums[0]==len(lengths),'geometry count')
    m=json.loads((f/'manifest.json').read_text()); require(m['oracleBlob']=='e228f43f2d33b9af59c5fb232281ca403455ca5c' and m['foundationSkipped'] is True,'manifest scope')
    c=[x for x in m['cases'] if x['name']==name]; require(len(c)==1,'case count'); c=c[0]
    e=root.read_bytes(); k=rank.read_bytes(); require(len(e)==len(k)==4096 and 0<int.from_bytes(k,'big')<=int.from_bytes(e,'big'),'rank range')
    require(sha(g)==c['geometrySHA256'] and sha(e)==c['rootSHA256'] and sha(k)==c['rankSHA256']==RANK_PINS[name] and c['wordSHA256']==PINS[name],'fixture pins')
    tests=pathlib.Path(__file__).resolve().parent.parent/'tests'; h=tests/'tb_weave_native_general_h.sv'; lex=tests/'tb_weave_native_general_lex.sv'
    require(blob(h)=='dea946e1f1e1bca0ffde60acf6f042f88750368b' and blob(lex)=='265c61c933bdefe47da93150be00b4271e8fc97e','bench pins')
    require(shutil.which('iverilog') and shutil.which('vvp'),'Icarus absent; Native NOT_RUN')
    require(shutil.disk_usage(d).free>=2*1024**3,'disk cap')
    for top,src in [('tb_weave_native_general_h',h),('tb_weave_native_general_lex',lex)]:
        run(['iverilog','-g2012','-s',top,'-o',str(d/(top+'.vvp')),str(src)],d/(top+'.compile.log'),60)
    table=d/'H.hex'; actual=d/'native.root'; word=d/'native.word'
    log=run(['vvp',str(d/'tb_weave_native_general_h.vvp'),f'+geometry={geo}',f'+root={actual}',f'+table={table}'],d/'H.log',240)
    require('GENERAL_H_CANDIDATE_PASS' in log and actual.read_bytes()==e,'native root')
    record=verify_table(table,lengths,e); (d/'H.verified.json').write_text(json.dumps(record,indent=2)+'\n')
    log=run(['vvp',str(d/'tb_weave_native_general_lex.vvp'),f'+geometry={geo}',f'+root={actual}',f'+rank={rank}',f'+table={table}',f'+word={word}'],d/'lex.log',240)
    require(f'GENERAL_LEX_TERMINAL_RANK_ONE days={sum(lengths)} months={len(lengths)}' in log and f'GENERAL_LEX_CANDIDATE_PASS positions={sum(lengths)}' in log,'lex markers')
    verify_word(word.read_bytes(),lengths,PINS[name]); record.update(case=name,wordSHA256=PINS[name],scope='HOST_GEOMETRY_RANK_NATIVE_H_LEX_ONLY_STAGE1_NOT_ACCEPTED')
    (d/'chain.verified.json').write_text(json.dumps(record,indent=2)+'\n'); print(json.dumps(record))

if __name__=='__main__': main()
