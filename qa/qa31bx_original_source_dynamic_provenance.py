#!/usr/bin/env python3
"""QA31BX: offline, finite, original-signed source/dynamic opcode provenance audit.

Python 3.11+; no interpreter execution, no network, no dependency on prior
QA31BW algorithms. Optional `orjson` accelerates JSON parsing. The signed
original source bytes can be supplied with --original-source, otherwise the
static-byte oracle is explicitly classified as an external byte attestation.

Usage:
  python qa31bx_original_source_dynamic_provenance.py \
    --ai QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip \
    --bw QA31BW_BEFUNGE98_KYRGYZ_EFFECTIVE_ADDRESS_20261121.zip \
    --output QA31BX_RESULT.json [--original-source ORIGINAL.b98]
"""
from __future__ import annotations
import argparse
import copy
import gzip
import hashlib
import io
import json
from pathlib import Path
import zipfile
try:
    import orjson
except ImportError:
    orjson = None

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
SOURCE = '560d6aa5807a7f766213a33835cce85eab0fa40c'
SOURCE_BYTES = 1836425
AI_SHA256 = '9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49'
BW_SHA256 = 'a9e76afb498ab922fb5086254edf9b59c96ada07ead73ba5f1ee37726c847628'
AH_SHA256 = '4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271'
Y_SHA256 = '1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a'
COORD_FETCH = (1500, 1860)
COORD_UNVISITED = (1500, 1881)
COORD_G_IP = (377, 1240)
COORD_G_ADDR = (79, 1710)
STATIC_SOURCE_FROM_INDEPENDENT_GIT_BLOB_REHASH = {COORD_FETCH: 32, COORD_UNVISITED: 46}


def ensure(test: bool, message: str) -> None:
    if not test:
        raise AssertionError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse(data: bytes):
    return orjson.loads(data) if orjson is not None else json.loads(data)


def read_json_lines(data: bytes):
    return [parse(line) for line in data.splitlines() if line]


def locked_zip(raw: bytes, sha: str, name: str) -> zipfile.ZipFile:
    ensure(sha256(raw) == sha, f'{name} SHA-256 does not match immutable pin')
    z = zipfile.ZipFile(io.BytesIO(raw))
    ensure(z.testzip() is None, f'{name}: ZIP CRC invalid')
    return z


def original_bytes(source_path: Path | None):
    if source_path is None:
        return dict(STATIC_SOURCE_FROM_INDEPENDENT_GIT_BLOB_REHASH), 'INDEPENDENT_CONNECTOR_GIT_OBJECT_ATTESTATION; NOT REHASHED BY LOCAL PYTHON'
    b = source_path.read_bytes()
    ensure(len(b) == SOURCE_BYTES, 'Original source byte size differs')
    ensure(hashlib.sha1(b'blob ' + str(len(b)).encode() + b'\0' + b).hexdigest() == SOURCE,
           'Canonical original Git object SHA-1 mismatch')
    rows = b.split(b'\n')
    ensure(len(rows) > COORD_UNVISITED[1], 'Source shorter than target rows')
    static = {}
    for (x, y), expected in STATIC_SOURCE_FROM_INDEPENDENT_GIT_BLOB_REHASH.items():
        static[(x, y)] = rows[y][x] if x < len(rows[y]) else 32
        ensure(static[(x, y)] == expected, f'Static source byte mismatch at {(x,y)}')
    return static, 'LOCAL_FULL_SOURCE_GIT_OBJECT_SHA1_AND_SIZE_VERIFIED'


def read_signatures(ai: zipfile.ZipFile):
    ah_name = 'QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip'
    ah = locked_zip(ai.read(ah_name), AH_SHA256, 'AH')
    y_name = 'QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip'
    y = locked_zip(ah.read(y_name), Y_SHA256, 'Y')
    ai_m = parse(ai.read('QA31AI_MANIFEST.json'))
    ah_m = parse(ah.read('QA31AH_MANIFEST.json'))
    y_m = parse(y.read('QA31Y_MANIFEST.json'))
    for z, manifest, name in [(ai, ai_m, 'AI'), (ah, ah_m, 'AH'), (y, y_m, 'Y')]:
        if 'project_id' in manifest:
            ensure(manifest['project_id'] == PROJECT, f'{name} project mismatch')
        members = manifest.get('files', manifest.get('members', {}))
        ensure(bool(members), f'{name} empty manifest')
        for file, record in members.items():
            expected = record['sha256'] if isinstance(record, dict) else record
            ensure(sha256(z.read(file)) == expected, f'{name} SHA of {file} changed')
    return y, y_m


