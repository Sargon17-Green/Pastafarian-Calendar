"""v138: synthetic negative controls for historic Seer source/toolchain receipts."""
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_seer_historical_binary_recovery_v138 as target

P=Path(__file__).resolve().parents[1]/"control"/"seer_historical_binary_recovery_v138.json"

def fake_script(out):
    return (
      'CXX=g++\n'
      'FLAGS="-O3 -DNDEBUG -std=c++20 -fopenmp -pthread -march=x86-64 -mavx2 -lgmp"\n'
      '"g++" -o "$ROOT/'+out+'"\n').encode()

def fake_source(path):
    if path.endswith("seer-next-experiment.yml"):
        return (
          "runs-on: ubuntu-24.04\nprofile: standard-minimal\n"
          "package-manager-cache: false\nnode-version: '24'\n"
          +("SEER_RNS_BACKEND: avx2\nSEER_MARCH: x86-64\n")*3
          +"bash prototype/scripts/build_engine_service.sh\n"
          +"bash research/seer-next/scripts/build_candidate.sh\n"
          +"bash research/seer-next/scripts/build_hybrid.sh\n"
          +"name: seer-next-native-ab-linux-avx2\npath: |\n"
          +"".join("  research/seer-next/results/working/f%02d.json\n"%i
                   for i in range(34))
          +"if-no-files-found: error\n").encode()
    if path.endswith("native-deps/action.yml"):
        return b"standard-minimal) packages=(g++ libgmp-dev libboost-dev); minimal=1\n"
    if path.endswith("build_engine_service.sh"):
        return fake_script("build/seer_engine_service")
    if path.endswith("build_candidate.sh"):
        return fake_script("research/seer-next/build/seer_next_engine_service")
    if path.endswith("build_hybrid.sh"):
        return fake_script("research/seer-next/build/seer_next_hybrid_engine_service")
    if path.endswith("compare_candidate.mjs"):
        return ("startingCommit:'"+target.SHA_STARTING+"'\n"
          +"baselineBinarySHA256:await sha256(src)\n"
          +"candidateBinarySHA256:await sha256(candidate)\n"
          +"createReadStream(file)\ncreateHash('sha256')\n").encode()
    return b"node-version: 24\n"

class FakeGH:
    def __init__(self):
        self.run={"id":target.RUN_ID,"head_sha":target.CI_SHA,
                  "status":"completed","conclusion":"success"}
        self.jobs={"total_count":1,"jobs":[{
          "id":target.JOB_ID,"status":"completed","conclusion":"success",
          "steps":[{"name":s,"conclusion":"success"} for s in target.STEPS]}]}
        self.art={"total_count":1,"artifacts":[{
          "id":13595506317,"name":"seer-next-native-ab-linux-avx2",
          "digest":"sha256:"+target.SHA_ARTIFACT,"expired":False}]}
    def get(self,path):
        prefix="/repos/"+target.REPO+"/actions/runs/"+str(target.RUN_ID)
        if path==prefix:return self.run
        if path==prefix+"/jobs?per_page=100":return self.jobs
        if path==prefix+"/artifacts?per_page=100":return self.art
        raise AssertionError("unexpected URL "+path)

