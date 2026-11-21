#!/usr/bin/env python3
"""v159 SOURCE-LOCKED STATIC DIAGNOSTIC PATCH PROPOSAL. NEVER execute F(c,t).

Inputs: exactly pinned historical Python and Ada sources (plus Ada weaving
source as a lineage lock). Output: NEW instrumented QA-only copies, unified
diffs, and a write-once manifest. Python is AST-parsed, Ada is not compiled.
Inserted blocks can be stripped exactly to recover immutable source bytes.

These are not historical source bytes, and their date behavior is untested.
The tool has no --execute, --compile, or native Soak entrypoint.
"""
from __future__ import annotations

import argparse
import ast
import difflib
from hashlib import sha256
import json
from pathlib import Path

from native_execution_receipt_v038 import canonical
from soak_ada_month_family_divergence_v156 import (
    validate_source_files, SOURCE_LOCKS, PY_COMMIT, ADA_COMMIT, blob_sha
)

SCHEMA="PASTAFARI_SOAK_STATIC_FOUNDATION_DIAGNOSTIC_PATCH_PROPOSAL_V159/1"
HALT="STOP_NEW_NATIVE_SOAK_DISPATCH"
MARK_OPEN_PY="# >>> V159_QA_DIAG_INSTRUMENTED_COPY_ONLY "
MARK_CLOSE_PY="# <<< V159_QA_DIAG_INSTRUMENTED_COPY_ONLY "
MARK_OPEN_ADA="-- >>> V159_QA_DIAG_INSTRUMENTED_COPY_ONLY "
MARK_CLOSE_ADA="-- <<< V159_QA_DIAG_INSTRUMENTED_COPY_ONLY "
VAR="PC_FOUNDATION_DIAG_V159"
MAX_BYTES=150_000
TARGETS={
 "REF-41": "instrumented_normative_reference_v159.py",
 "ADA-TELUGU": "instrumented_normative_oracle_v159.adb",
}
# Exact original source snippets. These anchors must remain unique and the
# historical whole-file Git blob must match before insertion.
PY_ANCHORS=(
    "        return family.unrank1(rank)",
    "        return DateIds(",
)
ADA_ANCHORS=(
    '      Stage13_Trace ("month_lengths_begin");',
    '          Stage13_Trace ("month_weave_tickets_done");',
    '            Stage13_Trace ("calendar_result_ready");',
)


def require(ok, why):
    if not ok: raise ValueError(why)


def digest(data:bytes)->str:
    return sha256(data).hexdigest()


def detect_eol(data:bytes)->bytes:
    require(type(data) is bytes and b"\x00" not in data
            and b"\r" not in data.replace(b"\r\n",b"")
            and 0<len(data)<MAX_BYTES, "invalid or oversized source bytes/EOL")
    eol=b"\r\n" if b"\r\n" in data else b"\n"
    require(data.endswith(eol),"original source must end with newline")
    return eol


def insert_once(original:bytes, anchor:str, label:str,
                code_lines:list[str], language:str) -> bytes:
    require(language in ("PY","ADA") and type(original) is bytes
            and type(anchor) is str and type(label) is str
            and type(code_lines) is list and code_lines
            and all(type(x) is str for x in code_lines),
            "invalid insertion request")
    eol=detect_eol(original)
    needle=anchor.encode("utf-8")+eol
    require(original.count(needle)==1,
            "target insertion anchor not unique or absent: "+label)
    prefix=MARK_OPEN_PY if language=="PY" else MARK_OPEN_ADA
    suffix=MARK_CLOSE_PY if language=="PY" else MARK_CLOSE_ADA
    # Marker blocks contain only newly added lines, not modified original.
    indent=anchor[:len(anchor)-len(anchor.lstrip())]
    start=(indent+prefix+label).encode("utf-8")+eol
    end=(indent+suffix+label).encode("utf-8")+eol
    newlines=eol.join(line.encode("utf-8") for line in code_lines)+eol
    require(start not in original and end not in original
            and start not in newlines and end not in newlines,
            "marker collision/recursive source injection")
    block=start+newlines+end
    return original.replace(needle,block+needle,1)


