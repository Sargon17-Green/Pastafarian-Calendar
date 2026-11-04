#!/usr/bin/env python3
"""Bounded 3x5 pinned-reference differential; diagnostic, NOT --certify.

Reuses exact successful unseeded signed-gate evidence (no rerun) and executes
three cold pinned-Python date processes in separate Git-root/cache contexts.
It does not import production Kotlin or the reference calendar into this process.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from time import monotonic

SOURCE_RUN = 41787621424
SOURCE_ARTIFACT = 13301487901
SOURCE_SHA = '366e5444040122530bbef96a0421ad5f6fa5ebe4'
PINNED_SHA = '7cb12bf355461e5a179e0deadb7365689288bf29'
EVIDENCE_SHA256 = 'f0945f38de8abe3b5cd25c7561a59f89bd7f6fc3b8a601a8bf2661a344192638'
PINNED_MODULE_SHA256 = 'a9e48e61124221cce39805a825c746a734a5f8f660406a898af38351e2cce6a1'
EXPECTED_TRACE_SHA256 = 'caaf71076bf738981db4b75af441ae82a8e4341970d24606ffc59bd208f64193'
TARGETS = [-278523, -278522, -278521]
PASS = 'PASS_PINNED_THREE_BY_FIVE_DIFFERENTIAL_NOT_CERTIFIED'


class DifferentialError(ValueError):
    pass


def strict_rows(rows, *, label):
    if type(rows) is not list or len(rows) != 3:
        raise DifferentialError(f'E_{label}_ROW_COUNT')
    result = []
    for i, row in enumerate(rows):
        if type(row) is not dict or not {'day','five_fields'}.issubset(row):
            raise DifferentialError(f'E_{label}_ROW_SHAPE_{i}')
        fields = row.get('five_fields')
        if (type(row.get('day')) is not int or row['day'] != TARGETS[i]
                or type(fields) is not list or len(fields) != 5
                or any(type(n) is not int or n <= 0 for n in fields)):
            raise DifferentialError(f'E_{label}_FIELD_SHAPE_{i}')
        result.append(fields)
    return result


def compare_rows(candidate, reference):
    a = strict_rows(candidate,label='INDEPENDENT')
    b = strict_rows(reference,label='PINNED')
    return [dict(day=day, independent=left, pinned=right,
                 matched=(left == right)) for day,left,right in zip(TARGETS,a,b)]


def verify_candidate_document(document):
    if type(document) is not dict:
        raise DifferentialError('E_EVIDENCE_FORMAT')
    expected = {
        'status':'PASS_REAL_UNSEEDED_FIVE_FIELDS_PINNED_DATE_NOT_COMPARED_NOT_CERTIFIED',
        'independent_commit':SOURCE_SHA,'pinned_commit':PINNED_SHA,
        'pinned_module_sha256':PINNED_MODULE_SHA256,
        'signed_transcript_sha256':EXPECTED_TRACE_SHA256,
        'cases':3,'fields_per_case':5,'total_unique_gap_questions':29523,
        'production_gate_limit_unchanged':8192,'segment_limit':4096,
        'checkpoint_seed_used':False,'pinned_date_comparison_performed':False,
        'full_date_certified':False,'certifiable':False,
        'targets':TARGETS,
    }
    for key,value in expected.items():
        if type(document.get(key)) is not type(value) or document[key] != value:
            raise DifferentialError('E_EVIDENCE_DRIFT_'+key.upper())
    strict_rows(document.get('rows'),label='INDEPENDENT')
    return document['rows']


def sha(path):
    return subprocess.check_output(['git','-C',str(path),'rev-parse','HEAD'],
                                   text=True,timeout=12).strip()


def verify_git_roots(branch_root, source_root):
    branch_root = branch_root.resolve(strict=True)
    source_root = source_root.resolve(strict=True)
    pinned_root = source_root.parent
    if (branch_root == pinned_root or branch_root.is_relative_to(pinned_root)
            or pinned_root.is_relative_to(branch_root)):
        raise DifferentialError('E_SHARED_GIT_ROOT')
    current = sha(branch_root)
    if (current != os.environ.get('GITHUB_SHA')
            or os.environ.get('GITHUB_REF_NAME') != 'Kotlin+Cymraeg'):
        raise DifferentialError('E_BRANCH_PROVENANCE')
    if sha(pinned_root) != PINNED_SHA:
        raise DifferentialError('E_PINNED_ROOT')
    ancestor = subprocess.run(['git','-C',str(branch_root),'merge-base','--is-ancestor',
                               SOURCE_SHA,current],capture_output=True,timeout=15)
    if ancestor.returncode != 0:
        raise DifferentialError('E_SOURCE_NOT_ANCESTOR')
    module = source_root/'pastafari_calendar'/'final_integration.py'
    if not module.is_file() or hashlib.sha256(module.read_bytes()).hexdigest() != PINNED_MODULE_SHA256:
        raise DifferentialError('E_PINNED_MODULE_HASH')
    return current


def run_worker(worker, source_root, target, *, seconds):
    if type(target) is not int or target not in TARGETS or not 1 <= seconds <= 240:
        raise DifferentialError('E_WORKER_BOUNDS')
    # Isolation: no PYTHONPATH, no user site, private HOME/CWD, separate PID
    # per target; -I ensures audited libraries are not importable from sys.path.
    with tempfile.TemporaryDirectory(prefix='pinned-date-') as tmp:
        env = {'PATH':os.environ.get('PATH','/usr/bin:/bin'),
               'HOME':tmp,'PYTHONDONTWRITEBYTECODE':'1',
               'PYTHONNOUSERSITE':'1','PYTHONHASHSEED':'0'}
        command = [sys.executable,'-I',str(worker.resolve(strict=True)),
                   '--source-root',str(source_root.resolve(strict=True)),
                   '--day',str(target)]
        completed = subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                                   text=True,timeout=seconds,cwd=tmp,env=env,check=False)
        if completed.returncode != 0:
            raise DifferentialError('E_WORKER_FAILED_'+str(target)+' '+completed.stderr[-500:])
        try:
            doc = json.loads(completed.stdout)
        except json.JSONDecodeError as exc:
            raise DifferentialError('E_WORKER_STDOUT_'+str(target)) from exc
        if (type(doc) is not dict or doc.get('day') != target
                or doc.get('reference_commit') != PINNED_SHA
                or doc.get('pinned_integration_sha256') != PINNED_MODULE_SHA256
                or doc.get('isolation_mode') != 'python_-I'
                or doc.get('process_cache_reset') is not True
                or doc.get('pinned_static_checkpoints_may_be_used') is not True):
            raise DifferentialError('E_WORKER_PROVENANCE_'+str(target))
        return {'day':doc['day'],'five_fields':doc.get('five_fields')}


def execute(args):
    root=Path(__file__).resolve().parent.parent
    branch_sha=verify_git_roots(root,args.pinned_root)
    data=args.candidate_evidence.read_bytes()
    if hashlib.sha256(data).hexdigest()!=EVIDENCE_SHA256:
        raise DifferentialError('E_EVIDENCE_HASH')
    rows=verify_candidate_document(json.loads(data))
    if not (1<=args.worker_timeout<=240 and 1<=args.total_timeout<=900):
        raise DifferentialError('E_TIME_BOUNDS')
    start=monotonic()
    deadline=start+args.total_timeout
    references=[]
    for target in TARGETS:
        remaining=int(deadline-monotonic())
        if remaining<=0:
            raise DifferentialError('E_TOTAL_DEADLINE')
        references.append(run_worker(root/'soak'/'pinned_five_field_worker.py',
                                     args.pinned_root,target,
                                     seconds=min(args.worker_timeout,remaining)))
    comparison=compare_rows(rows,references)
    if not all(c['matched'] for c in comparison):
        raise DifferentialError('E_REAL_PINNED_DATE_MISMATCH '+json.dumps(comparison))
    return {'status':PASS,'independent_commit':SOURCE_SHA,
            'differential_commit':branch_sha,'pinned_commit':PINNED_SHA,
            'source_run_id':SOURCE_RUN,'source_artifact_id':SOURCE_ARTIFACT,
            'source_artifact_json_sha256':EVIDENCE_SHA256,
            'pinned_module_sha256':PINNED_MODULE_SHA256,
            'comparisons':comparison,'cases':3,'fields_per_case':5,
            'independent_candidate_is_unseeded':True,
            'distinct_git_roots':True,'distinct_reference_process_per_target':True,
            'reference_process_cache_cleared_per_target':True,
            'pinned_static_gate_checkpoints_may_be_used':True,
            'production_gate_limit_unchanged':8192,
            'full_date_certified':False,'certifiable':False,
            'pinned_reference_used_only_for_comparison':True,
            'elapsed_seconds':round(monotonic()-start,3)}


def main(argv=None):
    p=argparse.ArgumentParser()
    p.add_argument('--pinned-root',type=Path,required=True)
    p.add_argument('--candidate-evidence',type=Path,required=True)
    p.add_argument('--evidence',type=Path,required=True)
    p.add_argument('--worker-timeout',type=int,default=180)
    p.add_argument('--total-timeout',type=int,default=700)
    args=p.parse_args(argv)
    try:
        report=execute(args)
    except Exception as exc:
        report={'status':'FAIL_PINNED_THREE_BY_FIVE_DIFFERENTIAL',
                'error_type':type(exc).__name__,'error':str(exc)[:1500],
                'full_date_certified':False,'certifiable':False}
    args.evidence.parent.mkdir(parents=True,exist_ok=True)
    args.evidence.write_text(json.dumps(report,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,sort_keys=True))
    return 0 if report['status']==PASS else 2


if __name__=='__main__':
    raise SystemExit(main())