def verify_bw(bw: zipfile.ZipFile):
    m = parse(bw.read('MANIFEST.json'))
    ensure(m['project_id'] == PROJECT and m['qa'] == 'QA31BW', 'Wrong BW scope')
    for name, expected in m['files'].items():
        ensure(sha256(bw.read(name)) == expected, 'BW member SHA mismatch: '+name)
    summary = parse(bw.read('qa31bw_summary.json'))
    ensure(summary['project_id'] == PROJECT and summary['source_git_blob_sha1_from_original_signed_receipts'] == SOURCE, 'Wrong BW input')
    witnesses = read_json_lines(bw.read('qa31bw_selected_original_sites.jsonl'))
    index = {}
    for w in witnesses:
        key = (w['case'], w['kind'])
        ensure(key not in index, 'Duplicate BW case/kind')
        index[key] = w
    ensure(len(witnesses) == 280 and sum(w['kind']=='fetch' for w in witnesses)==140,
           'BW expected 140 fetch and 140 independent g controls')
    control_rows = read_json_lines(bw.read('qa31bw_untouched_controls.jsonl'))
    ensure(len(control_rows)==12 and len({r['case'] for r in control_rows})==12, 'BW original controls count')
    return index, {r['case']:r for r in control_rows}


def strict_equal_observation(actual, expected):
    """Standalone focused oracle; expected witness data never supplies a writer."""
    ensure(actual['case'] == expected['case'], 'case identifier')
    for k in ('kind','t','ip','effective_address','observed_value_or_opcode','physical_prior_p_writer'):
        ensure(actual[k] == expected[k], f'original witness mismatch: {k}, {actual["case"]}')
    return True


def mutation_matrix(baseline):
    """Detached corruptions of a real newly reconstructed original fetch witness.

    A corruption succeeds only when the focused predicate rejects it.
    No native trace, source or original archive is edited.
    """
    ensure(baseline['kind']=='fetch' and baseline['physical_prior_p_writer'] is not None, 'hostile baseline')
    corrupt=[]
    changes={
        'case': 'synthetic_case', 'kind':'g', 't':baseline['t']+1,
        'ip':[1500,1881], 'effective_address':[1500,1881],
        'observed_value_or_opcode': 32,
    }
    for name,value in changes.items():
        t=copy.deepcopy(baseline);t[name]=value;corrupt.append((name,t))
    for name,fn in [
        ('writer_tick',lambda v:v.__setitem__('tick',v['tick']+1)),
        ('writer_ip',lambda v:v.__setitem__('ip',[95,480])),
        ('writer_value',lambda v:v.__setitem__('stored_value',61)),
        ('writer_missing',lambda v: v.clear()),
    ]:
        t=copy.deepcopy(baseline);fn(t['physical_prior_p_writer']);corrupt.append((name,t))
    for name in ('remove_ip','remove_kind','remove_writer'):
        t=copy.deepcopy(baseline);t.pop({'remove_ip':'ip','remove_kind':'kind','remove_writer':'physical_prior_p_writer'}[name]);corrupt.append((name,t))
    ensure(len(corrupt)>=12,'At least 12 detached hostile controls')
    rejected=[]
    for name,changed in corrupt:
        try:
            strict_equal_observation(changed,baseline)
        except (AssertionError,KeyError):
            rejected.append(name)
    ensure(len(rejected)==len(corrupt),'Detached hostile bypassed focused predicate')
    return rejected


def validate_receipt(case, source):
    ensure(source == SOURCE and case['status']=='HALT' and case['error'] is None,
           'nonoriginal/nonHALT receipt')
    ensure(0 < case['steps'] <= 25000, 'steps out of signed limits')
    ensure(sha256(bytes.fromhex(case['raw_hex'])) == case['raw_sha256'], 'original raw input SHA mismatch')


