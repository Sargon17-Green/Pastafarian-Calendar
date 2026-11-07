#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA12: Native Befunge-98 Stage-1 boundary grid; no Python calendar oracle.

Four shards partition unordered pairs of 16 distinct signed day indices.
For every ordered pair, three independent *native Befunge* reference programs
work_counts / save / save are compared with the unchanged QA production program.
Swapped pairs additionally obey metamorphic relations of the native results.
This is a finite functional gate, NOT full Stage-1 or geometry acceptance.
Works in pinned Python 2.7 PyFunge CI image. 
"""
from __future__ import print_function
import argparse
import hashlib
import json
import os
import subprocess
import sys
import time

SOURCE='src/interleaved_work_counts.b98'
REF_COUNTS='reference/work_counts.b98'
REF_SAVE='reference/save.b98'
PINS={SOURCE:'560d6aa5807a7f766213a33835cce85eab0fa40c',
      REF_COUNTS:'f941efc793c9eee4accf5d03873f8ed029b16725',
      REF_SAVE:'7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44'}
CMD=('pyfunge','--disable-fprint','--no-concurrent',
     '--no-filesystem','-v98','-d2')
M=(1<<127)-1
DAYS=[
    ('zero',0,0),('one',0,1),('two',0,2),
    ('minus_one',1,1),('minus_two',1,2),
    ('foundation_minus_2',1,15055673),
    ('foundation_minus_1',1,15055672),
    ('foundation',1,15055671),
    ('foundation_plus_1',1,15055670),
    ('foundation_plus_2',1,15055669),
    ('max_save',0,M),('over_save',0,M+1),
    ('negative_max_save',1,M),('negative_over_save',1,M+1),
    ('very_large',0,10**80+17),
    ('very_negative',1,10**80+19),
]
INVALID=[
    ('bad_calc_sign_2','2 1 0 1'),
    ('bad_target_sign_2','0 1 2 1'),
    ('negative_zero_calc','1 0 0 1'),
    ('negative_zero_target','0 1 1 0'),
    ('explicit_negative_calc','-1 1 0 1'),
    ('explicit_negative_target','0 1 -1 1'),
    ('plus_calc','+0 1 0 1'),
    ('plus_target','0 1 +0 1'),
    ('garbage_calc','x 1 0 1'),
    ('garbage_target','0 1 0 x'),
    ('missing_field','0 1 0'),
    ('extra_field','0 1 0 1 5'),
    ('empty_line',''),
    ('double_sign','--1 1 0 1'),
    ('sign_10','10 1 0 1'),
    ('trailing_garbage','0 1 0 1 xyz'),
]
TOTAL_UNORDERED=len(DAYS)*(len(DAYS)+1)//2
TOTAL_ORDERED=len(DAYS)**2

def require(ok,msg):
    if not ok:raise AssertionError(msg)

def gitblob(data):
    h=hashlib.sha1()
    h.update(('blob %d\0'%len(data)).encode('ascii'))
    h.update(data)
    return h.hexdigest()

def pin_sources():
    return dict((path,gitblob(open(path,'rb').read())) for path in PINS)

def partition(shard):
    allpairs=[(i,j) for i in range(len(DAYS))
               for j in range(i,len(DAYS))]
    return [p for n,p in enumerate(allpairs) if n%4==shard]

def run(path,raw,timeout=50):
    cmd=['timeout','--kill-after=3s',str(timeout)+'s']+list(CMD)+[path]
    process=subprocess.Popen(cmd,stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=process.communicate((raw+'\n').encode('ascii'))
    require(process.returncode==0,
            'NATIVE_FAIL path=%s input=%r exit=%r stderr=%r'%
            (path,raw,process.returncode,err[-450:]))
    result=out.split()
    require(result and all(x.lstrip(b'-').isdigit() for x in result),
            'non-numeric native output from %s input=%r'%(path,raw))
    return [x.decode('ascii') for x in result]

def oracle(first,second):
    a,b=first[1:],second[1:]
    raw='%d %d %d %d'%(a[0],a[1],b[0],b[1])
    work=run(REF_COUNTS,raw)
    c=run(REF_SAVE,'%d %d'%(a[0],a[1]))
    t=run(REF_SAVE,'%d %d'%(b[0],b[1]))
    result=work+c+t
    require(len(work)==5 and len(c)==1 and len(t)==1,
            'invalid native independent reference shape '+raw)
    return result

def check_mirror(forward,reverse,same):
    require(len(forward)==len(reverse)==7,'not 7 workcount outputs')
    require(forward[0]==reverse[1] and forward[1]==reverse[0] and
            forward[2]==reverse[2] and forward[3]==reverse[3] and
            forward[5]==reverse[6] and forward[6]==reverse[5],
            'native swap relations broken')
    require(int(forward[4])+int(reverse[4])==4,
            'native direction reversal relation broken')
    if same:
        require(forward[4]==reverse[4]=='2' and forward[2]=='1',
                'native same-day direction/distance broken')

def selftest():
    require(len(DAYS)==16 and len(set((x[1],x[2]) for x in DAYS))==16,
            'day boundary coverage not distinct')
    require(len(INVALID)==16 and len(set(x[1] for x in INVALID))==16,
            'invalid corpus not unique')
    families=[partition(i) for i in range(4)]
    require([len(x) for x in families]==[34,34,34,34],
            'shard distribution changed')
    union=[pair for family in families for pair in family]
    require(len(union)==TOTAL_UNORDERED and len(set(union))==TOTAL_UNORDERED,
            'unordered day coverage has gaps')
    require(sum(2-(i==j) for i,j in union)==TOTAL_ORDERED,
            'ordered day coverage has gaps')
    sample=['1','3','2','4','3','3','3']
    reverse=['3','1','2','4','1','3','3']
    check_mirror(sample,reverse,False)
    try:
        check_mirror(sample,reverse[:-1]+['2'],False)
        raise AssertionError('tampered swap accepted')
    except AssertionError as error:
        require('native swap relations broken' in str(error),'wrong tamper rejection')
    print('QA12_MATRIX_SELFTEST_PASS unordered=%d ordered=%d invalid=%d'%
          (TOTAL_UNORDERED,TOTAL_ORDERED,len(INVALID)))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--shard',type=int,choices=range(4))
    parser.add_argument('--selftest',action='store_true')
    args=parser.parse_args()
    selftest()
    if args.selftest:return
    require(args.shard is not None,'specify --shard')
    observed=pin_sources()
    require(observed==PINS,'native BF98 source/reference SHA drift: '+repr(observed))
    folder=os.environ.get('QA12_RECEIPT_DIR','/qa12-receipts')
    require(os.path.isdir(folder),'QA12 output directory not mounted')
    receipt={'schema':'bf98-stage1-qa12-native-boundary-grid-v1',
             'shard':args.shard,'source_blobs':observed,
             'stage1_accepted':False,'qa12_is_final_acceptance':False,
             'universe_days':len(DAYS),'all_unordered_pairs':TOTAL_UNORDERED,
             'all_ordered_pairs':TOTAL_ORDERED,'cases':[],
             'negative_cases':[],'complete':False}
    destination=os.path.join(folder,'qa12_shard_%d.json'%args.shard)
    try:
        for index,(i,j) in enumerate(partition(args.shard)):
            a,b=DAYS[i],DAYS[j]
            one=oracle(a,b)
            inp='%d %d %d %d'%(a[1],a[2],b[1],b[2])
            actual=run(SOURCE,inp)
            require(actual==one,
                    'production native disagrees with native references at '+repr((a[0],b[0],actual,one)))
            if i!=j:
                rev=oracle(b,a)
                revinput='%d %d %d %d'%(b[1],b[2],a[1],a[2])
                got=run(SOURCE,revinput)
                require(got==rev,'reverse native oracle differs '+repr((a[0],b[0])))
            else:rev=one
            check_mirror(actual,rev,i==j)
            receipt['cases'].append({'a':a[0],'b':b[0],
                'canonical_input':inp,'normal_seven':actual,
                'reversed_seven':rev,'symmetric_check':True})
            print('QA12_NATIVE_PAIR_PASS',args.shard,index,a[0],b[0]);sys.stdout.flush()
        for name,raw in INVALID[args.shard::4]:
            got=run(SOURCE,raw)
            require(got==['-1']*7,
                    'Native production lexical-invalid case accepted '+repr((name,got)))
            receipt['negative_cases'].append({'label':name,'input':raw,'output':got})
            print('QA12_NATIVE_INVALID_REJECT_PASS',args.shard,name);sys.stdout.flush()
        receipt['complete']=True
        print('QA12_NATIVE_SHARD_PASS',args.shard,
              'unordered',len(receipt['cases']),
              'invalid',len(receipt['negative_cases']))
    finally:
        with open(destination,'wb') as out:
            out.write((json.dumps(receipt,sort_keys=True,indent=2)+'\n').encode('ascii'))

if __name__=='__main__':main()