def strip_insertions(patched:bytes,labels:tuple[str,...],
                     language:str)->bytes:
    require(language in ("PY","ADA") and len(labels)==len(set(labels)),
            "invalid strip contract")
    eol=detect_eol(patched)
    prefix=MARK_OPEN_PY if language=="PY" else MARK_OPEN_ADA
    suffix=MARK_CLOSE_PY if language=="PY" else MARK_CLOSE_ADA
    lines=patched.split(eol)
    found=set()
    out=[]
    skipping=False
    for line in lines:
        decoded=line.decode("utf-8")
        if prefix in decoded:
            require(not skipping,"nested instrumentation blocks")
            label=decoded.split(prefix,1)[1]
            require(label in labels and label not in found,
                    "unexpected or duplicate instrumentation marker")
            indent=decoded[:decoded.index(prefix)]
            found.add(label)
            skipping=(label,indent)
            continue
        if suffix in decoded:
            require(skipping is not False,"orphan instrumentation close marker")
            label=decoded.split(suffix,1)[1]
            require((label,decoded[:decoded.index(suffix)])==skipping,
                    "mismatched instrumentation close marker")
            skipping=False
            continue
        if not skipping:out.append(line)
    require(skipping is False and found==set(labels),
            "missing or unclosed instrumentation marker")
    return eol.join(out)


def python_blocks()->tuple[list[str],list[str]]:
    selector=[
        '        if __import__("os").environ.get("PC_FOUNDATION_DIAG_V159") == "1":',
        '            __import__("sys").stderr.write(',
        '                "V159_PY_DIAG|selector|" + __import__("json").dumps({',
        '                    "source_mode": "QA_INSTRUMENTED_COPY_NOT_ORIGINAL",',
        '                    "month_lengths": list(month_lengths),',
        '                    "family_count_decimal": str(family.count()),',
        '                    "global_rank_decimal": str(rank),',
        '                }, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\\n"',
        '            )',
    ]
    final=[
        '        if __import__("os").environ.get("PC_FOUNDATION_DIAG_V159") == "1":',
        '            __import__("sys").stderr.write(',
        '                "V159_PY_DIAG|result|" + __import__("json").dumps({',
        '                    "source_mode": "QA_INSTRUMENTED_COPY_NOT_ORIGINAL",',
        '                    "calculation_day": str(calculation_day),',
        '                    "target_day": str(target_day),',
        '                    "year_open_day": str(year.open_gate_day),',
        '                    "year_close_day": str(year.close_gate_day),',
        '                    "month_count": structure.month_count,',
        '                    "month_lengths": list(structure.month_lengths),',
        '                    "month_weaving": list(structure.month_weaving),',
        '                    "month_name_indices": list(structure.month_name_indices),',
        '                    "target_offset0": year_offset0,',
        '                    "month_id": month_id,',
        '                    "day_in_month": day_in_month,',
        '                    "month_index": month_name_index,',
        '                }, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\\n"',
        '            )',
    ]
    return selector,final


def ada_blocks()->tuple[list[str],list[str],list[str]]:
    guard=('Ada.Environment_Variables.Exists ("PC_FOUNDATION_DIAG_V159")'
           ' and then Ada.Environment_Variables.Value ("PC_FOUNDATION_DIAG_V159") = "1"')
    first=[
        '       if '+guard+' then',
        '          Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '            "V159_ADA_DIAG|month_lengths_global_rank|" & To_String (Rank));',
        '       end if;',
    ]
    tickets=[
        '           if '+guard+' then',
        "              for J in Tickets'Range loop",
        '                 Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                   "V159_ADA_DIAG|ticket|" & Natural\'Image (J) &',
        '                   "|" & Natural\'Image (Tickets (J)));',
        '              end loop;',
        '           end if;',
    ]
    final=[
        '             if '+guard+' then',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|source_mode|QA_INSTRUMENTED_COPY_NOT_ORIGINAL");',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|calculation_day|" & To_String (Calculation_Day));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|target_day|" & To_String (Target_Day));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|year_open_day|" & To_String (Y.Open_Day));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|year_close_day|" & To_String (Y.Close_Day));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|month_count|" & Natural\'Image (Month_Count));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|month_count_rank|" & Natural\'Image (Month_Rank));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|month_name_rank|" & To_String (Month_Name_Rank));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|target_offset0|" & Natural\'Image (Offset_0));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|month_id|" & Natural\'Image (Month_Id));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|month_index|" & Natural\'Image (Month_Names (Month_Id)));',
        '                Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                  "V159_ADA_DIAG|day_in_month|" & Natural\'Image (Day_In_Month));',
        "                for J in Month_Lengths'Range loop",
        '                   Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                     "V159_ADA_DIAG|month_length|" & Natural\'Image (J) &',
        '                     "|" & Natural\'Image (Month_Lengths (J)));',
        '                end loop;',
        "                for J in Weave'Range loop",
        '                   Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                     "V159_ADA_DIAG|weave|" & Natural\'Image (J) &',
        '                     "|" & Natural\'Image (Weave (J)));',
        '                end loop;',
        "                for J in Month_Names'Range loop",
        '                   Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,',
        '                     "V159_ADA_DIAG|month_name|" & Natural\'Image (J) &',
        '                     "|" & Natural\'Image (Month_Names (J)));',
        '                end loop;',
        '             end if;',
    ]
    return first,tickets,final


