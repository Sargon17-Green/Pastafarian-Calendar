#!/usr/bin/env python3
"""QA31F: bounded, source-pinned prefix model. NOT a Native/EOF/Stage-1 proof."""
import hashlib
import json
from pathlib import Path

SOURCE_BLOB = '560d6aa5807a7f766213a33835cce85eab0fa40c'
SOURCE = Path(__file__).resolve().parents[1] / 'src' / 'interleaved_work_counts.b98'


def git_blob_sha(blob):
    return hashlib.sha1(b'blob ' + str(len(blob)).encode() + b'\x00' + blob).hexdigest()


def execute_prefix(lines, character_code):
    stack, written, events = [], {}, []
    x = y = 0
    dx, dy = 1, 0

    def pop():
        return stack.pop() if stack else 0

    def read(px, py):
        if (px, py) in written:
            return written[px, py]
        if py >= 0 and py < len(lines) and px >= 0 and px < len(lines[py]):
            return ord(lines[py][px])
        return 32

    for tick in range(1, 1001):
        px, py = x, y
        op = chr(read(x, y))
        if '0' <= op <= '9':
            stack.append(int(op))
        elif op == 'a':
            stack.append(10)
        elif op in ('+', '-', '*'):
            b, a = pop(), pop()
            stack.append(a + b if op == '+' else a - b if op == '-' else a * b)
        elif op == '!':
            stack.append(1 if pop() == 0 else 0)
        elif op == '>':
            dx, dy = 1, 0
        elif op == 'v':
            dx, dy = 0, 1
        elif op == '#':
            x, y = x + dx, y + dy
        elif op == '~':
            assert (x, y) == (13, 5), ('unexpected input site', x, y)
            stack.append(character_code)
        elif op == 'p':
            vy, vx, value = pop(), pop(), pop()
            written[vx, vy] = value
            if py == 5:
                events.append(['p', px, py, vx, vy, value])
        elif op == 'g':
            vy, vx = pop(), pop()
            value = read(vx, vy)
            stack.append(value)
            if py == 5:
                events.append(['g', px, py, vx, vy, value])
        elif op == 'j':
            count = pop()
            if py == 5:
                events.append(['j', px, py, count])
            x, y = x + count * dx, y + count * dy
        elif op == 'x':
            new_y, new_x = pop(), pop()
            if py == 5:
                events.append(['x', px, py, new_x, new_y])
            dx, dy = new_x, new_y
        elif op == ' ':
            pass
        else:
            raise AssertionError(f'unsupported instruction at {(px, py)}: {op!r}')
        x, y = x + dx, y + dy
        if (x, y) in ((10, 8), (10, 29)):
            assert stack == [], ('unexpected remaining stack', character_code, stack)
            return {'character_code': character_code, 'steps': tick,
                    'events': events, 'exit': [x, y], 'writes': len(written)}
        if x < 0 or y < 0 or x >= 10000 or y >= len(lines):
            raise AssertionError(('unexpected outbound IP', x, y))
    raise AssertionError(('prefix did not exit within bound', character_code))


def audit(source_bytes):
    assert git_blob_sha(source_bytes) == SOURCE_BLOB, 'immutable source blob mismatch'
    lines = source_bytes.decode('ascii').splitlines()
    assert lines[5][286] == 'x'
    assert lines[5][164] == 'j' and lines[5][225] == 'x'
    assert lines[5][60] == 'p' and lines[5][107] == 'g'
    results = [execute_prefix(lines, code) for code in range(256)]
    expected = [['p', 60, 5, 0, 49, 0], ['g', 107, 5, 0, 49, 0],
                ['j', 164, 5, 0], ['x', 225, 5, -215, 3]]
    for code, result in enumerate(results):
        assert result['steps'] == 532 and result['exit'] == [10, 8]
        assert result['writes'] == 4
        actual = result['events']
        exp = [entry.copy() for entry in expected]
        exp[0][-1] = code
        exp[1][-1] = code
        assert actual == exp, ('prefix divergence', code, actual)
    counterfactual = execute_prefix(lines, -1)
    assert counterfactual['steps'] == 532
    assert counterfactual['exit'] == [10, 29]
    assert counterfactual['events'] == [
        ['p', 60, 5, 0, 49, -1], ['g', 107, 5, 0, 49, -1],
        ['j', 164, 5, 61], ['x', 286, 5, -276, 24]]
    return {
        'kind': 'static_bounded_source_opcode_model_NOT_NATIVE',
        'source_blob': SOURCE_BLOB,
        'nonnegative_character_codes_passed': len(results),
        'observed_model_j_values': [0],
        'nonnegative_model_exit': [10, 8],
        'model_steps_per_character': 532,
        'negative_one_counterfactual_only': counterfactual,
        'signed_native_executions_new': 0,
        'EOF_semantics_verified': False,
        'global_unreachability_proven': False,
        'stage1_complete': False,
    }


def main():
    print(json.dumps(audit(SOURCE.read_bytes()), indent=2, ensure_ascii=False))


if __name__ == '__main__':
    main()
