# SQL+தமிழ் — Stage2 Slice25 full-selector fast-window QA regression
Date: 2026-11-20. PROJECT_ID=PC-BRANCH-SQL-TAMIL. Branch SQL+தமிழ்; verified pre-write HEAD e4dccbfa3ab999031f2c1b51bab6e2567712360c. No main, merge, publication, or production SQL edits.

## Verified original completed evidence on e4dccbfa3ab999031f2c1b51bab6e2567712360c
- Run 44811758812, attempt1, job 136549840040: completed/success, PG17.12, fast window 215291.598ms; 43 candidates; five exact field checks. Prior separate profile 44800413480 window 479828.815ms (55.13% lower, not a controlled performance experiment). Original ZIP artifact 14667521797 SHA256 ea5d06979a57a477c2be61c92021b50188c628f8cbcc61bbbf47bff74efbf978 matches GitHub/upload/raw bytes, 9/9 CRC. 32 source SHA lines (corrected from 31 after original ZIP inspection), generated SQL SHA256 2a2f476596358b841332eba98616a2b2f774b34ea94d21dac00868e76b898f0d, 4644 synthetic cases.
- Run 44811758616, job 136549838820: completed/success Stage1 (reference 52, saved-sum 7, heavy 3, isolation 4); original ZIP 14667646626 SHA256 7e2301669b46e46f3c40847179d075decf03a9e3645e3d5d7e06ef013e687ba0 matches GitHub/upload/raw bytes, 3/3 CRC.
- Run 44811758498, job 136549838885: Names Lock completed/success on same SHA; no ZIP artifact.
- Historical original selector baseline 44716273498: 5/8 success, three timeouts.

## New bounded regression protocol (NOT yet Native PASS)
- Source-lock eight years (4996, 4997, 4998, 5000, 5001, 5002, 5003, 5004) and 29 golden cases from pre-existing accepted fixtures; use unchanged input generator 153 and full-selector benchmark 154.
- In each ephemeral offline PG17 database load unchanged production sql/00..26; override year5000_gate_window in the DATABASE ONLY with single-walk QA function from file 158 (new override file 160). Then invoke genuine production find_target_year once in each of eight cases: prev_3_prev,prev_3,prev_2,anchor,next_1,next_2,next_3,next_3_next. No production Git source edit.
- Natural-push workflow adds 8 matrix jobs, max-parallel=2, 15-minute per job, 12-minute statement timeout, and preserves input.sql, source+generated SHA256, versions, test output, completion marker; per job 5 exact typed field flags plus 6 invalid-input flags and elapsed ms. All eight exact-year outputs, including historical timeout cases, must be verified.
- Acceptance of this QA regression requires 8/8 completed jobs, 40/40 field flags, 48/48 invalid-input flags, no timeout; original ZIP SHA256 must match GitHub digest, original upload job log AND downloaded bytes, ZIP CRC. Pending jobs are neither PASS nor blockers. Do not dispatch duplicate CI.
- This is NOT Slice25 calendar_date implementation or full-stage acceptance (Native>=40, isolation>=8, differential>=24). If QA regression proves 8/8, next independently construct >=24 reachable days across >=8 years plus an independent Tamil ordinal/text oracle, then implement production calendar_date and all required gates. No main/merge/publication.
