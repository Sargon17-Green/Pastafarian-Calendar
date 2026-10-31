#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31J: two previously unseen natural stdin buffers with existing Native observer."""
from __future__ import print_function
import os,sys,json
import stage1_qa31g_native_eof_probe as native
PIN='560d6aa5807a7f766213a33835cce85eab0fa40c'
CASES=[('digit_lf','1\n'),('digit_tab','1\t')]
def need(ok,msg):
    if not ok: raise AssertionError(msg)
def main(folder):
    need(os.path.isdir(folder),'output directory absent')
    source=open(native.qa20.SOURCE,'rb').read()
    need(native.qa20.pin(source)==PIN==native.PIN,'original source drift')
    need(native.CAP==7000,'native STEP bound changed')
    cases=[]
    for label,raw in CASES:
        c=native.run(source,folder,label,raw)
        need(c['label']==label and c['raw_hex']==raw.encode('hex'),'input provenance')
        cases.append(c)
        print('QA31J_NEW_NATIVE',label,c['status'],c['steps'],c['reads'])
    receipt={'schema':'qa31j-unseen-native-v1','source_blob':PIN,
             'source_modified':False,'ip_relocated':False,
             'original_qa31g_cases_rerun':0,'new_native_cases':2,
             'stage1_pass':False,'cases':cases}
    with open(os.path.join(folder,'qa31j_receipt.json'),'wb') as f:
        f.write(json.dumps(receipt,sort_keys=True,indent=2)+'\n')
    print('QA31J_TWO_UNSEEN_INPUTS_TRACED')
    print('QA31J_NO_STAGE1_PASS')
if __name__=='__main__':
    need(len(sys.argv)==2,'usage: runner output_folder')
    main(sys.argv[1])
