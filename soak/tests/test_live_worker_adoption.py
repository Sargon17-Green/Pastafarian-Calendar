from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile

RUNNER = Path(__file__).resolve().parents[1] / 'runner'
sys.path.insert(0, str(RUNNER))
import live_worker_adoption as a


class TestAdoptionProtocol(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.work = self.root / 'job'
        self.work.mkdir()
        self.nonce = 'deterministic-synthetic-fixture'
        self.script_sha = a.sha(b'pinned synthetic script')
        a.durable_file(self.work/'worker_source.py', b'pinned synthetic script')
        a.durable_file(self.work/'manifest.json', a.encoded(a.manifest(self.work, self.script_sha, self.nonce)))
        creation, live = a.process_identity(os.getpid())
        self.assertTrue(live)
        self.identity = {'pid': os.getpid(), 'creation_id': creation,
                         'nonce_sha256': a.sha(self.nonce.encode()), 'script_sha256': self.script_sha,
                         'guard': {'native_cpu_cap_certified': False}}
        a.durable_file(self.work/'identity.json', a.encoded(self.identity))

    def authorize(self):
        a.durable_file(self.work/'GO.json', a.encoded({k: self.identity[k]
                          for k in ('pid', 'creation_id', 'nonce_sha256')}))

    def finish(self):
        lines = [a.encoded({'kind':'MOCK_NO_CONVERTER', 'ordinal':i,
                            'plan_sha256':a.sha((self.work/'manifest.json').read_bytes())})
                 for i in range(a.STEP_COUNT)]
        spool = b''.join(lines)
        a.durable_file(self.work/'output.jsonl', spool)
        a.durable_file(self.work/'done.json', a.encoded({'pid':self.identity['pid'],
            'creation_id':self.identity['creation_id'], 'nonce_sha256':self.identity['nonce_sha256'],
            'count':a.STEP_COUNT, 'output_sha256':a.sha(spool)}))

    def test_unapproved_child_does_not_autorestart(self):
        with self.assertRaisesRegex(RuntimeError, 'not authorized'):
            a.supervisor_resume(self.work)

    def test_valid_finished_replay_no_duplicate_dispatch(self):
        self.authorize();self.finish()
        one = a.supervisor_resume(self.work)
        two = a.supervisor_resume(self.work)
        self.assertEqual(one['output']['verified_rows'], a.STEP_COUNT)
        self.assertEqual(one['output']['output_sha256'], two['output']['output_sha256'])
        self.assertEqual(one['new_processes_launched'], 0)

    def test_script_digest_mismatch_fails_closed(self):
        self.authorize();self.finish()
        obj = a.load_json(self.work/'identity.json'); obj['script_sha256'] = '0'*64
        (self.work/'identity.json').write_bytes(a.encoded(obj))
        with self.assertRaisesRegex(RuntimeError, 'identity mismatches immutable'):
            a.supervisor_resume(self.work)

    def test_creation_id_mismatch_fails_closed(self):
        self.authorize()
        obj = a.load_json(self.work/'identity.json'); obj['creation_id'] = '-1'
        (self.work/'identity.json').write_bytes(a.encoded(obj))
        with self.assertRaisesRegex(RuntimeError, 'GO/identity mismatch'):
            a.supervisor_resume(self.work)

    def test_frozen_source_changed_rejected(self):
        self.authorize(); self.finish()
        (self.work/'worker_source.py').write_bytes(b'altered worker source')
        with self.assertRaisesRegex(RuntimeError, 'frozen worker source digest mismatch'):
            a.supervisor_resume(self.work)

    def test_corrupted_spool_rejected(self):
        self.authorize();self.finish()
        with (self.work/'output.jsonl').open('ab') as f: f.write(b'garbage')
        with self.assertRaisesRegex(RuntimeError, 'hash/count'):
            a.supervisor_resume(self.work)

    def test_missing_done_is_not_certified(self):
        self.authorize()
        with self.assertRaisesRegex(RuntimeError, 'still active'):
            a.supervisor_resume(self.work, wait_seconds=0.01)

    def test_existing_manifest_refuses_second_worker(self):
        with self.assertRaisesRegex(RuntimeError, 'refuse duplicate child launch'):
            a.supervisor_start(self.work, Path(a.__file__))

    def test_file_publish_is_immutable(self):
        with self.assertRaisesRegex(RuntimeError, 'immutable file already exists'):
            a.durable_file(self.work/'manifest.json', b'altered')

    @unittest.skipIf(os.name == 'nt', 'local subprocess test runs only on Linux; Windows fixture is gated by RAM/CPU preflight')
    def test_real_supervisor_os_exit_child_survives(self):
        output = subprocess.run([sys.executable, str(Path(a.__file__)), 'fixture', '--root', str(self.root)],
                                text=True, capture_output=True, timeout=24)
        self.assertEqual(output.returncode, 0, output.stdout+output.stderr)
        result = json.loads(output.stdout.strip().split('PASTAFARI_SOAK_LIVE_ADOPTION_JSON=',1)[1])
        self.assertEqual(result['status'], 'LIVE_CHILD_ADOPTION_PASS')
        self.assertEqual(result['supervisor_crash_exit'], 86)
        self.assertEqual(result['children_started'], 1)
        self.assertEqual(result['new_processes_launched'], 0)
        self.assertEqual(result['output']['verified_rows'], 10)
        files = list((self.root/'handoffs').glob('PASTAFARI_SOAK_ADOPTION_v013_*.zip'))
        self.assertEqual(len(files),1)
        with zipfile.ZipFile(files[0]) as z:
            self.assertIsNone(z.testzip())
            self.assertIn('worker/done.json',z.namelist())


if __name__ == '__main__':
    unittest.main()
