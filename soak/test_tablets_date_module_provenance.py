"""Deterministic Git-backed source identity tests; no real TABLETS oracle."""
from __future__ import annotations

import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tablets_date_module_provenance import (
    DateModule, DateSourceError, PINNED_SHA, STATUS,
    verify_date_module_identities,
)


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args],
                                   text=True, stderr=subprocess.DEVNULL).strip()


class ProvenanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.roots = []
        for name, code in (
            ('ind', 'def date_tuple(origin, target):\n    return (5000, 1, 1, 1, 1)\n'),
            ('pin', 'def date_tuple(origin, target):\n    return (5000, 2, 2, 2, 2)\n'),
        ):
            root = self.base / name
            root.mkdir()
            git(root, 'init', '-q')
            git(root, 'config', 'user.email', 'test@example.invalid')
            git(root, 'config', 'user.name', 'Test')
            (root / 'date.py').write_text(code, encoding='utf-8')
            git(root, 'add', 'date.py')
            git(root, 'commit', '-qm', 'fixture')
            self.roots.append(root)
        self.ind = self.describe(self.roots[0])
        self.pin = self.describe(self.roots[1], PINNED_SHA)

    def describe(self, root, override_sha=None):
        return DateModule(root, 'date.py', override_sha or git(root, 'rev-parse', 'HEAD'),
                          hashlib.sha256((root/'date.py').read_bytes()).hexdigest(),
                          'date_tuple')

    def test_verified_two_git_modules_stays_diagnostic(self):
        actual_pinned_commit = git(self.roots[1], 'rev-parse', 'HEAD')
        with patch('tablets_date_module_provenance.PINNED_SHA', actual_pinned_commit):
            report = verify_date_module_identities(
                self.ind, self.describe(self.roots[1]))
        self.assertEqual(report['status'], STATUS)
        self.assertEqual(report['independent']['module_sha256'], self.ind.module_sha256)
        self.assertFalse(report['certifiable'])
        self.assertFalse(report['full_date_verified'])
        self.assertFalse(report['algorithmic_independence_certified'])
        self.assertFalse(report['cache_independence_certified'])

    def test_missing_descriptor_fails_closed(self):
        with self.assertRaisesRegex(DateSourceError, 'E_DATE_SOURCE_DESCRIPTOR'):
            verify_date_module_identities(None, self.pin)

    def test_rejects_pinned_commit_not_at_head(self):
        with self.assertRaisesRegex(DateSourceError, 'E_PINNED_HEAD_MISMATCH'):
            verify_date_module_identities(self.ind, self.pin)

    def test_rejects_wrong_pinned_lock(self):
        with self.assertRaisesRegex(DateSourceError, 'E_PINNED_COMMIT_LOCK'):
            verify_date_module_identities(self.ind, self.describe(self.roots[1]))

    def test_git_blob_check_rejects_dirty_but_matching_digest(self):
        root = self.roots[0]
        (root/'date.py').write_text('def date_tuple(a, b): return (1,1,1,1,1)\n')
        ind = self.describe(root)
        with self.assertRaisesRegex(DateSourceError, 'E_INDEPENDENT_WORKTREE_DIRTY'):
            verify_date_module_identities(ind, self.pin)

    def test_rejects_mismatched_actual_digest(self):
        ind = DateModule(self.ind.repo_root, self.ind.relative_path,
                         self.ind.commit_sha, '0'*64, self.ind.date_function)
        with self.assertRaisesRegex(DateSourceError, 'E_INDEPENDENT_DIGEST_MISMATCH'):
            verify_date_module_identities(ind, self.pin)

    def test_rejects_source_import_even_at_valid_sha(self):
        root = self.roots[0]
        (root/'date.py').write_text('import pastafari_calendar.final_integration\n'
                                    'def date_tuple(a, b): return (1,1,1,1,1)\n')
        git(root, 'add', 'date.py')
        git(root, 'commit', '-qm', 'forbidden source')
        with self.assertRaisesRegex(DateSourceError, 'E_INDEPENDENT_PINNED_IMPORT'):
            verify_date_module_identities(self.describe(root), self.pin)

    def test_rejects_dynamic_source_import(self):
        root = self.roots[0]
        (root/'date.py').write_text('def date_tuple(a, b):\n'
                                    '    return __import__("pastafari_calendar")\n')
        git(root, 'add', 'date.py')
        git(root, 'commit', '-qm', 'dynamic import')
        with self.assertRaisesRegex(DateSourceError, 'E_INDEPENDENT_DYNAMIC_SOURCE'):
            verify_date_module_identities(self.describe(root), self.pin)

    def test_rejects_missing_entrypoint(self):
        ind = DateModule(self.ind.repo_root, self.ind.relative_path,
                         self.ind.commit_sha, self.ind.module_sha256, 'missing_date')
        with self.assertRaisesRegex(DateSourceError, 'E_INDEPENDENT_FUNCTION_MISSING'):
            verify_date_module_identities(ind, self.pin)

    def test_rejects_root_escape(self):
        ind = DateModule(self.ind.repo_root, '../pin/date.py',
                         self.ind.commit_sha, self.ind.module_sha256, 'date_tuple')
        with self.assertRaisesRegex(DateSourceError, 'E_INDEPENDENT_PATH'):
            verify_date_module_identities(ind, self.pin)

    def test_does_not_misrepresent_result_as_full_date_pass(self):
        import inspect
        import tablets_date_module_provenance as mod
        src = inspect.getsource(mod.verify_date_module_identities)
        self.assertIn("'algorithmic_independence_certified': False", src)
        self.assertIn("'cache_independence_certified': False", src)
        self.assertIn("'full_date_verified': False", src)
        self.assertIn("'certifiable': False", src)


    def _commit_independent_dependency(self, helper_code, date_code=None):
        root = self.roots[0]
        (root / 'helper.py').write_text(helper_code, encoding='utf-8')
        (root / 'date.py').write_text(
            date_code or 'import helper\n'
                         'def date_tuple(origin, target):\n'
                         '    return helper.date_tuple(origin, target)\n',
            encoding='utf-8')
        git(root, 'add', 'date.py', 'helper.py')
        git(root, 'commit', '-qm', 'test dependency closure')

    def _verified_closure(self):
        pinned = self.describe(self.roots[1])
        with patch('tablets_date_module_provenance.PINNED_SHA',
                   git(self.roots[1], 'rev-parse', 'HEAD')):
            return verify_date_module_identities(self.describe(self.roots[0]),
                                                 pinned)

    def test_committed_local_dependency_is_git_verified(self):
        self._commit_independent_dependency(
            'def date_tuple(origin, target):\n'
            '    return (5000, 1, 1, 1, 1)\n')
        report = self._verified_closure()
        closure = report['independent']['static_local_dependency_closure']
        self.assertEqual(set(closure), {'date.py', 'helper.py'})
        self.assertEqual(closure['helper.py']['module_sha256'],
                         hashlib.sha256((self.roots[0]/'helper.py').read_bytes()).hexdigest())
        self.assertFalse(report['cache_independence_certified'])
        self.assertFalse(report['certifiable'])

    def test_transitive_reference_import_is_rejected(self):
        self._commit_independent_dependency(
            'import post55_differential\n'
            'def date_tuple(origin, target):\n'
            '    return (5000, 1, 1, 1, 1)\n')
        with self.assertRaisesRegex(DateSourceError,
                                    'E_INDEPENDENT_TRANSITIVE_PINNED_IMPORT'):
            self._verified_closure()

    def test_dirty_transitive_file_is_rejected(self):
        self._commit_independent_dependency(
            'def date_tuple(origin, target):\n'
            '    return (5000, 1, 1, 1, 1)\n')
        (self.roots[0]/'helper.py').write_text(
            'def date_tuple(origin, target): return (5001, 1, 1, 1, 1)\n',
            encoding='utf-8')
        with self.assertRaisesRegex(DateSourceError,
                                    'E_INDEPENDENT_DEPENDENCY_DIRTY'):
            self._verified_closure()

    def test_dynamic_import_in_transitive_file_is_rejected(self):
        self._commit_independent_dependency(
            'def date_tuple(origin, target):\n'
            '    return __import__("pastafari_calendar")\n')
        with self.assertRaisesRegex(DateSourceError,
                                    'E_INDEPENDENT_TRANSITIVE_DYNAMIC_SOURCE'):
            self._verified_closure()

    def test_wildcard_import_is_rejected(self):
        self._commit_independent_dependency(
            'def date_tuple(origin, target): return (5000, 1, 1, 1, 1)\n',
            'from helper import *\n'
            'def date_tuple(origin, target): return (5000, 1, 1, 1, 1)\n')
        with self.assertRaisesRegex(DateSourceError,
                                    'E_INDEPENDENT_WILDCARD_IMPORT'):
            self._verified_closure()



if __name__ == '__main__':
    unittest.main()
