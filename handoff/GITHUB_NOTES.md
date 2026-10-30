# Stage 1 Handoff - GitHub Notes

Branch: Fortran+English
Repository: Sargon17-Green/Pastafarian-Calendar

Stage 1 isolates neutral production bootstrap code from its test-only normative oracle. The production side does not yet implement the full calendar algorithm.

The bounded CI gate executes a selected Oracle smoke set, arithmetic boundaries, expected overflow rejections, and invalid-input checks. A successful bounded gate does not establish complete Stage 1 acceptance or authorize Stage 2. The full Oracle execution may be expensive and is not run by the bounded CI workflow.

Keep changes on the working branch. Do not merge into main or publish a release based on these checks.

This document was authored during focused Stage 1 QA because the original prose audit expected a handoff path absent from the branch. It is not a recovered historical artifact.