def make_patched(originals:dict[str,bytes])->dict[str,bytes]:
    validate_source_files(originals)
    py=originals["REF-41"]
    ada=originals["ADA-TELUGU"]
    select,final=python_blocks()
    py=insert_once(py,PY_ANCHORS[0],"PY_SELECTOR_GLOBAL_RANK",select,"PY")
    py=insert_once(py,PY_ANCHORS[1],"PY_FINAL_NAME_AND_WEAVE",final,"PY")
    rank_assignment=b"        rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())"
    selector_marker=b"# >>> V159_QA_DIAG_INSTRUMENTED_COPY_ONLY PY_SELECTOR_GLOBAL_RANK"
    return_rank=b"        return family.unrank1(rank)"
    require(py.index(rank_assignment) < py.index(selector_marker) <
            py.index(return_rank),"Python rank diagnostic must follow rank assignment before return")
    ast.parse(py.decode("utf-8"),filename="qa-instrumented-copy-not-executed.py")
    first,tickets,afinal=ada_blocks()
    ada=insert_once(ada,ADA_ANCHORS[0],"ADA_MONTH_LENGTH_RANK",first,"ADA")
    ada=insert_once(ada,ADA_ANCHORS[1],"ADA_INTERIOR_TICKETS",tickets,"ADA")
    ada=insert_once(ada,ADA_ANCHORS[2],"ADA_FINAL_NAME_AND_WEAVE",afinal,"ADA")
    require(strip_insertions(py,("PY_SELECTOR_GLOBAL_RANK","PY_FINAL_NAME_AND_WEAVE"),"PY")==
            originals["REF-41"],"Python reversibility lost")
    require(strip_insertions(ada,("ADA_MONTH_LENGTH_RANK","ADA_INTERIOR_TICKETS",
                                  "ADA_FINAL_NAME_AND_WEAVE"),"ADA")==
            originals["ADA-TELUGU"],"Ada reversibility lost")
    require(py!=originals["REF-41"] and ada!=originals["ADA-TELUGU"],
            "instrumented QA copies incorrectly declared original")
    return {"REF-41":py,"ADA-TELUGU":ada}


def diff_bytes(a:bytes,b:bytes,left:str,right:str)->bytes:
    eol=detect_eol(a)
    require(detect_eol(b)==eol,"source EOL changed unexpectedly")
    a_lines=a.decode("utf-8").splitlines(keepends=True)
    b_lines=b.decode("utf-8").splitlines(keepends=True)
    delta="".join(difflib.unified_diff(a_lines,b_lines,fromfile=left,tofile=right,
                                      lineterm="\n"))
    require(delta.startswith("--- ") and delta.count("@@")>0,
            "no valid instrumented source diff")
    return delta.encode("utf-8")


def output_paths(root:Path)->dict[str,Path]:
    return {
        "REF-41":root/"instrumented_normative_reference_v159.py",
        "ADA-TELUGU":root/"instrumented_normative_oracle_v159.adb",
    }


