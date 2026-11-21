#!/usr/bin/env python3
"""QA31P: bounded original QA31D signed route and q=(1,49) last writer audit.

Replays stack/FungeSpace operations for exactly the first 9,607 physical steps
of two existing Native traces. Does not execute a Befunge runtime, and makes
no claim about global reachability or Stage1 acceptance.
"""
import argparse
import gzip
import hashlib
import io
import json
import zipfile
from pathlib import Path

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
ZIP_SHA256 = 'b8df61e31a3f28bfcc21bbccb4d2ee26b5ccfeca534969e87d95a211fbb40eeb'
STEP_LIMIT = 9607
CASES = {
    'valid00': (b'0 0 0 0\n', 17387),
    'valid01': (b'0 0 0 1\n', 19713),
}


def require(ok, why):
    if not ok:
        raise AssertionError(why)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def source_rows(path):
    raw = Path(path).read_bytes()
    blob = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
    require(blob == SOURCE_BLOB, 'original-source Git blob mismatch: ' + blob)
    return raw.splitlines()


def source_cell(rows, xy):
    x, y = xy
    return rows[y][x] if 0 <= y < len(rows) and 0 <= x < len(rows[y]) else 32


def load_signed(path):
    data = Path(path).read_bytes()
    require(digest(data) == ZIP_SHA256, 'original QA31D ZIP SHA mismatch')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        require(archive.testzip() is None, 'outer ZIP CRC')
        names = set(archive.namelist())
        require(names == {'qa31d_valid00.steps.gz', 'qa31d_valid01.steps.gz',
                          'qa31d_native.json', 'qa31d_independent.json',
                          'native.log', 'audit.log'}, 'unexpected ZIP members')
        receipt = json.loads(archive.read('qa31d_native.json'))
        independent = json.loads(archive.read('qa31d_independent.json'))
        require(receipt['source_git_blob'] == SOURCE_BLOB and
                receipt['source_modified'] is False and
                receipt['ip_relocated'] is False and
                receipt['stage1_complete'] is False, 'receipt source/scope')
        require(independent['steps'] == 37100 and
                independent['hostile_receipts_rejected'] == 10 and
                independent['stage1_complete'] is False, 'historical auditor scope')
        case_receipts = {v['label']: v for v in receipt['records']}
        require(set(case_receipts) == set(CASES), 'case names')
        out = {}
        for label, (stdin, count) in CASES.items():
            spec = case_receipts[label]
            name = 'qa31d_' + label + '.steps.gz'
            zipped = archive.read(name)
            require(spec['step_trace_file'] == name and spec['steps'] == count,
                    label + ' trace identity')
            require(digest(zipped) == spec['step_trace_sha256'],
                    label + ' signed trace SHA')
            require(spec['input_sha256'] == digest(stdin), label + ' natural stdin')
            events = spec['read_events']
            require(events[0]['delivered_hex'] == stdin.hex() and
                    events[0]['tick'] == 292 and events[0]['method'] == 'readline' and
                    events[0]['start'] == 0 and events[0]['end'] == len(stdin),
                    label + ' first read receipt')
            require(events[1]['tick'] == 9340 and events[1]['delivered_hex'] == '' and
                    events[1]['start'] == events[1]['end'] == len(stdin),
                    label + ' EOF receipt')
            require(len(events) == 2, label + ' event count')
            lines = gzip.decompress(zipped).splitlines()
            require(len(lines) == count, label + ' physical trace length')
            first = []
            for index, line in enumerate(lines[:STEP_LIMIT], 1):
                fields = line.split(b'\t')
                require(len(fields) == 7, label + ' TSV record width')
                t, x, y, dx, dy, opcode, string_mode = map(int, fields)
                require(t == index and string_mode == 0, label + ' STEP index/mode')
                first.append((t, x, y, dx, dy, opcode))
            require(spec['j_observations'][0]['pre_toss'] == [61] and
                    spec['j_observations'][0]['tick'] == STEP_LIMIT and
                    spec['j_observations'][0]['next_step'][1:3] == [176, 38],
                    label + ' historical gate metadata')
            out[label] = first
        return out


