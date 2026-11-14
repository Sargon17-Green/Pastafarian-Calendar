from __future__ import annotations
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

RUNNER = pathlib.Path(__file__).resolve().parents[1]/'runner'
sys.path.insert(0,str(RUNNER))
from recovery_store import CONTRACT, CrashStore, Halted, PlanMismatch, sha256


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)/'workspace'
        self.plan = {
            'contract':CONTRACT, 'calculation_day':'-15055671','chunk_days':2,
            'years':[{'year':'5000','first_target_day':'-15055671',
                      'last_target_day':'-15055668','boundary_evidence_sha256':'a'*64},
                     {'year':'5001','first_target_day':'-15055667',
                      'last_target_day':'-15055664','boundary_evidence_sha256':'b'*64}],
            'engines':[{'id':'engine-a','algorithm_id':'original-a','source_sha256':'1'*64,
                        'binary_sha256':'2'*64,'name_map_sha256':'3'*64},
                       {'id':'engine-b','algorithm_id':'independent-b','source_sha256':'4'*64,
                        'binary_sha256':'5'*64,'name_map_sha256':'6'*64}]
        }

    def chunk(self,year='5000',n=0,*,engine='engine-a',deviation_at=None):
        first={'5000':-15055671,'5001':-15055667}[year]+n*2
        rows=[]
        for t in (first,first+1):
            offset=t+15055671
            rows.append({'calculation_day':'-15055671','target_day':str(t),'year':year,
                         'cutlet_index':10,'day_in_cutlet':503+offset,
                         'month_index':20+(1 if t==deviation_at else 0),
                         'day_in_month':56+offset,
                         'cutlet_name_raw':'A' if engine=='engine-a' else 'א',
                         'month_name_raw':'M' if engine=='engine-a' else 'חודש',
                         'source_raw_sha256':hashlib.sha256((engine+str(t)).encode()).hexdigest()})
        return (''.join(json.dumps(r,ensure_ascii=False,sort_keys=True)+'\n' for r in rows)).encode()

    def _foundation(self,s):
        for n in range(2):s.commit_chunk('engine-a','5000',n,self.chunk(n=n))

    def test_replay_does_not_double_count(self):
        with CrashStore(self.root,self.plan) as s:
            self._foundation(s)
            self.assertEqual(s.progress()['verified_comparisons_completed'],0)
            s.commit_chunk('engine-b','5000',0,self.chunk(n=0,engine='engine-b'))
            self.assertEqual(s.progress()['verified_comparisons_completed'],0)
            s.commit_chunk('engine-b','5000',1,self.chunk(n=1,engine='engine-b'))
            self.assertEqual(s.progress()['verified_comparisons_completed'],1)
            self.assertEqual(s.progress()['verified_day_pair_comparisons'],4)
            self.assertEqual(s.progress()['contiguous_verified_years'],1)
        with CrashStore(self.root,self.plan) as s:
            self.assertEqual(s.verify_and_recover()['verified_existing_chunks'],4)
            self.assertEqual(s.progress()['verified_comparisons_completed'],1)
            self.assertEqual(s.commit_chunk('engine-b','5000',1,self.chunk(n=1,engine='engine-b')),'ALREADY_COMMITTED')
            self.assertEqual(s.progress()['verified_comparisons_completed'],1)
            self.assertEqual([(c.engine_id,c.year,c.ordinal) for c in s.pending_jobs()],
                             [('engine-a','5001',0),('engine-a','5001',1)])

    def test_mismatch_blocks_new_dispatch_and_is_durable(self):
        with CrashStore(self.root,self.plan) as s:
            self._foundation(s)
            s.commit_chunk('engine-b','5000',0,self.chunk(engine='engine-b',deviation_at=-15055670))
            self.assertEqual(s.incident()['kind'],'FIRST_DIFFERENCE')
            self.assertEqual(s.incident()['evidence']['target_day'],'-15055670')
            self.assertFalse(s.progress()['all_verified'])
            with self.assertRaises(Halted):s.pending_jobs()
        with CrashStore(self.root,self.plan) as s:
            self.assertEqual(s.incident()['evidence']['target_day'],'-15055670')
            with self.assertRaises(Halted):s.commit_chunk('engine-a','5001',0,self.chunk(year='5001'))

    def test_reject_duplicate_json_key(self):
        data=self.chunk()
        invalid=data.replace(b'"month_index": 20,',b'"month_index": 20, "month_index": 20,')
        with CrashStore(self.root,self.plan) as s:
            with self.assertRaisesRegex(ValueError,'duplicate JSON key'):s.commit_chunk('engine-a','5000',0,invalid)
            self.assertEqual(s.progress()['committed_chunks'],0)

    def test_reject_partial_chunk(self):
        with CrashStore(self.root,self.plan) as s:
            with self.assertRaisesRegex(ValueError,'incomplete or extra'):s.commit_chunk('engine-a','5000',0,self.chunk().splitlines(keepends=True)[0])

    def test_plan_mutation_rejected(self):
        with CrashStore(self.root,self.plan):pass
        altered=json.loads(json.dumps(self.plan))
        altered['chunk_days']=3
        with self.assertRaises(PlanMismatch):
            with CrashStore(self.root,altered):pass

    def test_different_algorithm_required(self):
        bad=json.loads(json.dumps(self.plan))
        bad['engines'][1]['algorithm_id']='original-a'
        with self.assertRaisesRegex(ValueError,'duplicate/blank underlying algorithm'):
            with CrashStore(self.root,bad):pass

    def test_corrupt_committed_file_fails_closed(self):
        with CrashStore(self.root,self.plan) as s:
            s.commit_chunk('engine-a','5000',0,self.chunk())
            p=s._chunk_path(s._chunk('engine-a','5000',0))
        p.write_bytes(p.read_bytes()+b'garbage')
        with CrashStore(self.root,self.plan) as s:
            with self.assertRaisesRegex(ValueError,'integrity check'):s.verify_and_recover()
            self.assertEqual(s.progress()['verified_comparisons_completed'],0)

    def test_invalid_candidate_order_rejected(self):
        with CrashStore(self.root,self.plan) as s:
            with self.assertRaisesRegex(ValueError,'complete previous engine year'):
                s.commit_chunk('engine-b','5000',0,self.chunk(engine='engine-b'))

    def crash(self,stage):
        script='''import json,sys,pathlib
sys.path.insert(0,sys.argv[1])
from recovery_store import CrashStore
plan=json.loads(pathlib.Path(sys.argv[2]).read_text())
content=pathlib.Path(sys.argv[3]).read_bytes()
with CrashStore(pathlib.Path(sys.argv[4]),plan) as s:
    s.commit_chunk('engine-a','5000',0,content,inject_crash_at=sys.argv[5])
'''
        file = self.root.parent/'crash_worker.py';file.write_text(script)
        planp=self.root.parent/'plan-input.json';planp.write_text(json.dumps(self.plan))
        payload=self.root.parent/'payload-input.bin';payload.write_bytes(self.chunk())
        p=subprocess.run([sys.executable,str(file),str(RUNNER),str(planp),str(payload),str(self.root),stage],
                         stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
        return p.returncode

    def test_crash_after_file_fsync_recover_part_without_recompute(self):
        self.assertEqual(self.crash('after_payload_fsync'),73)
        with CrashStore(self.root,self.plan) as s:
            outcome=s.verify_and_recover()
            self.assertEqual(outcome['recovered_staged_files'],1)
            self.assertEqual(outcome['recovered_chunks'],1)
            self.assertEqual(s.progress()['committed_chunks'],1)
            self.assertEqual(outcome['progress']['verified_comparisons_completed'],0)

    def test_crash_after_rename_recover_blob_without_recompute(self):
        self.assertEqual(self.crash('after_payload_publish'),74)
        with CrashStore(self.root,self.plan) as s:
            outcome=s.verify_and_recover()
            self.assertEqual(outcome['recovered_staged_files'],0)
            self.assertEqual(outcome['recovered_chunks'],1)
            self.assertEqual(s.progress()['committed_chunks'],1)

    def test_crash_after_db_commit_is_already_recorded(self):
        self.assertEqual(self.crash('after_db_commit'),75)
        with CrashStore(self.root,self.plan) as s:
            outcome=s.verify_and_recover()
            self.assertEqual(outcome['verified_existing_chunks'],1)
            self.assertEqual(outcome['recovered_chunks'],0)
            self.assertEqual(s.progress()['committed_chunks'],1)

    def test_single_supervisor_lock(self):
        with CrashStore(self.root,self.plan):
            with self.assertRaisesRegex(RuntimeError,'another soak supervisor'):
                with CrashStore(self.root,self.plan):pass


if __name__=='__main__':unittest.main()
