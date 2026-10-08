# Befunge+Кыргызча — GitHub repository relocation

**Correct repository:** `Sargon17-Green/Pastafarian-Calendar`, GitHub repository ID `1347352423`.

**Mistaken repository:** `Sargon17-Green/pastafari-calendar`, GitHub repository ID `1325151817`.

**Source snapshot:** `Befunge+Кыргызча` branch at commit `741c0423e37325e2e162cd691a3d51f6492b878c`; original implementation path `implementations/befunge-kyrgyz/`.

This migration places all **95** implementation, reference, tests, fixtures, and documentation blobs at this branch's repository **root**, matching other language branches. Original Befunge-98 `*.b98` binaries/sources are copied byte-for-byte and their Git blob SHA remains identical. The existing `main` branch `CANONICAL_NAMES_LOCK.sha256` and shared canonical workflows are retained.

The Stage-1 regression workflow is moved to `.github/workflows/befunge-kyrgyz-stage1-regression.yml` and its source paths rebased to the branch root. Old QA run URLs in copied documents are historical evidence generated in the mistaken repository; they are **not** evidence of a run in this repository. A full native replay is required here before Stage-1 claims can be adopted.

Stage 1/55 remains OPEN; `LAST_COMPLETED_STAGE=0`. Stage 2 has not begun. After destination verification, remove only Befunge-specific branches in the mistaken repository; do not touch that repository's `main` branch or unrelated content.
