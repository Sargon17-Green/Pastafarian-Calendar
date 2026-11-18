#!/usr/bin/env python3
"""Bounded, read-only forensic inspection of an exact SHA-pinned NARS2000 installer.

NEVER executes input. This is not an installer unpacker. Report classifications are
structural findings only; signature counts cannot demonstrate a working CLI.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys

PINNED_SHA = '28e8d1dbcea13360a271e704196b5680f0c3e9461cfc38daa41b96dba202f11b'
PINNED_SIZE = 9430788
CAP = 30_000_000


def u16(b: bytes, offset: int) -> int:
    if offset < 0 or offset + 2 > len(b):
        raise ValueError('TRUNCATED_U16')
    return struct.unpack_from('<H', b, offset)[0]


def u32(b: bytes, offset: int) -> int:
    if offset < 0 or offset + 4 > len(b):
        raise ValueError('TRUNCATED_U32')
    return struct.unpack_from('<I', b, offset)[0]


def require(cond: bool, error: str):
    if not cond:
        raise ValueError(error)


def parse_pe(b: bytes) -> dict:
    require(len(b) >= 256, 'FILE_TOO_SHORT')
    require(b[:2] == b'MZ', 'NOT_MZ')
    lfanew = u32(b, 0x3c)
    require(0 < lfanew < min(len(b)-80, 4_000_000), 'INVALID_PE_OFFSET')
    require(b[lfanew:lfanew+4] == b'PE\0\0', 'NOT_PE_SIGNATURE')
    coff = lfanew+4
    machine = u16(b, coff)
    section_count = u16(b, coff+2)
    opt_size = u16(b, coff+16)
    require(0 < section_count <= 96, 'INVALID_SECTION_COUNT')
    optional_start = coff + 20
    optional_end = optional_start + opt_size
    require(optional_end <= len(b) and opt_size >= 96, 'TRUNCATED_OPTIONAL_HEADER')
    magic = u16(b, optional_start)
    require(magic in (0x10b, 0x20b), 'UNSUPPORTED_PE_MAGIC')
    is64 = magic == 0x20b
    dir_base = optional_start + (112 if is64 else 96)
    num_dirs = u32(b, optional_start + (108 if is64 else 92))
    dirs = []
    for i in range(min(num_dirs,16)):
        off = dir_base+8*i
        if off+8 <= optional_end:
            dirs.append({'index':i,'virtual_address':u32(b,off),'size':u32(b,off+4)})
    first_section = optional_end
    require(first_section + section_count*40 <= len(b), 'TRUNCATED_SECTIONS')
    sections = []
    ending = 0
    for idx in range(section_count):
        p = first_section + 40*idx
        name = b[p:p+8].split(b'\0',1)[0].decode('latin1')
        vsize, vaddress, rawsize, rawstart = (u32(b,p+8),u32(b,p+12),u32(b,p+16),u32(b,p+20))
        require(rawstart+rawsize<=len(b), 'SECTION_OUT_OF_FILE')
        if rawsize:
            ending=max(ending,rawstart+rawsize)
        sections.append({'name':name,'virtual_address':vaddress,'virtual_size':vsize,'raw_offset':rawstart,'raw_size':rawsize,
                         'sha256':hashlib.sha256(b[rawstart:rawstart+rawsize]).hexdigest() if rawsize else None})
    resources = []
    resource_error = None
    res_dir = next((d for d in dirs if d['index'] == 2 and d['virtual_address'] and d['size']), None)
    def rva_to_raw(rva, need=1):
        for s in sections:
            delta = rva - s['virtual_address']
            if 0 <= delta and delta + need <= s['raw_size']:
                return s['raw_offset'] + delta
        raise ValueError('RVA_OUT_OF_RAW_SECTIONS')
    if res_dir:
        base_rva = res_dir['virtual_address']
        counter = [0]
        def resource_name(value):
            if not (value & 0x80000000):
                return str(value)
            pos = rva_to_raw(base_rva + (value & 0x7fffffff), 2)
            length = u16(b, pos)
            require(length <= 1024, 'RESOURCE_NAME_EXCEEDS_BOUND')
            p2 = rva_to_raw(base_rva + (value & 0x7fffffff) + 2, 2*length)
            return b[p2:p2+2*length].decode('utf-16-le', errors='replace')
        def walk_resources(rel, level, parts):
            require(level <= 4, 'RESOURCE_TREE_TOO_DEEP')
            pdir = rva_to_raw(base_rva + rel, 16)
            num_entries = u16(b,pdir+12) + u16(b,pdir+14)
            require(num_entries <= 2048, 'RESOURCE_DIR_TOO_MANY_ENTRIES')
            counter[0] += num_entries
            require(counter[0] <= 10000, 'RESOURCE_TREE_TOO_LARGE')
            for i in range(num_entries):
                p = rva_to_raw(base_rva + rel + 16 + 8*i, 8)
                val = u32(b,p); where = u32(b,p+4)
                path=parts + [resource_name(val)]
                if where & 0x80000000:
                    walk_resources(where & 0x7fffffff, level+1, path)
                else:
                    leaf = rva_to_raw(base_rva + where,16)
                    data_rva = u32(b,leaf); size = u32(b,leaf+4)
                    require(size <= CAP, 'RESOURCE_DATA_TOO_LARGE')
                    raw = rva_to_raw(data_rva, size) if size else None
                    payload = b[raw:raw+size] if size else b''
                    resources.append({'path':path,'size':size,'file_offset':raw,
                        'sha256':hashlib.sha256(payload).hexdigest(),
                        'first_24_hex':payload[:24].hex()})
        try:
            walk_resources(0,0,[])
        except (ValueError, RecursionError) as e:
            resource_error = str(e)
    overlay = b[ending:]
    # All magic counts are bounded; these are only preliminary clues, not validated embedded files.
    magic = {'zip_local_PK0304': b'PK\x03\x04', 'cab_MSCF': b'MSCF', 'seven_zip': b'7z\xbc\xaf\x27\x1c',
             'gzip':b'\x1f\x8b\x08','MZ':b'MZ','NSIS_text':b'Nullsoft','inno_text':b'Inno Setup'}
    signatures = {}
    for name, token in magic.items():
        indices = []
        pos = 0
        while len(indices)<100:
            pos = b.find(token,pos)
            if pos<0:break
            indices.append(pos)
            pos+=1
        signatures[name] = {'first_offsets':indices[:24],'at_least_count':len(indices),'truncated':len(indices)==100}
    # Full valid PE images nested in a file can be detected without invoking them.
    nested = []
    off = 1
    while len(nested) < 20:
        off = b.find(b'MZ',off)
        if off<0:break
        if off+64<=len(b):
            nested_lfanew = u32(b,off+0x3c)
            if 0 < nested_lfanew < 2_000_000 and off+nested_lfanew+4<=len(b) and b[off+nested_lfanew:off+nested_lfanew+4]==b'PE\0\0':
                nested.append({'offset':off,'pe_header':off+nested_lfanew})
        off+=2
    return {'valid_pe':True,'machine_hex':f'{machine:04x}','optional_magic':f'{magic_hex(magic=is64)}',
            'pe_header_offset':lfanew,'section_count':section_count,'sections':sections,
            'data_directories':dirs,'resources':resources,'resource_error':resource_error,'overlay':{'start':ending,'size':len(overlay),
                'sha256':hashlib.sha256(overlay).hexdigest() if overlay else None,
                'first_32_hex':overlay[:32].hex()},
            'signature_candidates':signatures,'nested_pe_candidates':nested,
            'interpretation':'STRUCTURAL_ONLY_NOT_AN_EXTRACTION_OR_EXECUTION_PROOF'}


def magic_hex(magic: bool) -> str:
    return '020b' if magic else '010b'


def inspect(path: Path, require_pinned=True) -> dict:
    size = path.stat().st_size
    require(size <= CAP, 'FILE_EXCEEDS_BOUNDED_SIZE')
    raw = path.read_bytes()
    sha = hashlib.sha256(raw).hexdigest()
    if require_pinned:
        require(size == PINNED_SIZE, 'PINNED_SIZE_MISMATCH')
        require(sha == PINNED_SHA, 'PINNED_SHA256_MISMATCH')
    result = parse_pe(raw)
    result.update({'file_bytes':size,'sha256':sha,'pinned_size_and_sha_pass':bool(size == PINNED_SIZE and sha == PINNED_SHA),
                   'native_executed':False,'stage1_executed':False})
    return result


def main(argv=None) -> int:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('file',type=Path)
    ap.add_argument('--out',type=Path,default=Path('pe_structural_evidence.json'))
    ap.add_argument('--unsafe-unpinned-test-input',action='store_true',help='Only for local structural parser unit testing; NEVER for CI decisions.')
    args=ap.parse_args(argv)
    try:
        result=inspect(args.file,require_pinned=not args.unsafe_unpinned_test_input)
    except (ValueError,OSError) as e:
        result={'status':'REJECTED','error':str(e),'native_executed':False,'stage1_executed':False}
        args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        print('REJECTED: '+str(e),file=sys.stderr)
        return 2
    args.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('PE sections:',result['section_count'],'overlay bytes:',result['overlay']['size'])
    print('Native=NOT_RUN / STAGE1=NOT_RUN')
    return 0
if __name__=='__main__':
    raise SystemExit(main())
