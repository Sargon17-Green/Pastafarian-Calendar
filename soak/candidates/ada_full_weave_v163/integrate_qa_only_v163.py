#!/usr/bin/env python3
"""Issue29 v163: source-locked QA adapter for canonical full Ada weave.

Never compiles or invokes the calendar. Writes ONE separate QA copy of original
normative_oracle.adb; all historical source bytes are verified and untouched.
"""
from __future__ import annotations

from difflib import unified_diff
from hashlib import sha1, sha256
import json
from pathlib import Path
import shutil
import sys


COMMIT = "a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
ORIGINAL_BLOB = "923733d4f8face03586aee304640bf7540c28b4c"
START = "   -- Canonical two-rail family: open every month in order, rank an exact\n"
END = "   function Calendar_Date\n"
CONTEXT = "with Month_Weaving;\n"
ADDED_CONTEXT = "with Canonical_Full_Weave_V163;\n"
NEW_FUNCTION = """    --  QA v163: exact complete family, global lexicographic rank per Spec V.
    --  No fixed opening/closing rails; no interior-ticket approximation.
    function Choose_Month_Weaving
      (Structure_R : Sauce_Result; Lengths : Natural_Array) return Natural_Array
    is
       F : Canonical_Full_Weave_V163.Family (Lengths'Length);
    begin
       Stage13_Trace ("month_weave_full_family_build_begin");
       Canonical_Full_Weave_V163.Build
         (F, Canonical_Full_Weave_V163.Natural_Array (Lengths));
       Stage13_Trace ("month_weave_full_family_build_done");
       declare
          Total_Options : constant Big_Integer :=
            Canonical_Full_Weave_V163.Count (F);
          Rank : constant Big_Integer := Choose_Rank
            (Ask_Bowl (Structure_R, 4, Seal_Month_Weaving), Total_Options);
          Result : constant Canonical_Full_Weave_V163.Natural_Array :=
            Canonical_Full_Weave_V163.Unrank (F, Rank);
       begin
          Stage13_Trace ("month_weave_full_family_unrank_done");
          return Natural_Array (Result);
       end;
    end Choose_Month_Weaving;

"""


def digest(data: bytes) -> str:
    return sha256(data).hexdigest()


def blob(data: bytes) -> str:
    return sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def patch_only(src: bytes) -> bytes:
    source = src.decode("utf-8")
    if source.count(START) != 1 or source.count(END) != 1:
        raise RuntimeError("locked original function anchors absent or ambiguous")
    if source.count(CONTEXT) != 1 or ADDED_CONTEXT in source:
        raise RuntimeError("locked original context anchor absent or ambiguous")
    a, b = source.index(START), source.index(END)
    if not (a < b):
        raise RuntimeError("original function order has changed")
    patched = source[:a] + NEW_FUNCTION + source[b:]
    return patched.replace(CONTEXT, CONTEXT + ADDED_CONTEXT, 1).encode("utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        raise RuntimeError("usage: adapter.py v160_prepared_root candidate_dir")
    base, candidate = Path(sys.argv[1]), Path(sys.argv[2])
    if not (base / "preparation.json").is_file():
        raise RuntimeError("missing prior pinned QA source preparation")
    proof = json.loads((base / "preparation.json").read_text())
    if proof["source_dispatch_count"] != 0 or proof["soak_years"] != 0:
        raise RuntimeError("attempted to adapt executed or Soak source")
    srcroot = base / "sources" / "Ada-Telugu" / COMMIT / "src"
    original = (srcroot / "normative_oracle.adb").read_bytes()
    if blob(original) != ORIGINAL_BLOB:
        raise RuntimeError("historical normative oracle blob mismatch")
    output = base / "ada-build" / "src" / "normative_oracle.adb"
    if not output.is_file():
        raise RuntimeError("missing disposable QA Ada build directory")

    patched = patch_only(original)
    original_text = original.decode()
    start, end = original_text.index(START), original_text.index(END)
    discarded_original_function = original_text[start:end]
    patched_text = patched.decode()
    restored = patched_text.replace(ADDED_CONTEXT, "", 1).replace(
        NEW_FUNCTION, discarded_original_function, 1
    )
    if restored.encode() != original:
        raise RuntimeError("QA integration is not byte-reversible")

    for suffix in (".ads", ".adb"):
        src = candidate / ("canonical_full_weave_v163" + suffix)
        dest = output.parent / src.name
        if dest.exists():
            raise RuntimeError("candidate already placed; refuse overwrite")
        shutil.copyfile(src, dest)

    output.write_bytes(patched)
    diff = "".join(unified_diff(
        original_text.splitlines(keepends=True),
        patched_text.splitlines(keepends=True),
        fromfile="HISTORICAL_ORIGINAL/src/normative_oracle.adb",
        tofile="DISPOSABLE_QA/src/normative_oracle.adb",
    ))
    (base / "v163-qa-integration.diff").write_text(diff, encoding="utf-8")
    manifest = {
        "schema": "ISSUE29_ADA_FULL_CANONICAL_WEAVING_V163_QA_ONLY/1",
        "status": "QA_ADAPTED_COMPILE_ONLY_NO_CALENDAR_INVOKED",
        "original_commit": COMMIT,
        "original_blob_sha1": blob(original),
        "original_sha256": digest(original),
        "qa_adapter_sha256": digest(patched),
        "candidate_ads_sha256": digest((candidate / "canonical_full_weave_v163.ads").read_bytes()),
        "candidate_adb_sha256": digest((candidate / "canonical_full_weave_v163.adb").read_bytes()),
        "original_reversible_exact_bytes": True,
        "original_calendar_calls": 0,
        "qa_calendar_calls": 0,
        "full_soak_years": 0,
        "STOP_NEW_NATIVE_SOAK_DISPATCH": True,
    }
    (base / "v163-qa-adapter-manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    print("V163_QA_CANDIDATE_PATCH_SOURCE_LOCKED_AND_REVERSIBLE")
    print("V163_ORIGINAL_CALENDAR_CALLS_0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