def source_paths(root:Path)->dict[str,Path]:
    return {
        "REF-41":root/"Python-Turkce"/PY_COMMIT/"tests/normative_reference.py",
        "ADA-TELUGU":root/"Ada-Telugu"/ADA_COMMIT/"src/normative_oracle.adb",
        "ADA-WEAVING":root/"Ada-Telugu"/ADA_COMMIT/"src/month_weaving.adb",
    }


def plan(originals:dict[str,bytes],modified:dict[str,bytes])->dict:
    verified=validate_source_files(originals)
    expected=make_patched(originals)
    require(modified==expected,"QA proposed source copies not deterministically regenerated")
    return {
        "schema":SCHEMA,
        "status":"PATCH_PROPOSALS_STAGED_NOT_COMPILED_NOT_EXECUTED",
        "original_provenance":verified,
        "proposed_source_copies":[{
            "engine":key,
            "original_git_blob_sha1":SOURCE_LOCKS[key]["git_blob_sha1"],
            "original_sha256":digest(originals[key]),
            "qa_modified_git_blob_sha1":blob_sha(modified[key]),
            "qa_modified_sha256":digest(modified[key]),
            "original_bytes_unchanged":False,
            "patch_is_reversible_exact_original_bytes":True,
            "actual_original_source_executed":False,
            "modified_source_compiled_or_executed":False,
            "instrumentation_uses_stderr":True,
            "requires_environment_opt_in":VAR,
            "name":TARGETS[key]
        } for key in ("REF-41","ADA-TELUGU")],
        "python_syntax_ast_parsed":True,
        "ada_syntax_compiled_or_verified":False,
        "semantic_equivalence_to_original_proven":False,
        "diagnostic_values_are_real_native_evidence":False,
        "real_foundation_month_rank_or_weave_derived":False,
        "source_native_Fct_calls":0,
        "original_native_compiles":0,
        "original_full_years_certified":0,
        "issue29_disposition_authorized":False,
        "halt_new_native_soak_dispatch":True,
        "main_changes_permitted":False,
        "scientific_note":"Static diagnostics are proposed NEW source bytes, not original historical runs. Original F(c,t) is not executed."
    }


def generate(srcroot:Path,outroot:Path)->dict:
    require(not outroot.exists(),"output directory must not exist")
    originals={k:v.read_bytes() for k,v in source_paths(srcroot).items()}
    changed=make_patched(originals)
    document=plan(originals,changed)
    outroot.mkdir(parents=False,exist_ok=False)
    for key, dest in output_paths(outroot).items():
        dest.write_bytes(changed[key])
        diff=diff_bytes(originals[key],changed[key],
                        "historical/"+SOURCE_LOCKS[key]["path"],
                        "QA-v159/"+TARGETS[key])
        (outroot/(key.replace("-","_")+".diff")).write_bytes(diff)
    (outroot/"manifest.json").write_bytes(canonical(document)+b"\n")
    return document


def verify(srcroot:Path,outroot:Path)->dict:
    originals={k:v.read_bytes() for k,v in source_paths(srcroot).items()}
    changed={k:p.read_bytes() for k,p in output_paths(outroot).items()}
    expected=plan(originals,changed)
    data=(outroot/"manifest.json").read_bytes()
    require(data==canonical(expected)+b"\n","manifest mismatch or noncanonical report")
    for key in changed:
        d=diff_bytes(originals[key],changed[key],
                     "historical/"+SOURCE_LOCKS[key]["path"],
                     "QA-v159/"+TARGETS[key])
        require((outroot/(key.replace("-","_")+".diff")).read_bytes()==d,
                "unified diff has drifted")
    return expected


def main()->int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--sources-root",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    p.add_argument("--verify",action="store_true")
    args=p.parse_args()
    doc=(verify if args.verify else generate)(args.sources_root,args.out)
    print(json.dumps({
        "schema":doc["schema"],"status":doc["status"],
        "proposals":len(doc["proposed_source_copies"]),
        "original_native_Fct_calls":doc["source_native_Fct_calls"],
        "original_native_compiles":doc["original_native_compiles"],
        "real_intermediate_evidence":doc["diagnostic_values_are_real_native_evidence"],
        "requires_formal_issue29_disposition":not doc["issue29_disposition_authorized"],
        "source_sha256":{x["engine"]:x["qa_modified_sha256"]
                         for x in doc["proposed_source_copies"]}
    },sort_keys=True))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
