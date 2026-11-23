# Post55 three-JVM artifact verifier: bounded threat-model review (2026-11-23)

PROJECT_ID: PC-BRANCH-KOTLIN-CYMRAEG
Branch: Kotlin+Cymraeg
Reviewed parent HEAD: a8639d74675b98c12a862d87018c130006c2bb37
Pinned source commit: 25973c99d92c688e7cd4c30db71e2df58cdfb1fd
Pinned immutable source artifact: 14772808348
Expected full GitHub artifact ZIP SHA-256: 17559d9ecaadae66a522571c6a188edd74fe893963713e35545ec9dc6108388c

## Novel identified gap: ZIP file-type metadata

The previous verifier checked unique names (22), path traversal, member sizes, non-directory status, CRC, archive SHA-256, and coverage/hash correctness of the 20-entry SHA256SUMS manifest. It did not inspect the file-type bits in each ZIP member's external_attr. A Unix symlink encoded with create_system=3, external_attr=(0o120777 << 16) and regular-looking filename passes ZipInfo.is_dir(), zipfile.testzip(), and all content-hash/manifest checks when the envelope digest is re-signed. The verifier only reads ZIP member bytes; it does not extract, so this is evidence-type confusion rather than a demonstrated code execution or path traversal exploit.

Mitigation: reject any explicit member type other than regular file (allow unset type for normal ZIP writers) with E_UNSAFE_MEMBER_TYPE, before reading member payloads. Mutation test re-packages the complete 22-entry valid synthetic ZIP, preserves payloads and manifest, changes one process JSON to symlink metadata, recomputes envelope SHA-256, and expects rejection. Workflow's exact-count test guard is updated from 9 to 10; pinned real artifact regression remains mandatory. No production code, protocol fields, or accepted source lock are changed.

## Manifest and source binding

SHA256SUMS.txt covers exactly 20 cold-warm/ member payloads; it does not separately hash itself or cold-warm-run.log. The full ZIP SHA-256 is pinned by the workflow, so those bytes are still covered by the envelope digest. Names, count and content-hashes are checked. The pinned expected source SHA is matched against the summary and each worker JSON. JAR SHA-256 is a claim cross-checked between summary and workers, **not** recalculated from executable JAR bytes inside the ZIP. Worker PID and elapsed-time assertions are report claims; the auditor does not independently attest to OS process identity.

## Production transcripts versus reported oracle fields

The production.tsv rows contain seven integer fields and the worker JSON matches arrays must mirror each row. The auditor checks equal=true and that oracle_five equals production fields [2:], plus 33 gate metrics and 560 signed gaps per worker, with cross-worker byte equivalence and zero reported mismatches. This provides structural/cross-record consistency but **does not independently compute an oracle**: a consistently false production + reported oracle pair cannot be disproved by this verifier. Such correctness belongs to separate independent oracle gates, not this integrity-only audit.

## Certification boundary and evidence

Accepted parent evidence: run 45087337118/job 137408837827 (completed/success, 9/9 tests), archive 14780359950; Names Lock run 45087337301 (30 completed/success), Stage55 job 137408839972, component archive 14782357816. These runs predate the metadata hardening. New-SHA test/CI execution must be checked separately; neither passing syntax nor committed tests alone constitute a new Native PASS. No TABLETS/full-date/global independence, --certify, Stage56, main, merge, or release authorization.
