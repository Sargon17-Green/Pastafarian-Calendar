#!/usr/bin/env python3
"""Validate immutable *metadata* for CAL's eight tutorial stages.

No downloads, imports of CAL components, compilation or binary execution.
The metadata came from pinned GitHub tree listings; this validator checks
manifest integrity/structure, not executable safety or an independent build.
"""
from __future__ import annotations

import json
from pathlib import Path
import re
import sys

MANIFEST = Path(__file__).with_name("cal_bootstrap_stage_manifest.json")
COMMIT = "2d44defdedf24519bba754114ee66e6d1defff1e"
PARENT_TREE = "33e3765b57d1e6ce879b5c7f69f48262738cbf66"
INSTRUCTIONS_BLOB = "c7fe98e764fe1ff4584a93645145956f1014041e"
LEXICON_TREE = "9bf396bf64b1cd543e2737a0210924c0cd9d7c6e"
DOCUMENTATION_TREE = "f3da442082ccf3af9801b1a24c2d38e8c5b7b3c1"
SOURCE_NAMES = frozenset((
    "the compiler", "the desktop", "the editor", "the finder",
    "the noodle", "the writer",
))
BINARY_NAMES = tuple("cal-4700's son.exe" + str(i) for i in range(2, 6))
SHA = re.compile(r"[0-9a-f]{40}\Z")


class ManifestError(ValueError):
    pass


def insist(condition: bool, message: str) -> None:
    if not condition:
        raise ManifestError(message)


def check_object(obj: dict, description: str) -> None:
    insist(isinstance(obj, dict), description + " must be an object")
    insist(set(obj) == {"sha", "size"}, description + ": unexpected fields")
    insist(isinstance(obj["sha"], str) and bool(SHA.fullmatch(obj["sha"])),
           description + ": invalid Git blob SHA")
    insist(type(obj["size"]) is int and obj["size"] > 0,
           description + ": invalid byte count")


def validate(manifest: dict) -> dict:
    insist(isinstance(manifest, dict), "root must be an object")
    insist(manifest.get("kind") == "PINNED_CAL_TUTORIAL_GIT_TREE_METADATA_NOT_EXECUTABLE_TRUST",
           "invalid report kind")
    insist(manifest.get("repository") == "elenderg/PAL-1000", "wrong source repo")
    insist(manifest.get("commit") == COMMIT, "upstream commit changed")
    insist(manifest.get("tutorial_parent_tree") == PARENT_TREE,
           "tutorial parent tree changed")
    insist(manifest.get("instructions_blob") == INSTRUCTIONS_BLOB,
           "instructions blob changed")
    for flag in ("binary_downloaded", "compiler_executed",
                 "stage_zero_verified", "native_qa_99_pass"):
        insist(manifest.get(flag) is False, "unsupported trust claim: " + flag)

    stages = manifest.get("stages")
    insist(isinstance(stages, list) and len(stages) == 8,
           "expected exactly eight tutorial stages")
    compilers = set()
    trees = set()
    previous_binaries = {}
    common_sources = None
    initial_noodle = None
    final_noodle = None
    for number, stage in enumerate(stages, 1):
        label = f"passo{number:02d}"
        insist(isinstance(stage, dict) and stage.get("stage") == label,
               "stage order mismatch at " + label)
        expected_fields = {"stage", "tree_sha", "lexicon_tree",
                           "sources", "binary_objects"}
        if number >= 7:
            expected_fields.add("documentation_tree")
        insist(set(stage) == expected_fields, "unexpected stage fields at " + label)
        tree = stage["tree_sha"]
        insist(isinstance(tree, str) and SHA.fullmatch(tree),
               "invalid tree SHA at " + label)
        insist(tree not in trees, "duplicate stage tree at " + label)
        trees.add(tree)
        insist(stage["lexicon_tree"] == LEXICON_TREE, "lexicon drift at " + label)
        if number >= 7:
            insist(stage["documentation_tree"] == DOCUMENTATION_TREE,
                   "documentation drift at " + label)
        sources = stage["sources"]
        insist(isinstance(sources, dict) and set(sources) == SOURCE_NAMES,
               "source set mismatch at " + label)
        for filename, obj in sources.items():
            check_object(obj, label + "/" + filename)
        compiler_sha = sources["the compiler"]["sha"]
        insist(compiler_sha not in compilers, "compiler stage reused at " + label)
        compilers.add(compiler_sha)
        stable_sources = {k: v for k, v in sources.items()
                          if k not in ("the compiler", "the noodle")}
        if common_sources is None:
            common_sources = stable_sources
            initial_noodle = sources["the noodle"]
        else:
            insist(stable_sources == common_sources, "runtime source drift at " + label)
        if number <= 7:
            insist(sources["the noodle"] == initial_noodle,
                   "unexpected noodle change at " + label)
        else:
            final_noodle = sources["the noodle"]
            insist(final_noodle != initial_noodle,
                   "missing final-stage noodle change")

        expected_binary_count = 0 if number <= 2 else 1 if number == 3 else 3 if number <= 6 else 4
        expected_binary_names = set(BINARY_NAMES[:expected_binary_count])
        binaries = stage["binary_objects"]
        insist(isinstance(binaries, dict) and set(binaries) == expected_binary_names,
               "stage binary list mismatch at " + label)
        for filename, obj in binaries.items():
            check_object(obj, label + "/" + filename)
            if filename in previous_binaries:
                insist(obj == previous_binaries[filename],
                       "previous binary changed at " + label + "/" + filename)
        previous_binaries = binaries
    return {
        "kind": "CAL_STAGE_MANIFEST_INTERNAL_CONSISTENCY_ONLY",
        "stage_metadata_consistent": True,
        "tutorial_stages": len(stages),
        "distinct_compiler_blobs": len(compilers),
        "distinct_binary_blob_metadata": len(previous_binaries),
        "first_stage_with_binary_metadata": "passo03",
        "binary_downloaded": False,
        "compiler_executed": False,
        "stage_zero_verified": False,
        "native_qa_99_pass": False,
    }


def main() -> int:
    try:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        result = validate(manifest)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print("STAGE_METADATA_REJECTED: " + str(exc), file=sys.stderr)
        return 2
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
