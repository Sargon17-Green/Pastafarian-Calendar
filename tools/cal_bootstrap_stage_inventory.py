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
PINNED_STAGE_TREES = (
    "79eda0a2b7a1e8861cfae4a49680819079c23a3c",
    "cc6ff6f4e9b0f17b2495e3822ada180af98bc1b6",
    "3abe2a4ea0ec0f8cf43898193771d712ba995882",
    "c6fc6adadc1b6324bd484a433e1279db5c14ac23",
    "77e0ec276db7fbcb8b1d6315b4e26d08081f8057",
    "33a2a2a974f80525fe8518c8028fc7dd1195f781",
    "06cc5724cf2efd9b16b78bdf05e32d6e952768a5",
    "9e97ceaae1cd92d385c10f5c03ee2d55b5b90e1a",
)
PINNED_COMPILER_BLOBS = (
    "1cdc47a3ad273e66a76d4a451bc9e79f1237bd4d",
    "f454af1822f57a1fbc743cc80128c5aea578ac4f",
    "0781c345751fa6728ddb8a870a15c187e0097ab6",
    "0c4820c4c93d55326c953de3a82c09902949c3da",
    "b032d0cc2d3ad85ce9ab309866b0ecde43a60c7a",
    "2fefa2df621f2bccacc95ecdaf91d2e95a461d8e",
    "4aa0a6e7a692c306b574d05e8f5cf0045d74cca4",
    "d8da5ace27c8131fa152312b4262e5792d0d4898",
)
PINNED_BINARY_BLOBS = (
    "6de1969837d67fa54ede65b73d356628bd0b18cb",
    "d90c5c4a0ac852e2543c1e514c3bd6decdf58a49",
    "d4d0578fc81bbfe86a4b22ef2c86ff7e3d67e290",
    "3ae3311a2326e8f4a446f62a53fa09d7dcbfca3f",
)



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
        insist(tree == PINNED_STAGE_TREES[number - 1],
               "upstream stage tree changed at " + label)
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
        insist(compiler_sha == PINNED_COMPILER_BLOBS[number - 1],
               "compiler blob replaced at " + label)
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
            insist(obj["sha"] == PINNED_BINARY_BLOBS[BINARY_NAMES.index(filename)],
                   "binary blob replaced at " + label + "/" + filename)
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
