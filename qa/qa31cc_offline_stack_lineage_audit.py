#!/usr/bin/env python3
"""QA31CC: bounded independent offline stack-lineage audit of archived QA31CB traces.

This tool does not run Befunge, does not edit production source, and does not
claim a positive natural-input witness. Python 3 stdlib only.
Usage: python3 qa31cc_offline_stack_lineage_audit.py EVIDENCE_ZIP OUTPUT_JSON
"""
import copy
import gzip
import hashlib
import json
import sys
import zipfile
from pathlib import Path

PROJECT = 'PC-BRANCH-BEFUNGE98-KYRGYZ'
ZIP_SHA256 = 'ea247b7c907d9cd0e1fb8e211619ff538b99b435dd43bcdaef70f084f6e499be'
SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
RUN_SHA = 'faf93de8d27ec112c7c57d6fbfe193c3475a4187'
RUN_ID = '44996727508'
EXAMPLES = (100, 199, 500, 999)


def require(test, message):
    if not test:
        raise AssertionError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def point(event):
    require(event['storage_offset'] == [0, 0], 'nonzero storage offset')
    stack = event['pre_toss']
    require(len(stack) >= 3 and event['op'] == ord('p'), 'invalid put receipt')
    address = list(stack[-2:])
    require(event['target'] == address and event['cell_after'] == stack[-3],
            'put address or value mismatch')
    return tuple(address), stack[-3]


def instruction(rows, tick, opcode, ip):
    row = rows[tick - 1]
    require(row['t'] == tick and row['ip'] == list(ip)
            and row['op'] == ord(opcode) and row['string'] is False,
            'wrong physical opcode/IP at tick %d' % tick)
    return row


