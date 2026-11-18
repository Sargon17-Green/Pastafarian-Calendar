#!/usr/bin/env python3
"""Prepare *unverified* LX canary from a real official NARS2000 saved workspace.

Does not run NARS or create the expected sentinel; an independent bounded
Windows process must execute the resulting candidate to qualify native LX.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re

SECTION = re.compile(r'^\[([^\]\r\n]+)\]\s*$')
GLOBAL = re.compile(r'^\s*:(\d+)\s*=')
LX = re.compile(r'^(\s*\d+\s*=\s*\{quad\}lx\s*=\s*):([0-9]+)(\s*)$', re.I)
CANARY = 'APL_LX_CANARY_REAL_NATIVE_0_5_14_11'
PATH = re.compile(r'^[A-Za-z]:\\[A-Za-z0-9_\\.-]+\.txt$')


def make_canary(raw: bytes, marker: str) -> tuple[bytes, dict]:
    if len(raw) > 25_000_000 or not raw:
        raise ValueError('SOURCE_SIZE_UNSAFE')
    if not PATH.fullmatch(marker) or "'" in marker or '..' in marker:
        raise ValueError('BAD_CANARY_PATH')
    text = raw.decode('cp1252')
    newline = '\r\n' if '\r\n' in text else '\n'
    lines = text.splitlines(keepends=True)
    section_heads = [(i, m.group(1)) for i, line in enumerate(lines) if (m := SECTION.fullmatch(line.strip('\r\n')))]
    if not section_heads or sum(name == 'Globals' for _, name in section_heads) != 1:
        raise ValueError('NO_UNIQUE_GLOBALS_SECTION')
    vars_sections = [(i, name) for i, name in section_heads if name.lower().startswith('vars.')]
    if not vars_sections:
        raise ValueError('MISSING_VARS_SECTION')
    lx_matches = [(i, LX.match(line.strip('\r\n'))) for i, line in enumerate(lines)]
    lx_matches = [(i, m) for i, m in lx_matches if m]
    if len(lx_matches) != 1:
        raise ValueError('LX_REFERENCE_NOT_UNIQUE')
    global_begin = next(i for i, name in section_heads if name == 'Globals')
    next_sections = [i for i, _ in section_heads if i > global_begin]
    global_end = min(next_sections) if next_sections else len(lines)
    if not any(any(start < i < min((x for x,_ in section_heads if x > start), default=len(lines)) for start,_ in vars_sections) for i,_ in lx_matches):
        raise ValueError('LX_OUTSIDE_VARS')
    ids = {int(m.group(1)) for line in lines[global_begin+1:global_end] if (m := GLOBAL.match(line))}
    if not ids:
        raise ValueError('NO_GLOBAL_DEFINITIONS')
    new_id = max(ids) + 1
    if new_id >= 1_000_000:
        raise ValueError('GLOBAL_ID_RANGE')
    apl = (f"tn←'{marker}' ⎕NCREATE 0 ⋄ "
           f"'{CANARY}' ⎕NAPPEND tn ⋄ ⎕NUNTIE tn")
    # The [Globals] character payload itself is enclosed in APL apostrophes.
    # Double interior apostrophes so the stored character vector decodes to
    # an LX expression with intact quoted path and marker string literals.
    serialized = (apl.replace("'", "''")
                  .replace('←', '{assign}')
                  .replace('⎕', '{quad}')
                  .replace('⋄', '{diamond}'))
    decoded = (serialized.replace('{assign}', '←')
               .replace('{quad}', '⎕')
               .replace('{diamond}', '⋄')
               .replace("''", "'"))
    if decoded != apl:
        raise ValueError('LX_SERIALIZATION_NOT_REVERSIBLE')
    if not serialized.isascii() or "'" in marker:
        raise ValueError('ENCODING_FAILED')
    new_global = f":{new_id}=V C {len(apl)} 1 {len(apl)} '{serialized}'{newline}"
    lx_index, old = lx_matches[0]
    old_line = lines[lx_index]
    repl = old.group(1) + ':' + str(new_id) + old.group(3)
    lines[lx_index] = repl + (newline if old_line.endswith(('\n','\r')) else '')
    lines.insert(global_end, new_global)
    candidate = ''.join(lines).encode('cp1252')
    if candidate == raw:
        raise ValueError('CANDIDATE_UNCHANGED')
    # Removing only our insertion and restoring only the LX reference must exactly
    # reconstruct the original: no text normalization, reordering, or silent edits.
    restored = candidate.decode('cp1252').replace(new_global, '', 1)
    restored = restored.replace(repl + (newline if old_line.endswith(('\n','\r')) else ''), old_line, 1)
    if restored.encode('cp1252') != raw:
        raise ValueError('NONLOCAL_SOURCE_MUTATION')
    info = {
        'contract': 'APL_GERMAN_LX_PROBE_CANDIDATE_V1',
        'status': 'GENERATED_NOT_NATIVE_VALIDATED',
        'input_sha256': hashlib.sha256(raw).hexdigest(),
        'output_sha256': hashlib.sha256(candidate).hexdigest(),
        'canary_path': marker,
        'canary_token': CANARY,
        'lx_previous_global': int(old.group(2)),
        'lx_new_global': new_id,
        'apl_statement': apl,
        'actual_apl_characters': len(apl),
        'representation_ascii_characters': len(serialized),
        'native_executed': False,
    }
    return candidate, info


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=pathlib.Path, required=True)
    parser.add_argument('--candidate', type=pathlib.Path, required=True)
    parser.add_argument('--receipt', type=pathlib.Path, required=True)
    parser.add_argument('--canary', required=True)
    a = parser.parse_args()
    candidate, info = make_canary(a.source.read_bytes(), a.canary)
    a.candidate.parent.mkdir(parents=True, exist_ok=True)
    a.receipt.parent.mkdir(parents=True, exist_ok=True)
    a.candidate.write_bytes(candidate)
    a.receipt.write_text(json.dumps(info, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('LX_CANDIDATE_ONLY', info['output_sha256'])
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
