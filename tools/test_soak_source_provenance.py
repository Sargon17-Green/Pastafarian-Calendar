#!/usr/bin/env python3
"""Synthetic Git repository tests for fail-closed source provenance checks."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile

FIXTURES = {
    "src/monster.cpp": "cpp calendar",
    "src/engine with spaces.cpp": "spaced source",
    "src/שפה Δ.cpp": "unicode source",
    "src/back\\slash.cpp": "backslash source",
    "include/pastafari/odd [x] ; #$.hpp": "metachar source",
    "include/pastafari/line\nbreak.hpp": "newline source",
    "include/pastafari/monster.hpp": "header",
    "include/pastafari/source_language_catalog.hpp": "source names",
    "tools/soak_vector_adapter.cpp": "stream adapter",
    "tools/validate_soak_index_modes.py": "index validator",
}


def run_git(root, *args):
    result = subprocess.run(
        ["git", "-C", str(root), *args], check=True,
        capture_output=True, text=True, timeout=20
    )
    return result.stdout.strip()


def commit(root, message):
    run_git(root, "add", "-A")
    run_git(root, "commit", "-qm", message)
    return run_git(root, "rev-parse", "HEAD")


def probe(tool, repo, manifest, base, head, expected, reason_contains=None):
    result = subprocess.run(
        [sys.executable, str(tool), "--repository", str(repo),
         "--manifest", str(manifest), "--expected-engine-commit", base,
         "--expected-head", head],
        check=False, capture_output=True, text=True, timeout=25
    )
    lines = result.stdout.splitlines()
    if result.stderr or len(lines) != 1:
        raise AssertionError("non-machine-readable probe result")
    parsed = json.loads(lines[0])
    if (parsed.get("source_verified") is not expected or
            (result.returncode == 0) is not expected or
            parsed.get("binary_attested") is not False or
            parsed.get("global_soak_executed") is not False):
        raise AssertionError(f"wrong provenance verdict: {parsed!r}")
    if not expected and not parsed.get("reason"):
        raise AssertionError("missing fail-closed reason")
    if reason_contains and reason_contains not in parsed.get("reason", ""):
        raise AssertionError(f"unexpected fail-closed reason: {parsed!r}")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: test_soak_source_provenance.py TOOL")
    tool = Path(sys.argv[1]).resolve()
    count = 0
    with tempfile.TemporaryDirectory(prefix="cpp-latina-provenance-") as tmp:
        root = Path(tmp)
        run_git(root, "init", "-q")
        run_git(root, "config", "user.email", "ci@example.invalid")
        run_git(root, "config", "user.name", "Soak QA")
        for name, content in FIXTURES.items():
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        base = commit(root, "certified-engine")
        manifest = root / "manifest.json"
        metadata = {
            "repository": "Sargon17-Green/Pastafarian-Calendar",
            "branch": "C++&Latina",
            "implementation_id": "pastafarian-calendar-cpp-latina",
            "engine_verified_commit": base,
        }
        manifest.write_text(json.dumps(metadata), encoding="utf-8")
        probe(tool, root, manifest, base, base, True)
        count += 1
        (root / "README.md").write_text("metadata-only", encoding="utf-8")
        docs = commit(root, "metadata-only")
        probe(tool, root, manifest, base, docs, True)
        count += 1
        probe(tool, root, manifest, "0" * 40, docs, False)
        count += 1
        probe(tool, root, manifest, base, "0" * 40, False)
        count += 1
        invalid = dict(metadata)
        invalid["engine_verified_commit"] = "f" * 40
        manifest.write_text(json.dumps(invalid), encoding="utf-8")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        manifest.write_text(json.dumps(metadata), encoding="utf-8")
        (root / "src/monster.cpp").write_text("modified, not staged", encoding="utf-8")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        run_git(root, "add", "src/monster.cpp")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        run_git(root, "reset", "--hard", docs)
        foreign = root / "src/new_engine.cpp"
        foreign.write_text("untracked", encoding="utf-8")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        foreign.unlink()
        # Git's index can hide these modified files from ordinary git diff.
        run_git(root, "update-index", "--assume-unchanged", "src/monster.cpp")
        (root / "src/monster.cpp").write_text(
            "modified behind assume-unchanged", encoding="utf-8"
        )
        probe(tool, root, manifest, base, docs, False)
        count += 1
        run_git(root, "update-index", "--no-assume-unchanged", "src/monster.cpp")
        run_git(root, "reset", "--hard", docs)
        run_git(root, "update-index", "--skip-worktree", "src/monster.cpp")
        (root / "src/monster.cpp").write_text(
            "modified behind skip-worktree", encoding="utf-8"
        )
        probe(tool, root, manifest, base, docs, False)
        count += 1
        run_git(root, "update-index", "--no-skip-worktree", "src/monster.cpp")
        run_git(root, "reset", "--hard", docs)
        # A compiler may still use sources ignored by Git's status filters.
        (root / ".git/info/exclude").write_text(
            "src/ignored_shadow.hpp\n", encoding="utf-8"
        )
        ignored = root / "src/ignored_shadow.hpp"
        ignored.write_text("shadow source", encoding="utf-8")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        ignored.unlink()
        # Even byte-identical symlink aliases are not pinned source bytes.
        original = root / "src/monster.cpp"
        original.unlink()
        original.symlink_to("monster_alias.cpp")
        (root / "src/monster_alias.cpp").write_text("cpp calendar", encoding="utf-8")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        original.unlink()
        (root / "src/monster_alias.cpp").unlink()
        run_git(root, "reset", "--hard", docs)
        (root / "include/pastafari/monster.hpp").write_text("changed code", encoding="utf-8")
        changed_head = commit(root, "changed-engine")
        probe(tool, root, manifest, base, changed_head, False)
        count += 1
        run_git(root, "reset", "--hard", docs)
        manifest.write_text("[]", encoding="utf-8")
        probe(tool, root, manifest, base, docs, False)
        count += 1
        manifest.write_text(json.dumps(metadata), encoding="utf-8")
        probe(tool, root, manifest, base, docs, True)
        count += 1
        # Filenames with whitespace, Unicode, Git-quotable metacharacters,
        # a literal backslash, or an embedded newline must be byte-pinned.
        special_tracked = (
            "src/engine with spaces.cpp",
            "src/שפה Δ.cpp",
            "src/back\\slash.cpp",
            "include/pastafari/odd [x] ; #$.hpp",
            "include/pastafari/line\nbreak.hpp",
        )
        for name in special_tracked:
            # Hide this mutation from index-based git diff, forcing the raw
            # NUL-separated tracked-path and worktree-byte check to detect it.
            run_git(root, "update-index", "--assume-unchanged", "--", name)
            (root / name).write_text("tampered protected source", encoding="utf-8")
            probe(tool, root, manifest, base, docs, False,
                  "protected source bytes differ from HEAD:")
            count += 1
            run_git(root, "update-index", "--no-assume-unchanged", "--", name)
            run_git(root, "reset", "--hard", docs)
        # The same unusual tracked paths must remain byte-pinned even when
        # skip-worktree makes index-based diffs omit worktree changes.
        for name in special_tracked:
            run_git(root, "update-index", "--skip-worktree", "--", name)
            if not run_git(root, "ls-files", "-v", "--", name).startswith("S "):
                raise AssertionError(f"skip-worktree flag not set: {name!r}")
            (root / name).write_text("tampered behind skip-worktree", encoding="utf-8")
            probe(tool, root, manifest, base, docs, False,
                  "protected source bytes differ from HEAD:")
            count += 1
            run_git(root, "update-index", "--no-skip-worktree", "--", name)
            run_git(root, "reset", "--hard", docs)
        probe(tool, root, manifest, base, docs, True)
        count += 1
        # Odd untracked names, including ignored files, must fail closed.
        special_untracked = (
            "src/untracked with spaces.cpp",
            "src/לא במעקב.hpp",
            "include/pastafari/new\nline.hpp",
        )
        for name in special_untracked:
            path = root / name
            path.write_text("unexpected source", encoding="utf-8")
            probe(tool, root, manifest, base, docs, False,
                  "untracked or ignored protected source files:")
            count += 1
            path.unlink()
        probe(tool, root, manifest, base, docs, True)
        count += 1
        # A tracked source deleted behind skip-worktree is not an authorized
        # sparse omission: protected source bytes must actually be present.
        # Check both Unicode and literal-newline filenames, and recover using
        # a forced worktree restore after clearing the index bit.
        for name in ("src/שפה Δ.cpp", "include/pastafari/line\nbreak.hpp"):
            run_git(root, "update-index", "--skip-worktree", "--", name)
            if not run_git(root, "ls-files", "-v", "--", name).startswith("S "):
                raise AssertionError(f"skip-worktree flag not set: {name!r}")
            (root / name).unlink()
            probe(tool, root, manifest, base, docs, False,
                  "protected source missing or symlinked:")
            count += 1
            run_git(root, "update-index", "--no-skip-worktree", "--", name)
            run_git(root, "restore", "--source=HEAD", "--worktree", "--", name)
            if not (root / name).is_file():
                raise AssertionError(f"protected source not restored: {name!r}")
            probe(tool, root, manifest, base, docs, True)
            count += 1
        # Exercise Git sparse-checkout itself rather than manually unlinking
        # a skip-worktree file. Git must actually omit a tracked protected path
        # and mark its index entry S; provenance must still fail closed.
        for name in ("src/monster.cpp", "include/pastafari/monster.hpp"):
            run_git(root, "sparse-checkout", "set", "--no-cone",
                    "/*", "!/" + name)
            if (root / name).exists():
                raise AssertionError(f"sparse-checkout did not omit: {name!r}")
            if not run_git(root, "ls-files", "-v", "--", name).startswith("S "):
                raise AssertionError(f"sparse omission lacks skip-worktree: {name!r}")
            probe(tool, root, manifest, base, docs, False,
                  "protected source missing or symlinked:")
            count += 1
            run_git(root, "sparse-checkout", "disable")
            if not (root / name).is_file():
                raise AssertionError(f"sparse-checkout failed to restore: {name!r}")
            probe(tool, root, manifest, base, docs, True)
            count += 1
        # Cone sparse-index may collapse src/ to one tree entry while keeping
        # include/ materialized. The absence of protected source bytes must
        # fail closed even when Git's index represents a sparse directory.
        run_git(root, "sparse-checkout", "set", "--cone", "--sparse-index",
                "include", "tools")
        sparse_stage = run_git(root, "ls-files", "--sparse", "--stage", "--", "src")
        sparse_flags = run_git(root, "ls-files", "--sparse", "-v", "--", "src")
        if not (sparse_stage.startswith("040000 ") and
                sparse_stage.endswith("\tsrc/") and sparse_flags == "S src/"):
            raise AssertionError("src/ was not represented by a sparse-index directory")
        if ((root / "src/monster.cpp").exists() or
                not (root / "include/pastafari/monster.hpp").is_file()):
            raise AssertionError("cone sparse-checkout did not selectively omit src/")
        probe(tool, root, manifest, base, docs, False,
              "protected source missing or symlinked:")
        count += 1
        run_git(root, "sparse-checkout", "disable")
        if not (root / "src/monster.cpp").is_file():
            raise AssertionError("cone sparse-checkout did not restore src/")
        probe(tool, root, manifest, base, docs, True)
        count += 1
        # The reverse cone sparse-index case must fail closed as well:
        # include/ is omitted while protected src/ and tools/ remain on disk.
        run_git(root, "sparse-checkout", "set", "--cone", "--sparse-index",
                "src", "tools")
        sparse_stage = run_git(root, "ls-files", "--sparse", "--stage", "--", "include")
        sparse_flags = run_git(root, "ls-files", "--sparse", "-v", "--", "include")
        if not (sparse_stage.startswith("040000 ") and
                sparse_stage.endswith("\tinclude/") and sparse_flags == "S include/"):
            raise AssertionError("include/ was not represented by a sparse-index directory")
        if ((root / "include/pastafari/monster.hpp").exists() or
                not (root / "src/monster.cpp").is_file() or
                not (root / "tools/soak_vector_adapter.cpp").is_file()):
            raise AssertionError("cone sparse-checkout did not selectively omit include/")
        probe(tool, root, manifest, base, docs, False,
              "protected source missing or symlinked:")
        count += 1
        run_git(root, "sparse-checkout", "disable")
        if not (root / "include/pastafari/monster.hpp").is_file():
            raise AssertionError("cone sparse-checkout did not restore include/")
        probe(tool, root, manifest, base, docs, True)
        count += 1
    print(f"SOAK_SOURCE_PROVENANCE_TESTS={count}/{count}_PASS")


if __name__ == "__main__":
    main()
