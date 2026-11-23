#!/usr/bin/env python3
"""Self-contained synthetic and mutation tests for the artifact auditor.

Optional authentic-artifact regression: POST55_ARTIFACT_ZIP=/path/to/downloaded.zip.
"""
import hashlib
import json
import os
from pathlib import Path
import tempfile
import unittest
import zipfile

from verify_three_jvm_evidence_artifact import audit_zip, AuditError

SHA = "25973c99d92c688e7cd4c30db71e2df58cdfb1fd"
REAL = os.environ.get("POST55_ARTIFACT_ZIP", "")


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def encoded(obj):
    return (json.dumps(obj, sort_keys=True, indent=2) + "\n").encode()


def refresh_manifest(files):
    mapping = {}
    for name, blob in files.items():
        if name.startswith("cold-warm/") and name != "cold-warm/SHA256SUMS.txt":
            mapping[name.removeprefix("cold-warm/")] = digest(blob)
    files["cold-warm/SHA256SUMS.txt"] = "".join(
        f"{mapping[name]}  {name}\n" for name in sorted(mapping)).encode()


def rebuild(path, files):
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for name in sorted(files):
            z.writestr(name, files[name])
    return digest(path.read_bytes())


def synthetic_evidence():
    root = "cold-warm/"
    files = {"cold-warm-run.log": b"synthetic\n", root + "protocol-tests.log": b"8 synthetic OK\n"}
    days = list(range(-100, -89))
    interleaved = [days[i] for i in (10, 5, 9, 6, 8, 7, 4, 0, 3, 1, 2)]
    orders = [("natural", days), ("reverse", list(reversed(days))),
              ("interleaved", interleaved)]
    all_rows = [(name, target, [-100, target, 5000, 10, 501, 20, 55])
                for name, days_in_order in orders for target in days_in_order]
    prod = "".join("\t".join(map(str, row)) + "\n" for _, _, row in all_rows).encode()
    metrics = ("order\ttarget\texpanded_gate_count\n" +
               "".join(f"{name}\t{target}\t23\n" for name, target, _ in all_rows)).encode()
    gaps = "".join(f"{idx}\t42\n" for idx in
                   list(range(-1, -281, -1)) + list(range(1, 281))).encode()
    jar_sha = "a" * 64
    json_hashes = []
    for i in (1, 2, 3):
        prefix = root + f"process-{i}."
        worker = {
            "source": {"git_sha": SHA, "jar_sha256": jar_sha},
            "status": "PASS_BOUNDED_UNSEEDED_THREE_ORDER_YEAR_EDGE_NOT_CERTIFIED",
            "project_id": "PC-BRANCH-KOTLIN-CYMRAEG", "branch": "Kotlin+Cymraeg",
            "production_calls": 33, "production_columns": 7, "distinct_targets": 11,
            "order_count": 3, "independent_five_field_comparisons": 165,
            "signed_gate_gap_questions": 560, "production_gate_metric_count": 33,
            "production_configured_gate_limit": 8192,
            "production_gate_metric_max_allowed": 16385, "mismatches": 0,
            "single_jvm_session": True, "order_invariance_verified": True,
            "production_actual_gate_count_exposed": True,
            "production_gate_metric_order_invariant": True,
            "checkpoint_seed_used": False, "pinned_reference_used": False,
            "shared_cross_branch_fixture_used": False,
            "full_date_certified": False, "tablets_certified": False,
            "global_algorithmic_independence_certified": False,
            "certifiable": False, "elapsed_seconds": 125.0,
            "production_stdout_sha256": digest(prod),
            "production_gate_metric_sha256": digest(metrics),
            "signed_gate_gap_sha256": digest(gaps), "calculation_day": -100,
            "matches": [{"target": target, "production_seven": row,
                         "oracle_five": row[2:], "equal": True}
                        for _, target, row in all_rows],
            "production_expanded_gate_counts": [
                {"target": target, "expanded_gate_count": 23} for target in days],
        }
        for name, blob in (("production.tsv", prod), ("metrics.tsv", metrics),
                           ("gaps.tsv", gaps), ("stdout.log", b"simulated\n"),
                           ("stderr.log", b""), ("json", encoded(worker))):
            files[prefix + name] = blob
        json_hashes.append(digest(files[prefix + "json"]))
    summary = {
        "project_id": "PC-BRANCH-KOTLIN-CYMRAEG", "branch": "Kotlin+Cymraeg",
        "source_sha": SHA, "status": "PASS_BOUNDED_THREE_COLD_JVM_SESSIONS_NOT_CERTIFIED",
        "qa_scope": "bounded-post55-only", "certifiable": False,
        "full_date_certified": False, "tablets_certified": False,
        "global_algorithmic_independence_certified": False,
        "jvm_processes_required": 3, "jvm_sessions": 3, "distinct_targets": 11,
        "seven_column_rows": 99, "five_field_comparisons": 495,
        "ordered_gate_metrics": 99, "independent_signed_gaps": 1680,
        "mismatches": 0, "worker_python_pids": [1201, 1202, 1203],
        "jar_sha256": jar_sha, "worker_result_json_sha256": json_hashes,
        "worker_elapsed_seconds": [125.0] * 3, "elapsed_seconds": 375.0,
        "per_target_expanded_gates": [{"target": target, "count": 23} for target in days],
    }
    files[root + "cold-warm-report.json"] = encoded(summary)
    refresh_manifest(files)
    return files


class ArtifactVerifierTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.source = Path(self.tmp.name) / "fixture.zip"
        self.source_digest = rebuild(self.source, synthetic_evidence())

    def mutate(self, change, update_manifest=False):
        with zipfile.ZipFile(self.source) as z:
            files = {name: z.read(name) for name in z.namelist()}
        change(files)
        if update_manifest:
            refresh_manifest(files)
        path = Path(self.tmp.name) / "modified.zip"
        return path, rebuild(path, files)

    def test_synthetic_valid_archive(self):
        r = audit_zip(self.source, SHA, self.source_digest)
        self.assertEqual(r["status"], "PASS_POST55_ARTIFACT_INTEGRITY_ONLY_NOT_CERTIFIED")
        self.assertIs(r["independently_recomputes_oracle"], False)

    @unittest.skipUnless(REAL and Path(REAL).is_file(), "authentic ZIP not supplied")
    def test_authentic_pinned_artifact(self):
        p = Path(REAL)
        r = audit_zip(p, SHA, digest(p.read_bytes()))
        self.assertEqual(r["signed_gap_rows"], 1680)

    def test_re_signed_symlink_member_rejected(self):
        # A symlink entry can have correct contents, CRC and all 20 manifest hashes.
        with zipfile.ZipFile(self.source) as existing:
            files = {name: existing.read(name) for name in existing.namelist()}
        path = Path(self.tmp.name) / "symlink.zip"
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as z:
            for name, payload in sorted(files.items()):
                if name == "cold-warm/process-1.json":
                    member = zipfile.ZipInfo(name)
                    member.create_system = 3
                    member.external_attr = 0o120777 << 16
                    member.compress_type = zipfile.ZIP_DEFLATED
                    z.writestr(member, payload)
                else:
                    z.writestr(name, payload)
        with zipfile.ZipFile(path) as z:
            link = z.getinfo("cold-warm/process-1.json")
            self.assertFalse(link.is_dir())
            self.assertIsNone(z.testzip())
        with self.assertRaisesRegex(AuditError, "E_UNSAFE_MEMBER_TYPE"):
            audit_zip(path, SHA, digest(path.read_bytes()))

    def test_wrong_artifact_digest(self):
        with self.assertRaisesRegex(AuditError, "E_ARTIFACT_SHA256"):
            audit_zip(self.source, SHA, "f" * 64)

    def test_extra_member_rejected(self):
        p, d = self.mutate(lambda x: x.update({"extra.txt": b"tamper"}))
        with self.assertRaisesRegex(AuditError, "E_MEMBER_COUNT_OR_DUPLICATE"):
            audit_zip(p, SHA, d)

    def test_mutation_with_stale_manifest(self):
        def modify(files):
            p = "cold-warm/process-2.metrics.tsv"
            files[p] = files[p].replace(b"\t23\n", b"\t24\n", 1)
        p, d = self.mutate(modify)
        with self.assertRaisesRegex(AuditError, "E_MANIFEST_CONTENT"):
            audit_zip(p, SHA, d)

    def test_re_signed_manifest_does_not_authorize_certification(self):
        def modify(files):
            p = "cold-warm/cold-warm-report.json"
            obj = json.loads(files[p])
            obj["certifiable"] = True
            files[p] = encoded(obj)
        p, d = self.mutate(modify, True)
        with self.assertRaisesRegex(AuditError, "E_SUMMARY_CERTIFICATION"):
            audit_zip(p, SHA, d)

    def test_resigned_production_corruption(self):
        def modify(files):
            p = "cold-warm/process-1.production.tsv"
            files[p] = files[p].replace(b"\t5000\t10\t501", b"\t5000\t10\t502", 1)
        p, d = self.mutate(modify, True)
        with self.assertRaisesRegex(AuditError, "E_WORKER_CONTENT_HASHES"):
            audit_zip(p, SHA, d)

    def test_worker_sha_tamper(self):
        def modify(files):
            p = "cold-warm/process-2.json"
            obj = json.loads(files[p]); obj["source"]["git_sha"] = "f" * 40
            files[p] = encoded(obj)
        p, d = self.mutate(modify, True)
        with self.assertRaisesRegex(AuditError, "E_WORKER_PROVENANCE"):
            audit_zip(p, SHA, d)

    def test_resigned_signed_gap_index_swap(self):
        def modify(files):
            p = "cold-warm/process-1.gaps.tsv"
            entries = files[p].decode().splitlines()
            entries[0], entries[1] = entries[1], entries[0]
            files[p] = ("\n".join(entries) + "\n").encode()
            p2 = "cold-warm/process-1.json"
            worker = json.loads(files[p2])
            worker["signed_gate_gap_sha256"] = digest(files[p])
            files[p2] = encoded(worker)
            p3 = "cold-warm/cold-warm-report.json"
            summary = json.loads(files[p3])
            summary["worker_result_json_sha256"][0] = digest(files[p2])
            files[p3] = encoded(summary)
        p, d = self.mutate(modify, True)
        with self.assertRaisesRegex(AuditError, "E_SIGNED_GAP_SEQUENCE"):
            audit_zip(p, SHA, d)


if __name__ == "__main__":
    unittest.main()