def replay(steps, stdin, rows):
    stack, overlay, writes, read_events, gate_events = [], {}, [], [], []
    consumed = 0
    last_owner = None

    def pop():
        return stack.pop() if stack else 0

    for t, x, y, dx, dy, op in steps:
        require((dx, dy) != (0, 0), 'zero direction')
        require(op == overlay.get((x, y), source_cell(rows, (x, y))),
                'signed opcode/source mismatch at tick %d: %s' % (t, (x, y)))
        c = chr(op)
        if c in '0123456789abcdef':
            stack.append(int(c, 16))
        elif c in '+-*`':
            b, a = pop(), pop()
            stack.append(a + b if c == '+' else a - b if c == '-' else
                         a * b if c == '*' else int(a > b))
        elif c == '!':
            stack.append(int(pop() == 0))
        elif c == '~':
            if consumed < len(stdin):
                stack.append(stdin[consumed])
                consumed += 1
            else:
                require(t == 9340, 'unexpected EOF attempt')
        elif c == 'g':
            y0, x0 = pop(), pop()
            addr = (x0, y0)
            value = overlay.get(addr, source_cell(rows, addr))
            stack.append(value)
            if addr == (1, 49):
                read_events.append([t, x, y, value, last_owner])
        elif c == 'p':
            y0, x0, value = pop(), pop(), pop()
            addr = (x0, y0)
            overlay[addr] = value
            if addr == (1, 49):
                writes.append([t, x, y, value])
                last_owner = t
        elif c == 'j':
            operand = pop()
            if (x, y) == (114, 38):
                gate_events.append([t, operand])
        elif c == 'x':
            pop(); pop()
        elif c in '>v#':
            pass
        else:
            raise AssertionError('unmodeled opcode %r at tick %d' % (c, t))
    require(consumed == len(stdin), 'not all input bytes were used')
    require(writes == [[146,106,2,0], [2408,248,26,1],
                       [4670,248,26,2], [6932,248,26,3],
                       [9194,248,26,4]], 'q last-writer chain mismatch: %r' % writes)
    require(read_events[-1] == [9557,57,38,4,9194],
            'last q owner at row38 mismatch: %r' % read_events[-1:])
    require(gate_events == [[9607,61]], 'target j operand')
    require(stack == [], 'post-j stack must be empty')
    return {'signed_prefix_steps':len(steps), 'q_writes': writes,
            'q_reads': read_events, 'gate': gate_events[0],
            'bytes_consumed':consumed}


def hostile_controls(traces, rows):
    base = traces['valid00']
    attacks = [(146, 'op', ord('0')), (2408, 'op', ord('0')),
               (4670, 'op', ord('0')), (6932, 'op', ord('0')),
               (9194, 'op', ord('0')), (9557, 'op', ord('0')),
               (9607, 'op', ord('+')), (9607, 'x', 115),
               (2408, 'x', 249), (9557, 'y', 37)]
    indexes = {'x':1, 'y':2, 'op':5}
    accepted = 0
    for t, field, bad in attacks:
        mutated = list(base)
        original = list(mutated[t-1]); original[indexes[field]] = bad
        mutated[t-1] = tuple(original)
        try:
            replay(mutated, CASES['valid00'][0], rows)
        except (AssertionError, IndexError, ValueError, KeyError):
            accepted += 1
        else:
            raise AssertionError('hostile trace accepted: %d/%s' % (t, field))
    require(accepted == len(attacks) == 10, 'hostile rejection total')
    return accepted


def audit(traces, rows):
    a = replay(traces['valid00'], CASES['valid00'][0], rows)
    b = replay(traces['valid01'], CASES['valid01'][0], rows)
    require(a['q_writes'] == b['q_writes'] and a['gate'] == b['gate'],
            'last-writer/gate not invariant in valid input pair')
    require(all(s[:5] == t[:5] for s, t in zip(traces['valid00'], traces['valid01'])),
            'original pair diverged before gate')
    rejected = hostile_controls(traces, rows)
    return {
        'schema':'qa31p-signed-original-q-last-writer-v1',
        'project_id':'PC-BRANCH-BEFUNGE98-KYRGYZ',
        'source_git_blob':SOURCE_BLOB, 'qa31d_original_zip_sha256':ZIP_SHA256,
        'signed_physical_steps_checked': STEP_LIMIT * 2,
        'bounded_valid_stdin_cases': 2,
        'target_q_writes_per_case': len(a['q_writes']),
        'q_write_chain':a['q_writes'],
        'last_q_read':a['q_reads'][-1],
        'same_pre_j_counter_4_and_operand_61': True,
        'hostile_trace_mutations_rejected':rejected,
        'new_native_cases':0, 'global_reachability_proven':False,
        'source_owner_global_proven':False,
        'stage1_pass':False,
    }


def main():
    arg=argparse.ArgumentParser()
    arg.add_argument('original_source')
    arg.add_argument('original_qa31d_zip')
    arg.add_argument('--out',default='qa31p_counter.json')
    opts=arg.parse_args()
    report=audit(load_signed(opts.original_qa31d_zip), source_rows(opts.original_source))
    Path(opts.out).write_text(json.dumps(report, indent=2, sort_keys=True)+'\n')
    print('QA31P_ORIGINAL_SIGNED_19214_STEP_PREFIX_PASS')
    print('QA31P_Q_0_1_2_3_4_BOTH_VALID_CASES')
    print('QA31P_HOSTILE_TRACE_10_OF_10')
    print('QA31P_NO_NATIVE_NO_STAGE1_PASS')

if __name__ == '__main__':
    main()
