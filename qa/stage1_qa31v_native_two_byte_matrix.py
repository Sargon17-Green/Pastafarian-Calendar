#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31V original Native two-byte suffix matrix (25 cases per shard)."""
from __future__ import print_function
import binascii, json, os, sys
import stage1_qa31g_native_eof_probe as native

PIN = '560d6aa5807a7f766213a33835cce85eab0fa40c'
PREFIX = '1 0 0 0'
DIGITS = tuple(range(0x30,0x3a))
SPECIAL = (0,9,10,13,32,255)
WS = (9,10,13,32)
CAP, SIZE, SHARDS = 25000, 25, 8

def need(ok, why):
    if not ok: raise AssertionError(why)

def all_pairs():
    a = [(x,y) for x in DIGITS for y in DIGITS + SPECIAL]
    b = [(x,y) for x in WS for y in DIGITS]
    out = a + b
    need(len(a)==160 and len(b)==40 and len(set(out))==200,'pair corpus')
    return out

def main(shard,folder):
    need(0<=shard<SHARDS,'shard range')
    need(os.path.isdir(folder),'output missing')
    source = open(native.qa20.SOURCE,'rb').read()
    need(native.qa20.pin(source)==PIN==native.PIN==native.qa20.PIN,'source blob')
    need(native.CAP==7000,'observer CAP drift')
    native.CAP=CAP
    selected = all_pairs()[shard*SIZE:(shard+1)*SIZE]
    need(len(selected)==SIZE,'shard size')
    observed=[]
    for x,y in selected:
        label = 'pair_%02x_%02x' % (x,y)
        raw = PREFIX + chr(x) + chr(y)
        need(len(raw)==len(PREFIX)+2,'exact suffix bytes')
        rec = native.run(source,folder,label,raw)
        need(rec['label']==label and rec['raw_hex']==binascii.hexlify(raw)
             and rec['raw_sha256']==native.sha(raw)
             and rec['status']=='HALT' and rec['error'] is None
             and type(rec['steps']) is int and 0<rec['steps']<=CAP,
             'Native must HALT exactly: '+label)
        observed.append(rec)
        print('QA31V_NATIVE',shard,label,rec['status'],rec['steps'],rec['reads'])
        sys.stdout.flush()
    receipt={
        'schema':'qa31v-original-native-two-byte-v1',
        'source_blob':PIN,'source_modified':False,'ip_relocated':False,
        'suffix_prefix_hex':binascii.hexlify(PREFIX),
        'suffix_length':2,'corpus_size':200,
        'corpus_definition':'digit_x_digit_or_special_then_ws_x_digit',
        'shard':shard,'shard_size':SIZE,'total_shards':SHARDS,
        'case_cap_steps':CAP,'all_shards_step_cap':CAP*SIZE*SHARDS,
        'completed_native_cases':SIZE,
        'global_reachability_proven':False,'stage1_pass':False,
        'cases':observed
    }
    with open(os.path.join(folder,'qa31v_receipt.json'),'wb') as out:
        out.write(json.dumps(receipt,sort_keys=True,indent=2)+'\n')
    print('QA31V_NATIVE_SHARD_COMPLETE',shard,SIZE)
    print('QA31V_STAGE1_REMAINS_OPEN')

if __name__=='__main__':
    need(len(sys.argv)==3,'usage: qa31v_native_two_byte_matrix.py shard folder')
    main(int(sys.argv[1]),sys.argv[2])
