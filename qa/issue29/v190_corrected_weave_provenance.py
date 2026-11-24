#!/usr/bin/env python3
"""Static byte-accurate witness for the Issue29 GMP production patch. Never calls F."""
import hashlib,json,os,re,subprocess
from pathlib import Path

BASE="1160096aa847c54cbef27c232771ce1549d7ba8f"
ORIGINAL="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
BRANCH="qa/issue29-corrected-weave-provenance-v190"
MESSAGE="qa(issue29-v190): source-locked GMP production-call provenance guard; zero F"
QA_PATHS={
 ".github/workflows/issue29-v190-corrected-weave-provenance.yml",
 "qa/issue29/v190_corrected_weave_provenance.py",
 "qa/issue29/V190_PRODUCTION_WEAVE_PROVENANCE.md"}
PINS={
 (ORIGINAL,"src/normative_oracle.adb"):"923733d4f8face03586aee304640bf7540c28b4c",
 (BASE,"src/normative_oracle.adb"):"0be8f8ab4ddef26d34963d5567707a511ebda50b",
 (ORIGINAL,"src/month_weaving.adb"):"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
 (BASE,"src/month_weaving.adb"):"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
 (BASE,"src/canonical_full_weave_gmp_v164.ads"):"0b68edf7eddbc33869358bcfcc21e32465fc591e",
 (BASE,"src/canonical_full_weave_gmp_v164.adb"):"845bd8905943a54e63d6aba0334404a5051fe666",
 (BASE,"src/canonical_wide_rank_gmp_v164.ads"):"14b94e81534e98cfdb07be3824076bd7082385ea",
 (BASE,"src/canonical_wide_rank_gmp_v164.adb"):"52b8814c2ab1924cdebafe893a65d97cd3ccfa61",
 (BASE,"pastafari_calendar.gpr"):"eb8ac4b64f8f1fddb22087a51c5f4ccd508684d7"}
IMPORTS=(
 "with Canonical_Full_Weave_GMP_V164;",
 "with Canonical_Wide_Rank_GMP_V164;",
 "with GNATCOLL.GMP.Integers;")
CALLS=(
 "Canonical_Full_Weave_GMP_V164.Build",
 "Canonical_Full_Weave_GMP_V164.Count",
 "Canonical_Wide_Rank_GMP_V164.Choose_Rank",
 "Canonical_Full_Weave_GMP_V164.Unrank")

def require(ok,message):
 if not ok: raise AssertionError(message)
def git(*args):
 return subprocess.check_output(["git",*args],stderr=subprocess.DEVNULL).decode().strip()
def src(ref,path):
 return subprocess.check_output(["git","show",ref+":"+path])
def sha(b):return hashlib.sha256(b).hexdigest()

def ci_guard():
 if not os.environ.get("GITHUB_ACTIONS"):return
 require(os.environ.get("GITHUB_EVENT_NAME")=="push","not push")
 require(os.environ.get("GITHUB_RUN_ATTEMPT")=="1","not first attempt")
 require(os.environ.get("GITHUB_REF")=="refs/heads/"+BRANCH,"not branch")
 require(git("rev-parse","HEAD")==os.environ.get("GITHUB_SHA"),"HEAD drift")
 event=json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_bytes())
 require(event.get("head_commit",{}).get("message")==MESSAGE,"activation drift")
 require(subprocess.run(["git","merge-base","--is-ancestor",BASE,"HEAD"]).returncode==0,"source base")
 changed=git("diff","--name-only",BASE+"...HEAD").splitlines()
 require(len(changed)==3 and set(changed)==QA_PATHS,"non-QA paths modified")
 lock=Path(".github/workflows/canonical-names-lock.yml").read_text()
 require(lock.count("    if: "+"$"+"{{ false }}")==42,"original native dispatch not halted")
 require(lock.count("  verify:\n")==1,"canonical verify count")

def sections(text,corrected):
 marker=("   --  Issue29 PATCH (minimal spaghetti)" if corrected
         else "   -- Canonical two-rail family")
 end="   end Choose_Month_Weaving;"
 require(text.count(marker)==1 and text.count(end)==1,"ambiguous source function")
 start=text.index(marker); stop=text.index(end,start)+len(end)
 return text[:start],text[start:stop],text[stop:]