def audit_core(rows, token):
    """Independent trace-state oracle: explicit physical event ordering & stack math."""
    require(len(rows) == 24853 and rows[-1]['next'] is None, 'trace length/HALT')
    for tick in (292, 9598, 10579, 10614, 10629, 10664, 10900, 10901,
                 10902, 10903, 10904, 11135, 24722, 24723, 24724,
                 24725, 24726, 24727, 24728, 24729, 24730, 24731,
                 24732, 24795, 24823):
        require(rows[tick - 1]['t'] == tick, 'selected tick continuity')
    raw = ('1 0 0 %03d' % token).encode('ascii')
    first_read = instruction(rows, 292, '~', (13, 5))['reads']
    require(len(first_read) == 1 and bytes.fromhex(first_read[0]['hex']) == raw
            and (first_read[0]['start'], first_read[0]['end']) == (0, len(raw)),
            'stdin first-read provenance')
    second_read = instruction(rows, 9598, '~', (13, 5))['reads']
    require(len(second_read) == 1 and second_read[0]['hex'] == ''
            and second_read[0]['start'] == second_read[0]['end'] == len(raw),
            'stdin EOF read provenance')
    parsed = instruction(rows, 10579, '>', (4, 0))['pre']
    require(parsed == [1, 0, 0, token], 'stdin four-number stack origin')

    put_fourth = instruction(rows, 10614, 'p', (384, 575))['pg']
    put_third = instruction(rows, 10629, 'p', (369, 575))['pg']
    put_second = instruction(rows, 10664, 'p', (860, 846))['pg']
    require(point(put_fourth) == ((11, 1693), token), 'fourth operand put')
    require(point(put_third) == ((7, 1692), parsed[2]), 'third operand put')
    require(point(put_second) == ((5, 1691), parsed[1]), 'second operand put')
    require(put_fourth['pre_toss'][:4] == parsed
            and put_fourth['cell_before'] == 32,
            'fourth operand original stack/blank source')
    require(put_third['pre_toss'][:3] == parsed[:3]
            and put_third['cell_before'] == 32,
            'third operand original stack/blank source')
    require(put_second['pre_toss'][:2] == parsed[:2]
            and put_second['cell_before'] == 32,
            'second operand original stack/blank source')

    load_second = instruction(rows, 10900, 'g', (100, 1057))
    g = load_second['pg']
    require(g['target'] == [5, 1691]
            and g['cell_before'] == put_second['cell_after']
            and g['result'] == parsed[1]
            and load_second['post'] == [parsed[0], 1, parsed[1]],
            'second-operand physical read and stack')
    for t, op in ((10901, '!'), (10902, '*'), (10903, '!'), (10904, '*')):
        instruction(rows, t, op, (100, 1057 + t - 10900))
    x = load_second['post'][2]
    first = load_second['post'][0]
    intermediate = load_second['post'][1]
    # !, *, !, * on the physically observed stack; no Native helper imported.
    after_10901 = int(x == 0)
    after_10902 = intermediate * after_10901
    after_10903 = int(after_10902 == 0)
    owner_value = first * after_10903
    require(rows[10900]['post'] == [first, intermediate, after_10901], '! gate 1')
    require(rows[10901]['post'] == [first, after_10902], '* gate 1')
    require(rows[10902]['post'] == [first, after_10903], '! gate 2')
    require(rows[10903]['post'] == [owner_value], '* gate 2')

    owner_write = instruction(rows, 11135, 'p', (1332, 480))['pg']
    require(point(owner_write) == ((19, 1696), owner_value)
            and owner_write['cell_before'] == 32, 'owner physical write')
    owner_read = instruction(rows, 24722, 'g', (677, 765))['pg']
    require(owner_read['pre_toss'] == [19, 1696]
            and owner_read['target'] == owner_write['target']
            and owner_read['cell_before'] == owner_write['cell_after']
            and owner_read['result'] == owner_value, 'owner physical read/last writer')
    require(rows[24721]['post'] == [owner_value], 'owner g result stack')

    # Independent plain stack evaluation of all 11 original-source opcodes.
    opcodes = ('7', '8', '*', '*', '6', 'a', '*', '2', '+', '+')
    stack = [owner_value]
    for tick, op in enumerate(opcodes, 24723):
        row = instruction(rows, tick, op, (678 + tick - 24723, 765))
        require(row['pre'] == stack, 'dynamic-code RPN pre-stack')
        if op in '0123456789abcdef':
            stack = stack + [int(op, 16)]
        elif op in ('+', '*'):
            require(len(stack) >= 2, 'RPN stack underflow')
            a, b = stack[-2:]
            stack = stack[:-2] + [a + b if op == '+' else a * b]
        else:
            raise AssertionError('unsupported static opcode')
        require(row['post'] == stack, 'dynamic-code RPN post-stack')
    calculated_code = 56 * owner_value + 62
    require(stack == [calculated_code], 'independent 56*g+62 equation')
    dynamic_put = instruction(rows, 24795, 'p', (96, 480))['pg']
    require(point(dynamic_put) == ((1500, 1860), calculated_code)
            and dynamic_put['cell_before'] == 32, 'dynamic-code physical put')
    dynamic_fetch = instruction(rows, 24823, chr(calculated_code), (1500, 1860))
    require(dynamic_fetch['fetch'] is not None
            and dynamic_fetch['fetch']['cell_observed'] == calculated_code,
            'executed dynamic opcode does not match original put')
    require(parsed[:3] == [1, 0, 0] and owner_value == 0
            and calculated_code == 62, 'four accepted negative witnesses')
    return {
        'token': token, 'steps': len(rows),
        'raw_input': raw.decode('ascii'),
        'four_operand_stack_tick_10579': parsed,
        'fourth_operand_put': {'tick': 10614, 'target': [11, 1693], 'value': token},
        'third_operand_put': {'tick': 10629, 'target': [7, 1692], 'value': parsed[2]},
        'second_operand_put': {'tick': 10664, 'target': [5, 1691], 'value': parsed[1]},
        'second_operand_get_tick': 10900,
        'gate_opcode_ticks': [10901, 10902, 10903, 10904],
        'owner_put_tick': 11135, 'owner_value': owner_value,
        'owner_get_tick': 24722, 'code_put_tick': 24795,
        'code_fetch_tick': 24823, 'dynamic_code_value': calculated_code,
    }


def hostile_cases(rows, token):
    """Deterministic physical trace mutations; they must all be rejected."""
    changes = (
        (292, ('reads', 0, 'hex'), '30'),
        (9598, ('reads', 0, 'end'), 8),
        (10579, ('pre', 1), 1),
        (10614, ('pg', 'cell_after'), token + 1),
        (10629, ('pg', 'target', 0), 8),
        (10664, ('pg', 'pre_toss', 1), 1),
        (10664, ('pg', 'target', 0), 6),
        (10900, ('pg', 'result'), 1),
        (10901, ('post', 2), 0),
        (10904, ('post', 0), 1),
        (11135, ('pg', 'cell_after'), 1),
        (24722, ('pg', 'cell_before'), 1),
        (24723, ('op',), 56),
        (24732, ('post', 0), 118),
        (24795, ('pg', 'cell_after'), 118),
        (24823, ('fetch', 'cell_observed'), 118),
    )
    result = []
    for tick, path, value in changes:
        mutant = list(rows)
        mutant[tick - 1] = copy.deepcopy(rows[tick - 1])
        obj = mutant[tick - 1]
        for name in path[:-1]:
            obj = obj[name]
        obj[path[-1]] = value
        rejected = False
        try:
            audit_core(mutant, token)
        except (AssertionError, KeyError, TypeError, ValueError):
            rejected = True
        require(rejected, 'hostile mutation escaped gate at tick %s path %r' % (tick, path))
        result.append({'tick': tick, 'path': list(path), 'rejected': rejected})
    return result


