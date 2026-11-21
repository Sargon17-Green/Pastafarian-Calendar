#!/usr/bin/env python3
"""Issue29 v164 GMP source-locked reversible QA integration, COMPILE ONLY.

No F(c,t), no historical source mutation, no calendar execution, no Soak.
Use strictly after the pinned v160 preparation on a disposable directory.
"""
from __future__ import annotations

import hashlib
from difflib import unified_diff
import json
from pathlib import Path
import shutil
import sys


HIST_COMMIT = "a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
ORACLE_BLOB = "923733d4f8face03586aee304640bf7540c28b4c"
START = "   -- Canonical two-rail family: open every month in order, rank an exact\n"
END = "   function Calendar_Date\n"
CONTEXT = "with Month_Weaving;\n"
ADDED_CONTEXT = (
    "with Canonical_Full_Weave_GMP_V164;\n"
    "with Canonical_Wide_Rank_GMP_V164;\n"
)
ORACLE_FUNCTION = """   --  QA v164: all valid interleavings, one global GMP lexicographic rank.
   --  The two-rail and ticket approach of historical Ada is NOT used.
   function Choose_Month_Weaving
     (Structure_R : Sauce_Result; Lengths : Natural_Array) return Natural_Array
   is
      package G renames GNATCOLL.GMP.Integers;
      F : Canonical_Full_Weave_GMP_V164.Family (Lengths'Length);
   begin
      Stage13_Trace ("month_weave_v164_gmp_build_begin");
      Canonical_Full_Weave_GMP_V164.Build
        (F, Canonical_Full_Weave_GMP_V164.Natural_Array (Lengths));
      Stage13_Trace ("month_weave_v164_gmp_build_done");
      declare
         Count_Of_Weaves : G.Big_Integer;
         Global_Rank : G.Big_Integer;
         Stream : constant Answer_Stream :=
           Ask_Bowl (Structure_R, 4, Seal_Month_Weaving);
      begin
         Canonical_Full_Weave_GMP_V164.Count (F, Count_Of_Weaves);
         Canonical_Wide_Rank_GMP_V164.Choose_Rank
           (Stream.First, Stream.Direction_Step,
            Count_Of_Weaves, Global_Rank);
         declare
            Result : constant Canonical_Full_Weave_GMP_V164.Natural_Array :=
              Canonical_Full_Weave_GMP_V164.Unrank (F, Global_Rank);
         begin
            Stage13_Trace ("month_weave_v164_gmp_unrank_done");
            return Natural_Array (Result);
         end;
      end;
   end Choose_Month_Weaving;

"""
# The QA oracle must have this dependency before the inner package rename.
GMP_WITH = "with GNATCOLL.GMP.Integers;\n"
PROJECT = '''with "gnatcoll_gmp.gpr";

project Issue29_Gmp_Oracle_QA_Compile is
   for Source_Dirs use ("src");
   for Object_Dir use "obj";
   package Compiler is
      for Default_Switches ("Ada") use
        ("-gnat2022", "-gnatW8", "-gnata");
   end Compiler;
end Issue29_Gmp_Oracle_QA_Compile;
'''


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch(source: bytes) -> bytes:
    old = source.decode("utf-8")
    for a in (START, END, CONTEXT):
        if old.count(a) != 1:
            raise RuntimeError("immutable original Ada source anchor missing or repeated")
    if old.count("with GNATCOLL.GMP.Integers;") != 0:
        raise RuntimeError("unexpected GMP dependency already in historical Ada")
    i, j = old.index(START), old.index(END)
    if i >= j or i <= 0:
        raise RuntimeError("invalid weaving function boundary")
    altered = old[:i] + ORACLE_FUNCTION + old[j:]
    altered = altered.replace(CONTEXT, CONTEXT + ADDED_CONTEXT + GMP_WITH, 1)
    reverted = altered.replace(
        CONTEXT + ADDED_CONTEXT + GMP_WITH, CONTEXT, 1
    ).replace(ORACLE_FUNCTION, old[i:j], 1)
    if reverted.encode("utf-8") != source:
        raise RuntimeError("v164 QA integration source is not byte-reversible")
    return altered.encode("utf-8")


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: integrate_gmp_qa_only_v164.py prepared_root candidate_dir")
    root, candidate = Path(sys.argv[1]), Path(sys.argv[2])
    details = json.loads((root / "preparation.json").read_text(encoding="utf-8"))
    if details["source_dispatch_count"] != 0 or details["soak_years"] != 0:
        raise RuntimeError("prepared root was used for disallowed calendar execution")
    original_path = (
        root / "sources" / "Ada-Telugu" / HIST_COMMIT /
        "src" / "normative_oracle.adb"
    )
    original = original_path.read_bytes()
    if git_blob(original) != ORACLE_BLOB:
        raise RuntimeError("original Ada Git-blob source lock mismatch")

    new = patch(original)
    dest_src = root / "ada-build" / "src"
    oracle = dest_src / "normative_oracle.adb"
    if not oracle.exists():
        raise RuntimeError("expected disposable Ada source copy is missing")

    requirements = [
        "canonical_full_weave_gmp_v164.ads",
        "canonical_full_weave_gmp_v164.adb",
        "canonical_wide_rank_gmp_v164.ads",
        "canonical_wide_rank_gmp_v164.adb",
    ]
    hashes: dict[str, str] = {}
    for filename in requirements:
        item = candidate / filename
        output = dest_src / filename
        if not item.is_file() or output.exists():
            raise RuntimeError("GMP dependency absent or destination already occupied")
        hashes[filename] = sha(item.read_bytes())
        shutil.copyfile(item, output)
    oracle.write_bytes(new)

    (root / "ada-build" / "issue29-gmp-oracle-qa-compile.gpr").write_text(
        PROJECT, encoding="utf-8"
    )
    old_text = original.decode("utf-8")
    diff = "".join(unified_diff(
        old_text.splitlines(keepends=True),
        new.decode("utf-8").splitlines(keepends=True),
        fromfile="historical/src/normative_oracle.adb",
        tofile="disposable-QA/src/normative_oracle.adb",
    ))
    (root / "v164-qa-oracle.patch").write_text(diff, encoding="utf-8")
    receipt = {
        "schema": "ISSUE29_V164_SOURCE_LOCKED_REVERSIBLE_GMP_QA_COMPILE_ONLY/1",
        "source_commit": HIST_COMMIT,
        "source_git_blob_sha1": ORACLE_BLOB,
        "source_sha256": sha(original),
        "qa_oracle_sha256": sha(new),
        "dependencies_sha256": hashes,
        "exact_byte_reversibility": True,
        "source_calendar_F_calls": 0,
        "qa_calendar_F_calls": 0,
        "full_original_years": 0,
        "STOP_NEW_NATIVE_SOAK_DISPATCH": True,
        "mode": "QA_COPY_COMPILE_ONLY",
    }
    (root / "v164-qa-integration-receipt.json").write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8"
    )
    print("V164_GMP_ORACLE_QA_SOURCE_PINNED_EXACT_REVERSIBILITY_TRUE")
    print("V164_ZERO_CALENDAR_FCT_CALLS_ZERO_SOAK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
