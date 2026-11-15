#!/usr/bin/env python3
"""Generate an explicitly DERIVED Kotlin annual-stream clone, never an original.

Reads exact original Kotlin branch snapshot, checks known Git blob and source
shape, copies all original Kotlin files byte-for-byte except one *derived copy*
that adds wholeYearAt(). Original dayAt() remains verbatim in the copy.
Do not count this as an independent converter or as an unchanged source.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil

ORIGINAL_COMMIT = "0c703446d8a3b7435698bd16402ac5fa30e461c9"
NATIVE_PATH = "src/main/kotlin/pastafari/ProductionMonthWeavingEngine.kt"
ORIGINAL_BLOB = "d69edc09b94ae630586c619bf8d0592fa21278de"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\x00" + data).hexdigest()


def exact_one(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise ValueError("expected exactly one native Kotlin method anchor: " + old[:70])
    return text.replace(old, new)


def derive(source: str) -> tuple[str, str]:
    signature = "    fun dayAt(rank1: BigInteger, targetOffset0: Int): Day {"
    if source.count(signature) != 1 or not source.endswith("    }\n\n}\n"):
        raise ValueError("unrecognized original immutable Kotlin weaving class shape")
    begin = source.index(signature)
    end = len(source) - len("\n}\n")
    original = source[begin:end]
    if not original.endswith("    }\n"):
        raise ValueError("cannot isolate exact original dayAt function")
    clone = exact_one(
        original, signature,
        "    fun wholeYearAt(rank1: BigInteger): List<Day> {",
    )
    clone = exact_one(
        clone,
        '        require(targetOffset0 in 0 until totalDays) { "E_WEAVING_OFFSET" }',
        '        require(totalDays in 1..5778) { "E_WEAVING_OFFSET" }',
    )
    clone = exact_one(
        clone,
        "        for (position in 0..targetOffset0) {",
        "        val transcript = ArrayList<Day>(totalDays)\n"
        "        for (position in 0 until totalDays) {",
    )
    clone = exact_one(
        clone,
        '            check(found) { "E_WEAVING_UNRANK" }',
        '            check(found) { "E_WEAVING_UNRANK" }\n'
        '            transcript.add(Day(selected + 1, lengths[selected] - remaining[selected]))',
    )
    clone = exact_one(
        clone,
        "        return Day(selected + 1, lengths[selected] - remaining[selected])",
        '        check(remaining.all { it == 0 } && opened == lengths.size &&\n'
        '            closed == lengths.size && transcript.size == totalDays) {\n'
        '            "E_WEAVING_DERIVED_FULL_YEAR_NOT_COMPLETE"\n'
        '        }\n'
        '        return transcript',
    )
    if "targetOffset0" in clone or "fun dayAt(" in clone:
        raise ValueError("cloned function still references native per-day offset")
    derived_source = source[:end] + "\n" + clone + source[end:]
    if derived_source.count(original) != 1 or derived_source.count("fun wholeYearAt(") != 1:
        raise ValueError("cannot prove original dayAt remained verbatim in derivative")
    return derived_source, original


def generate(original_dir: Path, out_dir: Path):
    if out_dir.exists():
        raise FileExistsError("derived output must not overwrite any existing directory")
    source_dir = original_dir / "src/main/kotlin/pastafari"
    source = source_dir / "ProductionMonthWeavingEngine.kt"
    if not source.is_file():
        raise FileNotFoundError(str(source))
    raw = source.read_bytes()
    if git_blob(raw) != ORIGINAL_BLOB:
        raise ValueError("pinned Kotlin weaving Git blob mismatch")
    if b"\r\n" in raw:
        raise ValueError("unexpected original line endings")
    text = raw.decode("utf-8")
    derived_text, original_method = derive(text)
    sources = sorted(source_dir.glob("*.kt"))
    if len(sources) < 10:
        raise ValueError("incomplete pinned Kotlin source closure")
    provenance = {
        "schema": "PASTAFARI_KOTLIN_FULL_YEAR_DERIVATIVE_V028/1",
        "status": "EXPERIMENTAL_DERIVED_NOT_UNCHANGED_SOURCE_NOT_INDEPENDENT",
        "original_commit": ORIGINAL_COMMIT,
        "pinned_original_weaving_git_blob": ORIGINAL_BLOB,
        "original_weaving_sha256": sha256(raw),
        "original_dayAt_function_sha256": sha256(original_method.encode("utf-8")),
        "derived_source_sha256": sha256(derived_text.encode("utf-8")),
        "derived_wholeYearAt_function_sha256":
            sha256(derived_text.split("    fun wholeYearAt(", 1)[1].split("\n    }\n\n}", 1)[0].encode("utf-8")),
        "source_files_copied_from_original": [],
        "native_dayAt_original_method_preserved": True,
        "independent_source_claim": False,
        "canonical_oracle_certified": False,
        "validated_full_year_comparisons": 0,
        "original_source_mutated": False,
        "main_updates_allowed": False,
    }
    dest = out_dir / "src/main/kotlin/pastafari"
    dest.mkdir(parents=True, exist_ok=False)
    for file in sources:
        data = file.read_bytes()
        target = dest / file.name
        if file.name == "ProductionMonthWeavingEngine.kt":
            target.write_bytes(derived_text.encode("utf-8"))
        else:
            target.write_bytes(data)
        provenance["source_files_copied_from_original"].append({
            "path": file.name,
            "original_sha256": sha256(data),
            "copied_sha256": sha256(target.read_bytes()),
            "is_derived": file.name == "ProductionMonthWeavingEngine.kt",
        })
    (out_dir / "PROVENANCE.json").write_text(
        json.dumps(provenance, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    print("KOTLIN_ANNUAL_DERIVATIVE_CREATED=" + json.dumps({
        "status": provenance["status"],
        "original_commit": ORIGINAL_COMMIT,
        "derived_source_sha256": provenance["derived_source_sha256"],
        "copied_files": len(sources),
        "dayAt_original_method_preserved": True,
        "full_year_verifications": 0,
    }, sort_keys=True), flush=True)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--original-repository", type=Path, required=True)
    p.add_argument("--output-dir", type=Path, required=True)
    args = p.parse_args()
    generate(args.original_repository.resolve(), args.output_dir.resolve())


if __name__ == "__main__":
    main()