def hostile_source_and_receipt_controls(case: dict, source_byte_map: dict):
    """Detached receipt / source-attestation mutations, not regenerated Native traces."""
    cases = []
    baseline = copy.deepcopy(case)
    def c(name, **values):
        x = copy.deepcopy(baseline)
        x.update(values)
        cases.append((name, SOURCE, x))
    cases.append(('wrong_source_sha', '0' * 40, copy.deepcopy(baseline)))
    c('status_not_halt', status='TIMEOUT')
    c('non_null_error', error='synthetic_error')
    c('zero_steps', steps=0)
    c('too_many_steps', steps=25001)
    c('invalid_raw_sha', raw_sha256='0'*64)
    c('raw_hex_corruption', raw_hex=baseline['raw_hex']+'ff')
    c('invalid_raw_hex', raw_hex='xyz')
    c('empty_raw_hex', raw_hex='')
    for name in ('status', 'error', 'steps', 'raw_sha256', 'raw_hex'):
        x = copy.deepcopy(baseline)
        x.pop(name)
        cases.append(('missing_'+name, SOURCE, x))
    rejected=[]
    for name, source, x in cases:
        try:
            validate_receipt(x, source)
        except (AssertionError, KeyError, ValueError):
            rejected.append(name)
    ensure(len(rejected)==len(cases) and len(rejected)>=12,
           'Receipt/source hostile bypassed receipt predicate')
    ensure(source_byte_map==STATIC_SOURCE_FROM_INDEPENDENT_GIT_BLOB_REHASH,
           'No validated original source-byte attestation available')
    return rejected


