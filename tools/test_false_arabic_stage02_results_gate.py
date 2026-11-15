"""Synthetic adversarial checks; no FALSE executable or Windows environment required."""
import hashlib
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from false_arabic_stage02_results_gate import PROJECT, SHA, MARKERS, classify


class Stage02GateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'evidence.zip'
        self.source = b'lock exact source bytes\n'
        self.digest = hashlib.sha256(self.source).hexdigest()
        self.evidence = {
            'project_id': PROJECT,
            'target_sha': SHA,
            'observed_sha': SHA,
            'runner_exit_code': 0,
            'native_exit_code': 0,
            'git_fetch_exit_code': 0,
            'preflight_exit_code': 0,
            'combined_source_sha256': self.digest,
            'runtime_sha256': 'a' * 64,
        }

    def make(self, evidence=None, source=None, extras=None, stdout=None):
        info = self.evidence if evidence is None else evidence
        body = self.source if source is None else source
        with zipfile.ZipFile(self.path, 'w') as z:
            z.writestr('RESULTS/evidence.json', json.dumps(info))
            z.writestr('RESULTS/native_stdout.txt', '\n'.join(MARKERS) if stdout is None else stdout)
            z.writestr('RESULTS/combined_sha256.txt', self.digest + '  stage02_discovery01_combined.false\n')
            z.writestr('RESULTS/stage02_discovery01_combined.false', body)
            for key, val in extras or []:
                z.writestr(key, val)

    def test_valid_discovery_shape_only(self):
        self.make()
        result = classify(str(self.path))
        self.assertTrue(result['native_pass'])
        self.assertEqual(result['scope'], 'DISCOVERY01_ONLY_NOT_STAGE2_ACCEPTANCE')

    def test_v11_alias_copy_exit_zero_never_claimed_as_native(self):
        self.make({**self.evidence, 'execution_mode': 'DOCUMENTED_ASCII_PICK_ALIAS_COPY',
                   'exact_source_bytes_executed': False})
        result = classify(str(self.path))
        self.assertEqual(result['classification'], 'ASCII_O_ALIAS_DIAGNOSTIC_ONLY')
        self.assertFalse(result['native_pass'])

    def test_unknown_execution_mode_rejected(self):
        self.make({**self.evidence, 'execution_mode': 'UNAUDITED_PATCH'})
        with self.assertRaisesRegex(ValueError, 'unrecognized source execution mode'):
            classify(str(self.path))

    def test_explicit_source_bytes_denial_rejected(self):
        self.make({**self.evidence, 'exact_source_bytes_executed': False})
        with self.assertRaisesRegex(ValueError, 'source-byte execution explicitly denied'):
            classify(str(self.path))

    def test_failure_marker_conflicts_with_success_markers(self):
        self.make(stdout='\\n'.join(MARKERS) + '\\nفشل استقصاء المرحلة الثانية')
        with self.assertRaisesRegex(ValueError, 'explicit Stage2 failure marker'):
            classify(str(self.path))

    def test_reject_unverified_fetch(self):
        self.make({**self.evidence, 'git_fetch_exit_code': None})
        with self.assertRaisesRegex(ValueError, 'fetch success'):
            classify(str(self.path))

    def test_reject_unverified_preflight(self):
        self.make({**self.evidence, 'preflight_exit_code': None})
        with self.assertRaisesRegex(ValueError, 'preflight success'):
            classify(str(self.path))

    def test_reject_tampered_combined_source(self):
        self.make(source=b'changed\n')
        with self.assertRaisesRegex(ValueError, 'source bytes differ'):
            classify(str(self.path))

    def test_reject_ambiguous_evidence(self):
        self.make(extras=[('OTHER/evidence.json', json.dumps(self.evidence))])
        with self.assertRaisesRegex(ValueError, 'ambiguous duplicate'):
            classify(str(self.path))

    def test_reject_duplicate_native_stdout(self):
        self.make(extras=[('OTHER/native_stdout.txt', '\n'.join(MARKERS))])
        with self.assertRaisesRegex(ValueError, 'ambiguous duplicate'):
            classify(str(self.path))

    def test_reject_wrong_project(self):
        self.make({**self.evidence, 'project_id': 'PC-BRANCH-OTHER'})
        with self.assertRaisesRegex(ValueError, 'PROJECT_ID'):
            classify(str(self.path))

    def test_reject_wrong_target_sha(self):
        self.make({**self.evidence, 'target_sha': 'f' * 40})
        with self.assertRaisesRegex(ValueError, 'target SHA'):
            classify(str(self.path))

    def test_reject_missing_runtime_hash(self):
        self.make({**self.evidence, 'runtime_sha256': ''})
        with self.assertRaisesRegex(ValueError, 'runtime SHA256'):
            classify(str(self.path))

    def test_native_nonzero_never_pass(self):
        self.make({**self.evidence, 'native_exit_code': 2})
        self.assertFalse(classify(str(self.path))['native_pass'])

    def test_environment_missing_never_pass(self):
        self.make({**self.evidence, 'runner_exit_code': 3, 'native_exit_code': None})
        self.assertFalse(classify(str(self.path))['native_pass'])

    def test_reject_missing_combined_source(self):
        self.make()
        with zipfile.ZipFile(self.path, 'r') as z:
            members = [(k, z.read(k)) for k in z.namelist() if not k.endswith('stage02_discovery01_combined.false')]
        with zipfile.ZipFile(self.path, 'w') as z:
            for name, content in members:
                z.writestr(name, content)
        with self.assertRaisesRegex(ValueError, 'missing combined source bytes'):
            classify(str(self.path))


if __name__ == '__main__':
    unittest.main()
