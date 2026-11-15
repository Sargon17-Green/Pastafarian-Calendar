#!/usr/bin/env python3
"""Pure bounded two-original source comparison, not a native runner or oracle.

The caller must independently validate pinned source/name tables and process
receipts. Kotlin production bridge outputs numeric indices only; preserve
their raw tokens as such and NEVER invent native Cymraeg names. This gate
only admits 1..32 days within the witnessed 4244-day year 5000.
"""
from __future__ import annotations
import hashlib
import json
import re
from native_raw_pair_gate_v018 import verify_pair
from year_validator import YearCase, parse_line

SCHEMA="PASTAFARI_TWO_ORIGINAL_BOUNDED_CHUNK_GATE_V050/1"
C="-15055671"
YEAR="5000"
YEAR_FIRST=-15057702
YEAR_LAST=-15053459
BOUNDARY_SHA="ad64cc51522d7f19cb8a238e2a6a418e75203c6cbfe017c394f623edeb882e78"
LIMIT=32
NUMBER=re.compile(r"^(?:0|-?[1-9][0-9]*)$")
FIELDS=("year","cutlet_index","day_in_cutlet","month_index","day_in_month")

class EvidenceError(ValueError):
    pass

def sha(payload:bytes)->str:
    return hashlib.sha256(payload).hexdigest()

def json_line(row:dict)->bytes:
    return (json.dumps(row,ensure_ascii=False,sort_keys=True,
            separators=(",",":"),allow_nan=False)+"\n").encode("utf8")

def strict_lines(blob:bytes,label:str,count:int,max_size:int=16384)->list[bytes]:
    if (type(blob) is not bytes or not blob or len(blob)>count*max_size
            or not blob.endswith(b"\n") or b"\r" in blob or b"\x00" in blob):
        raise EvidenceError(label+": invalid raw stream framing or size")
    lines=blob.splitlines(keepends=True)
    if len(lines)!=count or any(len(line)>max_size or line==b"\n" for line in lines):
        raise EvidenceError(label+": missing/duplicate/oversized rows")
    for line in lines:
        if line.count(b"\n")!=1:
            raise EvidenceError(label+": invalid LF framing")
        line.decode("utf8",errors="strict")
    return lines

def integer(token:str,name:str)->int:
    if type(token) is not str or not NUMBER.fullmatch(token):
        raise EvidenceError("Kotlin noncanonical decimal "+name)
    return int(token)

def kotlin_original_row(native:bytes,c:str,t:str,year:str)->dict:
    try:
        fields=native[:-1].decode("ascii").split("\t")
    except UnicodeError as exc:
        raise EvidenceError("Kotlin original TSV not ASCII") from exc
    if len(fields)!=7:
        raise EvidenceError("Kotlin source must emit seven fields")
    values=[integer(token,str(i)) for i,token in enumerate(fields)]
    if fields[:3]!=[c,t,year]:
        raise EvidenceError("Kotlin original c/t/year mismatch")
    y,ci,cd,mi,md=values[2:]
    if not (1<=ci<=17 and 1<=mi<=47 and cd>0 and md>0):
        raise EvidenceError("Kotlin original indexes or day out of range")
    return {
        "calculation_day":c,"target_day":t,"year":str(y),
        "cutlet_index":ci,"day_in_cutlet":cd,
        "month_index":mi,"day_in_month":md,
        # These text fields hold raw native INDEX TOKENS, not Cymraeg names.
        "cutlet_name_raw":fields[3],"month_name_raw":fields[5],
        "native_name_provenance":"INDEX_ONLY_NO_CYMRAEG_NAMES_IN_SOURCE",
        "source_raw_sha256":sha(native),
    }

