from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tomllib
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
EXPECTED_HEAD_ENV = "GITHUB_SHA"
FORBIDDEN_DOC_MARKERS = (
    "0.1.0-stage1",
    "PASS olarak iddia edilmemektedir",
)


def _git(*args: str) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    return completed.stdout.strip()


class ReleaseCandidateFreezeAudit(unittest.TestCase):
    def test_01_release_metadata_is_frozen_at_1_0_0(self):
        with (REPO_ROOT / "pyproject.toml").open("rb") as stream:
            project = tomllib.load(stream)["project"]

        self.assertEqual(project["name"], "pastafari-calendar-python")
        self.assertEqual(project["version"], "1.0.0")
        self.assertEqual(project["requires-python"], ">=3.11")
        self.assertEqual(project["readme"], "README.md")
        self.assertIn("tamamlanmış", project["description"])

    def test_02_release_documentation_has_no_pre_release_markers(self):
        readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("Paket sürümü `1.0.0`", readme)
        self.assertIn("421 PASS", readme)
        for marker in FORBIDDEN_DOC_MARKERS:
            with self.subTest(marker=marker):
                self.assertNotIn(marker, readme)

    def test_03_tracked_tree_has_no_generated_python_release_artifacts(self):
        tracked = tuple(filter(None, _git("ls-files").splitlines()))
        forbidden: list[str] = []

        for raw_path in tracked:
            path = Path(raw_path)
            parts = path.parts
            if "__pycache__" in parts or raw_path.endswith((".pyc", ".pyo")):
                forbidden.append(raw_path)
                continue
            if parts and parts[0] in {"build", "dist", ".venv"}:
                forbidden.append(raw_path)
                continue
            if any(part.endswith(".egg-info") for part in parts):
                forbidden.append(raw_path)

        self.assertEqual(forbidden, [])

    def test_04_rc_head_matches_ci_and_tracked_worktree_is_clean(self):
        head = _git("rev-parse", "HEAD")
        expected_head = os.environ.get(EXPECTED_HEAD_ENV)
        if expected_head:
            self.assertEqual(head, expected_head)

        tracked_status = _git("status", "--porcelain", "--untracked-files=no")
        self.assertEqual(tracked_status, "")
        print(f"RC_FREEZE=PASS head={head}")


if __name__ == "__main__":
    unittest.main()