class RecoveryCases(unittest.TestCase):
    def setUp(self):
        self.m=json.loads(P.read_text(encoding="utf8"))
        self.gh=FakeGH()
        self.src={p:fake_source(p) for p in target.SOURCE}
        def mocked(_gh,repo,sha,path):
            self.assertEqual(repo,target.REPO)
            self.assertEqual(sha,target.CI_SHA)
            return self.src[path],{"git_blob_sha1":target.SOURCE[path]}
        self.p=patch.object(target,"checked_blob",side_effect=mocked)
        self.p.start()
        self.addCleanup(self.p.stop)
    def test_source_contract_7_blobs_and_34_json(self):
        r=target.verify_sources(self.m,self.gh)
        self.assertEqual(r["frozen_source_blobs_verified"],7)
        self.assertEqual(r["exact_original_artifact_json_paths"],34)
    def test_historical_ci_4_required_steps_success(self):
        self.assertEqual(len(target.verify_ci(self.m,self.gh)["required_successful_build_steps"]),4)
    def test_no_original_10000_year_certification(self):
        a=target.audit(self.m,self.gh)
        self.assertEqual(a["scientific_original_10000_years_certified"],0)
        self.assertFalse(a["reproducible_bit_identical_binary_proven"])
        self.assertFalse(a["GHA_cache_absence_proven"])
        self.assertFalse(a["soak_dispatch_authorized"])
    def test_queued_run_not_pass(self):
        self.gh.run["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            target.verify_ci(self.m,self.gh)
    def test_wrong_commit_run_not_pass(self):
        self.gh.run["head_sha"]="f"*40
        with self.assertRaisesRegex(ValueError,"CI source SHA"):
            target.verify_ci(self.m,self.gh)
    def test_failed_candidate_build_not_pass(self):
        self.gh.jobs["jobs"][0]["steps"][1]["conclusion"]="failure"
        with self.assertRaisesRegex(ValueError,"not all successful"):
            target.verify_ci(self.m,self.gh)
    def test_historic_archive_digest_cannot_change(self):
        self.gh.art["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"metadata mismatch"):
            target.verify_ci(self.m,self.gh)
    def test_historic_archive_expired_not_pass(self):
        self.gh.art["artifacts"][0]["expired"]=True
        with self.assertRaisesRegex(ValueError,"no longer accessible"):
            target.verify_ci(self.m,self.gh)
    def test_starting_commit_is_not_real_git_head(self):
        self.m["reporter_static_field"]["hardcoded_value"]=target.CI_SHA
        with self.assertRaisesRegex(ValueError,"incorrectly promoted"):
            target.validate(self.m)
    def test_reporter_requires_streamed_sha_from_original_binary_file(self):
        p="research/seer-next/scripts/compare_candidate.mjs"
        self.src[p]=b"startingCommit:'"+target.SHA_STARTING.encode()+b"'\n"
        with self.assertRaisesRegex(ValueError,"historic hash reporter"):
            target.verify_sources(self.m,self.gh)
    def test_artifact_adds_executable_path_rejected(self):
        p=".github/workflows/seer-next-experiment.yml"
        self.src[p]=self.src[p].replace(
          b"if-no-files-found: error",
          b"  research/seer-next/build/seer_next_engine_service\nif-no-files-found: error")
        with self.assertRaisesRegex(ValueError,"34 JSON-only"):
            target.verify_sources(self.m,self.gh)
    def test_wrong_source_blob_pin_rejected(self):
        self.m["source_files"][4]["git_blob_sha1"]="f"*40
        with self.assertRaisesRegex(ValueError,"SHA inventory changed"):
            target.validate(self.m)
    def test_O0_instead_of_O3_rejected(self):
        p="research/seer-next/scripts/build_candidate.sh"
        self.src[p]=self.src[p].replace(b"-O3",b"-O0")
        with self.assertRaisesRegex(ValueError,"recipe flags"):
            target.verify_sources(self.m,self.gh)
    def test_cache_absence_cannot_be_invented(self):
        self.m["github_actions_cache_presence_or_absence_asserted"]=True
        with self.assertRaisesRegex(ValueError,"binary/Soak"):
            target.validate(self.m)
    def test_log_tokens_if_available_can_be_verified(self):
        a=target.verify_historical_log_text("\n".join(target.LOG_TOKENS))
        self.assertEqual(a["state"],"AVAILABLE_VERIFIED_FROM_HISTORIC_JOB_LOG")
        self.assertFalse(a["binary_bytes_available_from_log"])
    def test_missing_apt_package_version_rejected(self):
        log="\n".join(x for x in target.LOG_TOKENS if "g++ is already" not in x)
        with self.assertRaisesRegex(ValueError,"missing historic toolchain"):
            target.verify_historical_log_text(log)
    def test_no_original_binary_sha_invented_for_hybrid(self):
        self.m["three_build_outputs"][2]["reported_sha256"]="3"*64
        with self.assertRaisesRegex(ValueError,"hash claims changed"):
            target.validate(self.m)
    def test_original_binary_bytes_availability_cannot_be_forged(self):
        self.m["three_build_outputs"][0]["original_executable_bytes_available"]=True
        with self.assertRaisesRegex(ValueError,"hash claims changed"):
            target.validate(self.m)

if __name__=="__main__":
    unittest.main()