def execute(ai_raw: bytes, bw_raw: bytes, source_path: Path | None):
    static, source_gate = original_bytes(source_path)
    ensure(static[COORD_FETCH]==32 and static[COORD_UNVISITED]==46,'external original source byte pin mismatch')
    with locked_zip(bw_raw, BW_SHA256, 'BW') as bw, locked_zip(ai_raw, AI_SHA256, 'AI') as ai:
        witness, controls=verify_bw(bw)
        with_scope=[]; receipt_count=0; selected_fetches=[]; selected_g=[]; y1881_fetches=0
        original_ticks=0; physical_p_to_1881=0; cases_seen=set(); controls_verified=set()
        unexpected_mutators=0; baseline_receipt=None
        y,y_m=read_signatures(ai)
        with y:
            shard_names=sorted(n for n in y.namelist() if n.startswith('QA31V_SHARD') and n.endswith('.zip'))
            ensure(len(shard_names)==8,'Expected eight original immutable ZIPs')
            for shard_name in shard_names:
                with locked_zip(y.read(shard_name),y_m['files'][shard_name],shard_name) as shard:
                    receipt=parse(shard.read('qa31v_receipt.json'))
                    ensure(receipt['source_blob']==SOURCE and receipt['source_modified'] is False, 'source changed in shard')
                    for case in receipt['cases']:
                        validate_receipt(case,receipt['source_blob'])
                        if baseline_receipt is None: baseline_receipt=copy.deepcopy(case)
                        label=case['label']
                        ensure(label not in cases_seen,'duplicate signed original case')
                        cases_seen.add(label)
                        receipt_count+=1
                        packed=shard.read(case['trace'])
                        ensure(sha256(packed)==case['trace_sha256'],'signed gzip SHA mismatch: '+label)
                        last={}; fetched=[]; reads=[]; first=None; tick=0; previous_next=None
                        with gzip.GzipFile(fileobj=io.BytesIO(packed)) as gz:
                            for raw_line in gz:
                                e=parse(raw_line)
                                tick+=1
                                ensure(e['t']==tick and e['string'] is False, 'bad tick/string: '+label)
                                ip=tuple(e['ip']); op=e['op'];
                                if op in (105,115,123,125):unexpected_mutators+=1
                                if previous_next is not None:
                                    ensure(tuple(previous_next)==ip,'IP continuity error '+label)
                                previous_next=e['next']
                                if op==112:
                                    st=e['pre'];ensure(len(st)>=3, 'unexpected p underflow in physical original')
                                    yv,xv,v=st[-1],st[-2],st[-3]
                                    ensure(type(yv) is int and type(xv) is int,'nonintegral coordinate')
                                    last[(xv,yv)]=(tick,list(ip),v)
                                    if (xv,yv)==COORD_UNVISITED:physical_p_to_1881+=1
                                if ip==COORD_FETCH or ip==COORD_UNVISITED:
                                    if ip==COORD_UNVISITED:y1881_fetches+=1
                                    else:
                                        owner=last.get(COORD_FETCH)
                                        fetched.append({'case':label,'kind':'fetch','t':tick,'ip':list(ip),
                                                        'effective_address':list(ip),'observed_value_or_opcode':op,
                                                        'physical_prior_p_writer':({'tick':owner[0],'ip':owner[1],'stored_value':owner[2]} if owner else None)})
                                if ip==COORD_G_IP and op==103:
                                    st=e['pre'];ensure(len(st)>=2 and (st[-2],st[-1])==COORD_G_ADDR,'g effective address')
                                    owner=last.get(COORD_G_ADDR)
                                    reads.append({'case':label,'kind':'g','t':tick,'ip':list(ip),
                                                  'effective_address':list(COORD_G_ADDR),
                                                  'observed_value_or_opcode':e['post'][-1],
                                                  'physical_prior_p_writer':({'tick':owner[0],'ip':owner[1],'stored_value':owner[2]} if owner else None)})
                        ensure(tick==case['steps'], 'signed STEP total mismatch '+label)
                        original_ticks += tick
                        if label in controls:
                            c=controls[label]
                            ensure(c['steps']==tick and c['trace_sha256']==case['trace_sha256'],'signed control mismatch')
                            controls_verified.add(label)
                        for obs in fetched+reads:
                            strict_equal_observation(obs,witness[(label,obs['kind'])])
                        selected_fetches.extend(fetched);selected_g.extend(reads)
                        with_scope.append({'case':label,'steps':tick,'fetches':len(fetched),
                                           'source_fetch_byte':static[COORD_FETCH],
                                           'dynamic_fetch':fetched[0]['observed_value_or_opcode'] if fetched else None})
        ensure(receipt_count==200 and len(cases_seen)==200, 'Not all 200 original receipts present')
        ensure(len(selected_fetches)==140 and len(selected_g)==140, 'Not exactly 140 signed original sites each')
        ensure(len(controls_verified)==12, '12 original untouched controls missing')
        ensure(y1881_fetches==0, 'Original y1881 was physically fetched; previously UNKNOWN claim invalid')
        for fetch in selected_fetches:
            ensure(fetch['observed_value_or_opcode']==62 and fetch['physical_prior_p_writer']['stored_value']==62,
                   'Original dynamic opcode not explained by physical p')
            ensure(fetch['physical_prior_p_writer']['tick']<fetch['t'],'writer not physically earlier')
        ensure(original_ticks==3628390, 'Physical original corpus size unexpected')
        ensure(unexpected_mutators==0, 'Unaccounted i/s/block mutator in signed originals')
        hostile=mutation_matrix(selected_fetches[0])
        hostiles_sr=hostile_source_and_receipt_controls(baseline_receipt,static)
        return {
            'project_id':PROJECT,'qa':'QA31BX','scope':'ORIGINAL_SIGNED_FINITE_ONLY',
            'source_git_sha1':SOURCE,'source_bytes':SOURCE_BYTES,'source_gate':source_gate,
            'source_initial_bytes':{'1500,1860':static[COORD_FETCH],'1500,1881':static[COORD_UNVISITED]},
            'original_signed_halt_receipts':receipt_count,'original_steps_independently_parsed':original_ticks,
            'independently_reconstructed_g_witness_matches':len(selected_g),
            'independently_reconstructed_fetch_witness_matches':len(selected_fetches),
            'all_fetch_original_source_space_vs_dynamic_greater_than':len(selected_fetches),
            'unvisited_original_fetch_1500_1881':y1881_fetches,
            'physical_original_p_to_1500_1881':physical_p_to_1881,
            'untouched_original_signed_controls':len(controls_verified),
            'detached_witness_hostile_rejections':hostile,
            'detached_source_receipt_hostile_rejections':hostiles_sr,
            'original_i_s_open_close_observations':unexpected_mutators,
            'original_unobserved_1881_dynamic_value':'UNKNOWN',
            'changed_run_reachability_source_so_stack_output':'UNKNOWN',
            'new_native_runs':0,'new_ci_runs':0,'stage1_pass':False,
            'records':with_scope,
        }


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--ai',required=True,type=Path)
    p.add_argument('--bw',required=True,type=Path)
    p.add_argument('--original-source',type=Path)
    p.add_argument('--output',required=True,type=Path)
    args=p.parse_args()
    report=execute(args.ai.read_bytes(),args.bw.read_bytes(),args.original_source)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print('QA31BX_LOCAL_FINITE_PASS receipts={} steps={} fetch={} g={} controls={} hostile={} source_gate={}'.format(
        report['original_signed_halt_receipts'],report['original_steps_independently_parsed'],
        report['independently_reconstructed_fetch_witness_matches'],
        report['independently_reconstructed_g_witness_matches'],
        report['untouched_original_signed_controls'],len(report['detached_source_receipt_hostile_rejections'])+len(report['detached_witness_hostile_rejections']),report['source_gate']))
    print('QA31BX_NO_NATIVE_NO_CI_NO_STAGE1_PASS')

if __name__=='__main__':
    main()