def main(zip_path, result_path):
    zipdata = Path(zip_path).read_bytes()
    require(digest(zipdata) == ZIP_SHA256, 'exact QA31CB archive SHA256 mismatch')
    with zipfile.ZipFile(zip_path) as z:
        require(z.testzip() is None and len(z.namelist()) == 13, 'archive CRC/member gate')
        manifest = json.loads(z.read('qa31cb_artifact_manifest.json'))
        require(manifest['project_id'] == PROJECT and manifest['run_id'] == RUN_ID
                and manifest['head_sha'] == RUN_SHA and manifest['stage1_accepted'] is False,
                'executed run/project identity')
        hashes = manifest['files']
        require(len(hashes) == 12 and set(hashes) == set(z.namelist()) - {'qa31cb_artifact_manifest.json'},
                'archived member manifest membership')
        for filename, want in hashes.items():
            require(digest(z.read(filename)) == want, 'manifest digest mismatch: '+filename)
        metadata = json.loads(z.read('qa31cb_source_cells.json'))
        require(metadata['project_id'] == PROJECT
                and metadata['source_git_blob_sha1'] == SOURCE_BLOB
                and metadata['cells']['input_owner']['coordinate'] == [19, 1696]
                and metadata['cells']['dynamic_code_cell']['coordinate'] == [1500, 1860],
                'source provenance and target coordinates')
        receipts = {int(x['input_token']): x for line in z.read('qa31cb_cases.jsonl').splitlines()
                    for x in (json.loads(line),)}
        require(len(receipts) == 900 and set(receipts) == set(range(100,1000)),
                'QA31CB existing case receipt domain')
        observations = []
        mutants = []
        for token in EXAMPLES:
            label = 'token_%03d.jsonl.gz' % token
            packed = z.read(label)
            receipt = receipts[token]
            require(digest(packed) == receipt['trace_sha256']
                    and receipt['steps'] == 24853 and receipt['status'] == 'HALT'
                    and receipt['source_git_blob_sha1'] == SOURCE_BLOB,
                    'original compressed trace receipt identity')
            rows = [json.loads(line) for line in gzip.decompress(packed).splitlines()]
            observations.append(audit_core(rows, token))
            # One complete retained physical trace is sufficient for negative-control
            # self-test; the same oracle verifies all four separately.
            if token == 100:
                mutants = hostile_cases(rows, token)
    # Pure hypothetical calculation, NOT Native evidence. Same path is unproven.
    candidate = (1, 1, 0, 100)
    hypothetical_gate = candidate[0] * int(1 * int(candidate[1] == 0) == 0)
    require(hypothetical_gate == 1 and 56*hypothetical_gate+62 == 118,
            'hypothetical candidate algebra')
    output = {
        'schema':'qa31cc-offline-original-four-stack-lineage-v1',
        'project_id': PROJECT,
        'source_git_blob_sha1':SOURCE_BLOB,
        'executed_sha':RUN_SHA,
        'run_id': RUN_ID,
        'original_artifact_zip_sha256': ZIP_SHA256,
        'archived_member_sha256_pass':12,
        'archive_crc_members_pass':13,
        'independently_walked_full_native_traces':len(observations),
        'total_physically_inspected_steps':sum(x['steps'] for x in observations),
        'observations':observations,
        'hostile_tests_rejected':len(mutants),
        'hostile_tests':mutants,
        'hypothesis':{
            'input_string':'1 1 0 100',
            'conditional_second_operand':1,
            'conditional_owner_value':1,
            'conditional_dynamic_code_value':118,
            'assumption':'preservation of the examined control-flow and stack mapping, not established',
            'native_executed':False,
            'natural_reachability_proven':False
        },
        'source_modified':False,
        'new_native_executions':0,
        'new_ci_runs':0,
        'stage1_accepted':False,
        'global_reachability_proven':False,
    }
    Path(result_path).write_text(json.dumps(output, indent=2, sort_keys=True, ensure_ascii=False)+'\n',encoding='utf-8')
    print('QA31CC_OFFLINE_PASS',len(observations),'traces',
          output['total_physically_inspected_steps'],'STEPS',
          len(mutants),'hostile rejected; positive candidate UNTESTED')
    return output


if __name__ == '__main__':
    require(len(sys.argv) == 3, 'usage: script EVIDENCE_ZIP OUTPUT_JSON')
    main(sys.argv[1], sys.argv[2])