def verify(old,new):
 before0,body0,after0=sections(old,False)
 before1,body1,after1=sections(new,True)
 for statement in IMPORTS:
  require(old.count(statement)==0,"original unexpectedly imports GMP")
  require(new.count(statement)==1,"GMP import missing/duplicate")
  before1=before1.replace(statement+"\n","",1)
 require(before0==before1,"non-weave prefix differs")
 require(after0==after1,"non-weave suffix differs")
 require("Month_Weaving.From_Choices" in body0,"historical path absent")
 require("Month_Weaving.From_Choices" not in body1,"old tickets called from corrected path")
 require("Tickets :" not in body1,"ticket loop in corrected path")
 require(re.search(r"Ask_Bowl\s*\(\s*Structure_R,\s*4,\s*Seal_Month_Weaving\s*\)",body1) is not None,
         "wrong stream seal")
 positions=[]
 for c in CALLS:
  require(body1.count(c)==1,"changed GMP call: "+c)
  positions.append(body1.index(c))
 require(positions==sorted(positions),"wrong GMP call order")
 require("return Natural_Array (Result);" in body1,"GMP result not returned")
 require(after1.count("Choose_Month_Weaving (Structure_R, Month_Lengths)")==1,
         "integrated call missing")
 require("   end Calendar_Date;" in after1,"calendar path lost")
 return {"byte_identical_outside_weave_and_three_imports":True,
         "untouched_prefix_sha256":sha(before0.encode()),
         "untouched_suffix_sha256":sha(after0.encode()),
         "historical_weave_sha256":sha(body0.encode()),
         "corrected_weave_sha256":sha(body1.encode()),
         "gmp_calls_in_order":list(CALLS),
         "legacy_ticket_path_in_production_weave":False,
         "calendar_date_integration_calls":1}

def mutations(old,new):
 tests=[
  ("suffix",new.replace("   end Calendar_Date;","   end Calendar_Date; -- altered",1)),
  ("prefix",new.replace("   function Day_Count","   function Day_Count_BROKEN",1)),
  ("import",new.replace("with GNATCOLL.GMP.Integers;\n","",1)),
  ("count",new.replace("Canonical_Full_Weave_GMP_V164.Count","Canonical_Full_Weave_GMP_V164.Coin",1)),
  ("return",new.replace("return Natural_Array (Result);","return Result;",1)),
  ("legacy",new.replace("Canonical_Full_Weave_GMP_V164.Unrank","Month_Weaving.From_Choices",1))]
 for label,mutant in tests:
  require(mutant!=new,"mutation did not change source: "+label)
  try:verify(old,mutant)
  except AssertionError:continue
  raise AssertionError("negative mutation escaped guard: "+label)
 return len(tests)

def main():
 ci_guard()
 inventory={}
 for (ref,path),blob in PINS.items():
  actual=git("rev-parse",ref+":"+path)
  require(actual==blob,"locked source blob changed: "+path)
  raw=src(ref,path)
  inventory[ref+":"+path]={"git_blob":blob,"sha256":sha(raw),"bytes":len(raw)}
 old=src(ORIGINAL,"src/normative_oracle.adb").decode()
 new=src(BASE,"src/normative_oracle.adb").decode()
 require(Path("src/normative_oracle.adb").read_bytes()==new.encode(),"checkout changed")
 proj=Path("pastafari_calendar.gpr").read_text()
 require(proj.count('with "gnatcoll_gmp.gpr";')==1,"GMP missing from normal project")
 facts=verify(old,new)
 failed_mutants=mutations(old,new)
 require(failed_mutants==6,"negative mutation coverage")
 return {
 "schema":"ISSUE29_V190_BYTE_EXACT_GMP_PRODUCTION_PATCH_GUARD/1",
 "status":"PASS_SOURCE_ONLY_PROVENANCE_GMP_CALL_CHAIN",
 "corrected_source_commit":BASE,"historical_source_commit":ORIGINAL,
 "source_identity":inventory,
 "provenance":facts,"negative_source_mutations_rejected":failed_mutants,
 "documented_maintenance_risk":"GMP packages still contain QA-only comments despite production use",
 "external_full_stack_regression":"v188 separately accepted one-date native differential; not rerun",
 "original_F_calls":0,"native_calendar_calls":0,
 "original_soak_years":0,"halt_new_native_soak":True
 }
if __name__=="__main__":
 print(json.dumps(main(),indent=2,sort_keys=True))
