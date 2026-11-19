"""v115 real QA workflow inventory and unauthorized dispatch mutation tests."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import audit_workflow_native_dispatch_halt_v115 as v


class FirstMismatchNativeWorkflowInterlock(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest,cls.lock,cls.workflows=v.load_tree(Path(__file__).resolve().parents[2])

    def audit(self,m=None,lock=None,files=None):
        return v.check_inventory(
            self.manifest if m is None else m,
            self.lock if lock is None else lock,
            self.workflows if files is None else files)

    def test_all_55_workflows_classified_and_24_native_jobs_stopped(self):
        result=self.audit()
        self.assertEqual(result["classified_workflows"],55)
        self.assertEqual(result["blocked_native_workflows"],24)
        self.assertEqual(result["preserved_readonly_or_control_workflows"],31)

    def test_every_native_job_has_literal_false_guard(self):
        for path in self.manifest["native_dispatch_jobs_halted"]:
            self.assertIn("    if: "+v.HALT,self.workflows[path])

    def test_native_job_true_condition_rejected(self):
        files=self.workflows.copy()
        path=self.manifest["native_dispatch_jobs_halted"][0]
        files[path]=files[path].replace("    if: "+v.HALT,"    if: ${{ true }}",1)
        with self.assertRaisesRegex(ValueError,"unguarded native job"):
            self.audit(files=files)

    def test_new_second_native_job_without_halt_rejected(self):
        files=self.workflows.copy()
        path=self.manifest["native_dispatch_jobs_halted"][0]
        files[path]+="\n  unauthorized-native:\n    runs-on: ubuntu-24.04\n    steps:\n      - run: echo unsafe\n"
        with self.assertRaisesRegex(ValueError,"unguarded native job"):
            self.audit(files=files)

    def test_new_unknown_workflow_rejected(self):
        files=self.workflows.copy()
        files[".github/workflows/unclassified-original.yml"]="name: X\njobs:\n  run:\n    runs-on: ubuntu-24.04\n"
        with self.assertRaisesRegex(ValueError,"unclassified or missing"):
            self.audit(files=files)

    def test_removed_known_workflow_rejected(self):
        files=self.workflows.copy()
        files.pop(self.manifest["classified_readonly_or_control_workflows"][0])
        with self.assertRaisesRegex(ValueError,"unclassified or missing"):
            self.audit(files=files)

    def test_duplicate_inventory_items_rejected(self):
        m=copy.deepcopy(self.manifest)
        m["native_dispatch_jobs_halted"].append(m["native_dispatch_jobs_halted"][0])
        with self.assertRaisesRegex(ValueError,"duplicate workflow paths"):
            self.audit(m=m)

    def test_revoked_scientific_incident_lock_rejected(self):
        lock=copy.deepcopy(self.lock)
        lock["decision"]="RESUME_ALL_NATIVE"
        with self.assertRaisesRegex(ValueError,"confirmed v108"):
            self.audit(lock=lock)

    def test_false_year_credit_rejected(self):
        m=copy.deepcopy(self.manifest)
        m["ten_thousand_soak_years_passed"]=1
        with self.assertRaisesRegex(ValueError,"incident workflow inventory"):
            self.audit(m=m)

    def test_readonly_workflow_unexpected_disable_rejected(self):
        files=self.workflows.copy()
        path=self.manifest["classified_readonly_or_control_workflows"][0]
        original=files[path]
        ix=original.index("jobs:\n")
        end=original.index("\n",original.index("\n",ix+5)+1)
        files[path]=original[:end+1]+"    if: "+v.HALT+"\n"+original[end+1:]
        with self.assertRaisesRegex(ValueError,"readonly job unexpectedly stopped"):
            self.audit(files=files)


    def test_readonly_workflow_content_changed_without_new_guard_rejected(self):
        files=self.workflows.copy()
        path=self.manifest["classified_readonly_or_control_workflows"][0]
        files[path]+="\n# unexpected unchecked change to previously approved audit job\n"
        with self.assertRaisesRegex(ValueError,"readonly workflow Git blob SHA drift"):
            self.audit(files=files)

if __name__=="__main__":
    unittest.main()