def verify_bounded_original_chunk(
        *,python_original_raw:bytes,python_original_normalized:bytes,
        kotlin_original_stdout:bytes,calculation_day:str,year:str,
        first_target_day:str,last_target_day:str,boundary_evidence_sha256:str,
        frozen_python_cutlets:dict[str,int],frozen_python_months:dict[str,int])->dict:
    """No date computation; all names supplied by caller remain untrusted unless
    the caller previously authenticated original REF-41 frozen source blobs."""
    if calculation_day!=C or year!=YEAR or boundary_evidence_sha256!=BOUNDARY_SHA:
        raise EvidenceError("unknown original reference c/year/boundary")
    if any(type(x) is not str or not NUMBER.fullmatch(x)
           for x in (first_target_day,last_target_day)):
        raise EvidenceError("noncanonical target day")
    start,end=int(first_target_day),int(last_target_day)
    n=end-start+1
    if not (YEAR_FIRST<=start<=end<=YEAR_LAST and 1<=n<=LIMIT):
        raise EvidenceError("chunk outside witnessed original year or exceeds cap")
    if (type(frozen_python_cutlets) is not dict or
        type(frozen_python_months) is not dict or
        sorted(frozen_python_cutlets.values())!=list(range(1,18)) or
        sorted(frozen_python_months.values())!=list(range(1,48))):
        raise EvidenceError("invalid native source name tables")
    pyraw=strict_lines(python_original_raw,"python original raw",n)
    pynorm=strict_lines(python_original_normalized,"python normalized",n)
    ktraw=strict_lines(kotlin_original_stdout,"kotlin OS stdout",n)
    kotlin_norm=[]
    matched=0
    difference=None
    case=YearCase(calculation_day,year,first_target_day,last_target_day,boundary_evidence_sha256)
    for i,(raw,norm,kt) in enumerate(zip(pyraw,pynorm,ktraw)):
        target=str(start+i)
        try:
            verify_pair("REF-41",raw,norm,frozen_python_cutlets,
                        frozen_python_months,calculation_day,target)
        except ValueError as exc:
            raise EvidenceError(f"Python raw source invalid row {i+1}: {exc}") from exc
        py_day=parse_line(norm.decode("utf8"),i+1,case,start+i)
        kt_row=kotlin_original_row(kt,calculation_day,target,year)
        kt_day=parse_line(json_line(kt_row).decode("utf8"),i+1,case,start+i)
        kotlin_norm.append(json_line(kt_row))
        if py_day.normalized!=kt_day.normalized:
            difference={
                "ordinal":i,"target_day":target,
                "first_different_field":next(field for field,a,b in
                    zip(FIELDS,py_day.normalized,kt_day.normalized) if a!=b),
                "python_five_fields":list(py_day.normalized),
                "kotlin_five_fields":list(kt_day.normalized),
                "python_raw_line_sha256":sha(raw),
                "kotlin_stdout_line_sha256":sha(kt),
            }
            break
        matched+=1
    return {
        "schema":SCHEMA,
        "status":("ORIGINAL_NATIVE_FIRST_MISMATCH_HALT" if difference
                  else "BOUNDED_ORIGINAL_CHUNK_MATCH_NOT_FULL_YEAR"),
        "calculation_day":calculation_day,"year":year,
        "first_target_day":first_target_day,"last_target_day":last_target_day,
        "boundary_evidence_sha256":boundary_evidence_sha256,
        "original_full_year_length":YEAR_LAST-YEAR_FIRST+1,
        "chunk_days":n,"matched_original_day_pairs":matched,
        "first_mismatch":difference,"halt_new_dispatch":difference is not None,
        "python_raw_sha256":sha(python_original_raw),
        "python_normalized_sha256":sha(python_original_normalized),
        "kotlin_os_stdout_sha256":sha(kotlin_original_stdout),
        # Never emit a partial chunk on first mismatch.
        "kotlin_index_only_normalized_jsonl":None if difference else b"".join(kotlin_norm),
        "kotlin_native_names_reported":False,
        "host_process_identity_attested_by_this_gate":False,
        "algorithmic_independence_certified":False,
        "canonical_oracle_certified":False,
        "original_full_year_soak_passes_certified":0,
    }
