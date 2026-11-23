#!/usr/bin/env python3
"""Negative-capability controls for claims NOT attested by the bounded ZIP verifier.

No new producer execution, no challenge to the authentic pinned artifact,
and no claim of independently audited source, JAR, or operating-system PIDs.
"""
import json
from pathlib import Path
import tempfile
import unittest

from verify_three_jvm_evidence_artifact import audit_zip
from test_verify_three_jvm_evidence_artifact import (
    SHA, digest, encoded, refresh_manifest, rebuild, synthetic_evidence,
)

INTEGRITY_ONLY = "PASS_POST55_ARTIFACT_INTEGRITY_ONLY_NOT_CERTIFIED"


class UnattestedProvenanceClaimsTests(unittest.TestCase):
    def check_resigned(self, files):
        refresh_manifest(files)
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "resigned.zip"
            archive_digest = rebuild(path, files)
            result = audit_zip(path, SHA, archive_digest)
        self.assertEqual(result["status"], INTEGRITY_ONLY)
        self.assertIs(result["independently_recomputes_oracle"], False)
        self.assertIs(result["certifies_full_date"], False)
        return result

    def test_resigned_jar_claim_is_consistent_but_not_byte_attested(self):
        # No JAR bytes inside the accepted evidence format. Arbitrary,
        # internally consistent digest claims still pass integrity-only.
        files = synthetic_evidence()
        summary_name = "cold-warm/cold-warm-report.json"
        summary = json.loads(files[summary_name])
        fabricated = "f" * 64
        summary["jar_sha256"] = fabricated
        for i in (1, 2, 3):
            worker_name = f"cold-warm/process-{i}.json"
            worker = json.loads(files[worker_name])
            worker["source"]["jar_sha256"] = fabricated
            files[worker_name] = encoded(worker)
            summary["worker_result_json_sha256"][i - 1] = digest(files[worker_name])
        files[summary_name] = encoded(summary)
        self.check_resigned(files)

    def test_resigned_distinct_pid_claims_are_not_os_attestations(self):
        # Distinct positive numbers meet the contract but are not evidence
        # from the runner process table, nor actual Java process identities.
        files = synthetic_evidence()
        summary_name = "cold-warm/cold-warm-report.json"
        summary = json.loads(files[summary_name])
        summary["worker_python_pids"] = [918001, 918002, 918003]
        files[summary_name] = encoded(summary)
        result = self.check_resigned(files)
        self.assertEqual(result["python_worker_pids_distinct"], 3)


if __name__ == "__main__":
    unittest.main()
