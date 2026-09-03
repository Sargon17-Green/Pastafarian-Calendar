Pastafari Calendar — Stage 59 corrected delta, Web-UI edition

Use this package only AFTER the rollback workflow has completed successfully.
Expected rollback tree: 3e6fe2bb035a300b02d33534015e4011ea767019.

Recommended Web UI application:
1. Open `.github/workflows/` on branch `JavaScript+Interlingue`.
2. Upload `javascript-interlingue-stage59-apply-corrected.yml` there with exactly that filename.
3. Commit directly to the branch.
4. The push automatically starts the workflow.
5. The workflow reconstructs Stage 59 from the retained historical commits, writes files only to
   `server/`, `tests/`, and `.github/workflows/`, runs verification, commits the corrected delta,
   pushes it, and removes the temporary apply workflow from the final tree.

Do not manually upload the files from REFERENCE_CORRECTED_TREE.zip unless you specifically want
to inspect or compare the intended hierarchy. It is a reference copy, not the recommended installer.

The root `package.json` and root `README.md` must remain exactly as they were before Stage 59.
