#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA16: finite genuine PyFunge-98 hot reset while TWO other Programs run.

Native calculation and all numeric expectations are Befunge, never Python.
Private-space guards instrument actual native Space.get/put/putspace.
"""
from __future__ import print_function
import hashlib, json, os, sys, StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_live_pair_matrix as base

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
CASES = (
    ('invalid_valid_two_peers', 'i0', 'v1', 'v3', 'v0', (100, 2, 3)),
    ('valid_invalid_lexical_two_peers', 'v2', 'v4', 'v5', 'i5', (51, 3, 2)),
    ('invalid_numeric_valid_two_peers', 'i2', 'v2', 'v3', 'v5', (37, 2, 5)),
    ('valid_invalid_numeric_two_peers', 'v3', 'v1', 'v5', 'i0', (83, 5, 2)),
)
OUTPUT='/multihotreset/qa16_native_two_live_peers.json'

def need(test,reason):
    if not test:raise AssertionError(reason)

def execute(code,case,refs):
    name,first,peer1,peer2,after,quanta=case
    labels=('a','b','c')
    aa,bb,cc=(base.make(code,v) for v in (first,peer1,peer2))
    members={'a':aa,'b':bb,'c':cc}
    actors=[aa,bb,cc]
    obj=aa['program'];identity=id(obj)
    need(len(set(id(m['program']) for m in actors))==3 and
         len(set(id(m['program'].space) for m in actors))==3 and
         len(set(id(m['program'].semantics) for m in actors))==3 and
         len(set(id(m['stdin']) for m in actors))==3 and
         len(set(id(m['stdout']) for m in actors))==3,
         'QA16 does not own three independent real Native Programs')
    cls=type(obj.space)
    need(all(type(m['program'].space) is cls for m in actors),'incompatible Funge-space classes')
    get0,put0,ps0=cls.get,cls.put,cls.putspace
    active=[None]
    writes={k:set() for k in labels}
    put_counts={k:0 for k in labels}
    get_counts={k:0 for k in labels}
    direct={k:0 for k in labels}
    putspace_counts={k:0 for k in labels}
    def logged_get(space,*args,**kw):
        owner=active[0]
        if owner is not None:
            need(space is members[owner]['program'].space,'QA16 a Native read crossed ownership boundary')
            get_counts[owner]+=1
        return get0(space,*args,**kw)
    def logged_put(space,*args,**kw):
        owner=active[0]
        need(owner is not None and space is members[owner]['program'].space and len(args)>=2,
             'QA16 Native write crossed an owner boundary')
        result=put0(space,*args,**kw)
        need(int(get0(space,args[0]))==int(args[1]),'QA16 real Native put not persisted')
        put_counts[owner]+=1
        writes[owner].add(tuple(map(int,args[0])))
        return result
    def logged_putspace(space,*args,**kw):
        owner=active[0]
        need(owner is not None and space is members[owner]['program'].space,
             'QA16 putspace escaped its owner')
        putspace_counts[owner]+=1
        return ps0(space,*args,**kw)
    def enable():
        cls.get,cls.put,cls.putspace=logged_get,logged_put,logged_putspace
    def disable():
        active[0]=None
        cls.get,cls.put,cls.putspace=get0,put0,ps0
    def snapshot(key):
        m=members[key]; p=m['program'];vt=m['point']
        return (id(p),id(p.space),id(p.semantics),id(p.semantics.platform),
                id(p.ips),base.state(m),
                tuple((xy,int(get0(p.space,vt(xy)))) for xy in sorted(writes[key])))
    def tick(key):
        m=members[key];p=m['program']
        if not p.ips:return
        ip=p.ips[0]
        if not ip.stringmode and int(get0(p.space,ip.position))==ord('p'):
            direct[key]+=1
        active[0]=key
        try:base.tick(m)
        finally:active[0]=None
    def run_quantum(key,n):
        if not members[key]['program'].ips:return 0
        paused=[x for x in labels if x!=key]
        signatures=[snapshot(x) for x in paused]
        executed=0
        for j in range(n):
            if not members[key]['program'].ips:break
            tick(key);executed+=1
        for k,prior in zip(paused,signatures):
            need(snapshot(k)==prior,
                 'QA16 quantum illegally modified a passive live or terminated Program '+k)
        return executed
    def ref(k):
        if k not in refs:refs[k]=base.reference(k)
        return refs[k]
    rounds=0;before=0;after_overlap=0;two_peer_checks=0;control_rejections=0
    oldspace=None;oldvtype=None;oldcells=None
    try:
        enable()
        # The two peers, not merely the actor, perform actual native work first.
        for j in range(1500):
            need(bb['program'].ips and cc['program'].ips,'QA16 peer ended before live warmup')
            tick('b');tick('c')
        need(put_counts['b']>0 and put_counts['c']>0 and
             get_counts['b']>0 and get_counts['c']>0,
             'QA16 warmup did not exercise both independent p/g histories')
        # Intentional test-only adversarial write outside any executed opcode.
        # Undo it before Native execution resumes; do not count it as a Native p.
        point=sorted(writes['b'])[0]
        s=bb['program'].space;v=bb['point'](point)
        prior=snapshot('b');original=int(get0(s,v))
        put0(s,v,original+1)
        need(snapshot('b')!=prior,'QA16 watcher missed forged passive peer memory write')
        put0(s,v,original)
        need(snapshot('b')==prior,'QA16 negative-control write not restored')
        control_rejections+=1
        while obj.ips:
            rounds+=1
            need(rounds<100000 and bb['program'].ips and cc['program'].ips,
                 'QA16 actor did not finish with both independent peers live')
            if bb['program'].ips and cc['program'].ips:before+=1
            if run_quantum('a',quanta[0]):two_peer_checks+=2
            if run_quantum('b',quanta[1]):two_peer_checks+=2
            if run_quantum('c',quanta[2]):two_peer_checks+=2
        need(aa['stdout'].getvalue().split()==ref(first),'QA16 pre-reset response not Native reference')
        oldspace=obj.space;oldvtype=aa['point']
        oldcells=tuple((pt,int(get0(oldspace,oldvtype(pt)))) for pt in sorted(writes['a']))
        need(oldcells and bb['program'].ips and cc['program'].ips,'QA16 no old memory or peers')
        peer1_before=snapshot('b');peer2_before=snapshot('c')
        peerobjects=(bb['program'],cc['program'])
        disable()
        newin=StringIO.StringIO(base.raw_for(after));newout=StringIO.StringIO()
        platform=BufferedPlatform([],{},stdin=newin,stdout=newout)
        oldsem=obj.semantics
        Program.__init__(obj,Befunge98,platform=platform)
        need(id(obj)==identity and obj.space is not oldspace and
             obj.semantics is not oldsem and obj.semantics.platform is platform and not obj.ips,
             'QA16 actor hot reset reused old execution objects')
        obj.load_code(code);obj.create_ip()
        need(len(obj.ips)==1 and tuple(obj.ips[0].position)==(0,0) and
             tuple(obj.ips[0].delta)==(1,0) and not obj.ips[0].stack[0],
             'QA16 newly reset actor IP not pristine')
        aa['point']=obj.ips[0].position.__class__;aa['stdin']=newin
        aa['stdout']=newout;aa['steps']=0;aa['label']=after
        need(bb['program'] is peerobjects[0] and cc['program'] is peerobjects[1] and
             snapshot('b')==peer1_before and snapshot('c')==peer2_before,
             'QA16 reinitializing actor corrupted a different live Program')
        need(tuple((pt,int(get0(oldspace,oldvtype(pt)))) for pt,_ in oldcells)==oldcells,
             'QA16 actor reset modified old discarded physical memory')
        writes['a']=set();put_counts['a']=get_counts['a']=direct['a']=putspace_counts['a']=0
        enable()
        while any(m['program'].ips for m in actors):
            rounds+=1
            need(rounds<150000,'QA16 Native 3-program scheduling did not terminate')
            if all(m['program'].ips for m in actors):after_overlap+=1
            for key,n in (('c',quanta[2]),('a',quanta[0]),('b',quanta[1])):
                if run_quantum(key,n):two_peer_checks+=2
        for m,k in ((aa,after),(bb,peer1),(cc,peer2)):
            need(m['stdout'].getvalue().split()==ref(k) and not m['program'].ips,
                 'QA16 one of three Native outcomes disagrees with real Befunge reference')
        need(tuple((pt,int(get0(oldspace,oldvtype(pt)))) for pt,_ in oldcells)==oldcells,
             'QA16 subsequent actor and peer runs altered old discarded Funge-space')
        need(before>0 and after_overlap>0 and two_peer_checks>0 and control_rejections==1,
             'QA16 finite overlap or ownership negative control missing')
        for k in labels:
            need(put_counts[k]>0 and get_counts[k]>0 and
                 put_counts[k]==direct[k] and putspace_counts[k]==0,
                 'QA16 native memory APIs/physical p count inconsistent: '+k)
        return {'name':name,'before':first,'peer_one':peer1,'peer_two':peer2,
                'after':after,'quanta':list(quanta),'before_overlap':before,
                'after_all_three_overlap':after_overlap,
                'passive_peer_snapshot_checks':two_peer_checks,
                'peer_memory_attack_rejected':control_rejections,
                'old_actor_written_coordinates_checked':len(oldcells),
                'peer_writes':[put_counts['b'],put_counts['c']],
                'peer_reads':[get_counts['b'],get_counts['c']],
                'actor_post_reset_put':put_counts['a'],
                'old_actor_memory_preserved':True,'peers_stayed_private':True,
                'same_program_identity':True,'fresh_actor_space_semantics_ip_io':True,
                'three_outputs_match_independent_native_references':True,
                'before_output':ref(first),'peer_one_output':ref(peer1),
                'peer_two_output':ref(peer2),'after_output':ref(after)}
    finally:disable()

def main():
    need(os.path.isdir('/multihotreset'),'QA16 evidence volume absent')
    data=open(base.SOURCE,'rb').read()
    sha=hashlib.sha1('blob %d\0%s'%(len(data),data)).hexdigest()
    need(sha==PIN==base.PIN,'QA16 QA production source mutated')
    refs={};rows=[]
    for case in CASES:
        result=execute(data,case,refs);rows.append(result)
        print('QA16_NATIVE_TWO_PEERS_HOT_RESET_PASS',case[0],
              'before',result['before_overlap'],
              'after',result['after_all_three_overlap'])
        sys.stdout.flush()
    need(len(rows)==4 and sum(k.startswith('v') for k in refs)==6,
         'QA16 independent six valid native oracle anchors incomplete')
    receipt={'schema':'qa16-real-native-two-live-peers-hot-reset-v1',
             'source_git_blob':PIN,'stage1_final_accepted':False,
             'scenario_count':4,'native_program_executions':16,
             'independent_native_reference_invocations':18,'records':rows}
    with open(OUTPUT,'wb') as out:out.write(json.dumps(receipt,sort_keys=True,indent=2)+'\n')
    print('QA16_REAL_NATIVE_4_TRIPLE_HOT_RESET_SCENARIOS_PASS')
    print('STAGE1_STILL_OPEN')
if __name__=='__main__':main()
