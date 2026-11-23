# Three-JVM evidence: JAR and process provenance boundary (2026-11-23)

PROJECT_ID: PC-BRANCH-KOTLIN-CYMRAEG
Branch: Kotlin+Cymraeg
Audited parent HEAD: 14356028df3b621b60c966c83bb863b60455327a
Original source SHA: 25973c99d92c688e7cd4c30db71e2df58cdfb1fd
Original producer run/job: 45069238424 / 137352247087, completed/success, attempt 1
Immutable producer artifact ID: 14772808348
Original archive SHA256: 17559d9ecaadae66a522571c6a188edd74fe893963713e35545ec9dc6108388c
Accepted integrity QA: 45265564430 / 138011428312, completed/success, 10/10 tests
Accepted Names Lock: 45265564421, completed/success, 30/30 jobs; Stage55 FULL_NATIVE_GREEN

## Verified evidence and trust boundary

The original GitHub workflow checked out the exact source, compiled production Kotlin and the date bridge using Kotlin 1.9.0, invoked the three-worker audit with the resulting JAR, and uploaded a ZIP with the recorded digest. Producer log corroborates compilation and successful audit. The producer's Python source calculates SHA256 from actual JAR bytes and starts three Python workers; each worker hashes the provided JAR and uses subprocess.run to start Java. Thus the producing source contains actual checks, but the immutable artifact does not include executable JAR bytes or an independently signed compilation receipt.

The offline integrity verifier compares a 64-hex JAR digest claim in the summary with the same claim in each worker, not with the original JAR bytes; three positive distinct worker_python_pids are checked as integers, not attested against the OS process table. The original pinned archive digest protects the original archive against undetected mutation, but does not by itself attest the truth of claims inside it.

## New bounded QA (no producer rerun)

Two separate synthetic controls re-sign a coherent 22-member ZIP. One replaces all JAR digest claims and all dependent hashes; another changes three distinct PID values. The existing integrity-only verifier is expected to accept both after valid re-signing. This illustrates **the limits of the verifier's claims**; it is NOT evidence of a defect in actual Kotlin production, a fabricated authentic ZIP, or process fraud. Original 10 controls plus these 2 require 12/12 tests with zero skips; the authentic 14772808348 regression remains mandatory. No change to production implementation or to the original artifact.

## Prospective measurable provenance contract (design only, not implemented)

For a later authorized gate, bind source SHA, compiler distribution SHA/version, compile command, resulting JAR bytes or independently signed JAR digest, artifact digest and run/job identity in an independently verified build attestation. Record OS process-creation data (Java PID, parent worker PID, start time and executable/command fingerprint) with a separately trusted capture method; numeric Python PID declarations are insufficient. Negative controls: forged digest, substituted JAR, duplicate process lifetime and cross-run attestation mismatch must be rejected. Do not apply this stronger contract retroactively to the pinned ZIP; it lacks the required independent inputs.

Classification: existing integrity/Names results ACCEPTED at their exact SHA; this new QA-only test requires completed exact-SHA CI before acceptance. No new Stage56, --certify, TABLETS/full-date/global-independence certification, merge/main or release.
