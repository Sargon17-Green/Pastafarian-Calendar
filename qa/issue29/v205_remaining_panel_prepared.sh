#!/usr/bin/env bash
# PREPARED_NOT_AUTHORIZED_NOT_RUN. No workflow trigger.
# Eight remaining frozen v191 witnesses; no new F until explicitly authorized.
# v204 accepted for its single witness only: run 46024534551, job 140592397331,
# artifact 15212166434, SHA256 cd3f0ac8aec1a84dda5d2cd437b085e86dc04a3d143679f141e479669dfbff2a.
# v204 result (-15055671,-15057695) -> (5000,15,8,28,2), 9.80 s, 103468 KiB RSS.
# v203 native cached projection: 4244/4244, not full F or whole-year credit.
# No Stage42, main, merge, release, or soak. STOP_NEW_NATIVE_SOAK_DISPATCH=true.
set -euo pipefail
if [[ "${ISSUE29_V205_AUTHORIZATION:-}" != "EIGHT_F_REMAINING_PANEL_ONLY" ]]; then
  echo "NOT_AUTHORIZED: no execution"; exit 64
fi
if [[ $# != 1 ]]; then echo "Usage: bash $0 NEW_EVIDENCE_DIRECTORY"; exit 64; fi
for cmd in git gh python3 sha256sum gprbuild systemd-run sudo timeout; do command -v "$cmd" >/dev/null; done
[[ "$(stat -fc %T /sys/fs/cgroup)" == cgroup2fs ]]
sudo -n true
repo_root="$(git rev-parse --show-toplevel)"
evidence="$(realpath -m "$1")"
mkdir "$evidence" # must be new; no overwrite or accidental rerun
live="d10d50383025d73ad2ce11d19d5759221d70f730"
printf '%s\n' "$live" > "$evidence/live-source.txt"
git -C "$repo_root" cat-file -e "$live^{commit}"
test "$(git -C "$repo_root" rev-parse "$live:src/normative_oracle.adb")" = "0be8f8ab4ddef26d34963d5567707a511ebda50b"
test "$(git -C "$repo_root" rev-parse "$live:src/canonical_full_weave_gmp_v164.adb")" = "845bd8905943a54e63d6aba0334404a5051fe666"
git -C "$repo_root" ls-tree -r "$live" src > "$evidence/source-blobs.txt"
gh api repos/Sargon17-Green/Pastafarian-Calendar/actions/artifacts/15199677578/zip > "$evidence/reference.zip"
echo "937dc0962d77c4e66f28bbde731716b08612cfb5a304b948ad02543b0af25e50  $evidence/reference.zip" | sha256sum -c -
python3 - "$evidence" <<'PY'
import csv,json,sys,zipfile,hashlib
from pathlib import Path
e=Path(sys.argv[1])
with zipfile.ZipFile(e/"reference.zip") as z:
    assert z.testzip() is None
    def get(s):
        names=[n for n in z.namelist() if n.endswith(s)]
        assert len(names)==1
        return z.read(names[0])
    data=get("oracle/STAGE55_YEAR5000_CANDIDATE.csv")
    assert data==get("STAGE55_YEAR5000_CANDIDATE_RUN1.csv")==get("STAGE55_YEAR5000_CANDIDATE_RUN2.csv")
    summary=json.loads(get("projection-summary.json"))
    assert summary["matched_rows"]==8488
    assert hashlib.sha256(data).hexdigest()==summary["projection_sha256"]
rows=list(csv.DictReader(data.decode("ascii").splitlines()))
assert len(rows)==4244
c=-15055671
fields=["YEAR","CUTLET_INDEX","CUTLET_DAY","MONTH_INDEX","MONTH_DAY"]
frozen=[
    (-15055658,[5000,14,13,3,69]),
    (-15056671,[5000,17,273,20,29]),
    (-15054671,[5000,14,1000,23,36]),
    (-15057702,[5000,15,1,18,1]),
    (-15057696,[5000,15,7,6,1]),
    (-15056944,[5000,15,759,16,20]),
    (-15056943,[5000,17,1,40,12]),
    (-15055670,[5000,14,1,29,38]),
]
assert len({t for t,_ in frozen})==8
assert all(t not in (-15055671,-15057695) for t,_ in frozen)
for t,want in frozen:
    assert [int(rows[t-(-15057702)][k]) for k in fields]==want,(t,want)
(e/"expected.json").write_text(json.dumps([dict(c=c,t=t,expected=w) for t,w in frozen],indent=2)+"\n")
(e/"targets.txt").write_text("".join(str(t)+"\n" for t,_ in frozen))
PY
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -C "$repo_root" archive "$live" src | tar -x -C "$work"
mkdir "$work/tests"
cat > "$work/v205.gpr" <<'GPR'
with "gnatcoll_gmp.gpr";
project V205 is
   for Source_Dirs use ("src", "tests");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("issue29_v205_panel.adb");
   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2022", "-gnatW8", "-gnata", "-gnato");
   end Compiler;
end V205;
GPR
cat > "$work/tests/issue29_v205_panel.adb" <<'ADA'
with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Normative_Oracle;
procedure Issue29_V205_Panel is
   use Ada.Text_IO;
   use Ada.Numerics.Big_Numbers.Big_Integers;
   C : constant Big_Integer := To_Big_Integer (-15_055_671);
   T : Big_Integer;
begin
   if Ada.Command_Line.Argument_Count /= 1 then
      raise Constraint_Error with "exactly one target required";
   end if;
   T := From_String (Ada.Command_Line.Argument (1));
   if T /= To_Big_Integer (-15_055_658)
     and then T /= To_Big_Integer (-15_056_671)
     and then T /= To_Big_Integer (-15_054_671)
     and then T /= To_Big_Integer (-15_057_702)
     and then T /= To_Big_Integer (-15_057_696)
     and then T /= To_Big_Integer (-15_056_944)
     and then T /= To_Big_Integer (-15_056_943)
     and then T /= To_Big_Integer (-15_055_670)
   then
      raise Constraint_Error with "target outside approved remaining panel";
   end if;
   declare
      R : constant Normative_Oracle.Calendar_Result :=
        Normative_Oracle.Calendar_Date (C, T);
   begin
   Put_Line ("V205 " & To_String (C) & " " & To_String (T) & " " &
     To_String (R.Year_Number) & " " & Positive'Image (R.Cutlet_Canonical) &
     " " & To_String (R.Day_In_Cutlet) & " " &
     Positive'Image (R.Month_Canonical) & " " & To_String (R.Day_In_Month));
   end;
end Issue29_V205_Panel;
ADA
cat > "$work/bounded.sh" <<'INNER'
#!/usr/bin/env bash
set -euo pipefail
cd "$1"
evidence="$2"
# Validate effective cgroup cap and swap prohibition before building.
cg="$(awk -F: '$1=="0"{print $3}' /proc/self/cgroup)"
test "$(cat "/sys/fs/cgroup$cg/memory.max")" = 1073741824
test "$(cat "/sys/fs/cgroup$cg/memory.swap.max")" = 0
printf '%s\n' "$cg" > "$evidence/cgroup.txt"
cat "/sys/fs/cgroup$cg/memory.max" "/sys/fs/cgroup$cg/memory.swap.max" > "$evidence/memory-limits.txt"
ulimit -v 1048576
gprbuild -p -j2 -P v205.gpr > "$evidence/build.log" 2>&1
sha256sum bin/issue29_v205_panel > "$evidence/binary.sha256"
# One attempt per distinct target; stop immediately on mismatch or failure.
while IFS= read -r t; do
  d="$evidence/case_$t"
  mkdir "$d"
  ( set -o noclobber; printf '%s\n' "$(date -u +%FT%TZ)" > "$d/F_ATTEMPT_ONCE" )
  PC_STAGE13_DIAGNOSTIC=1 /usr/bin/time -v -o "$d/time.txt" bin/issue29_v205_panel "$t" > "$d/stdout.txt" 2> "$d/stderr.txt"
  python3 - "$evidence" "$t" <<'VERIFY'
import json,sys
from pathlib import Path
e=Path(sys.argv[1]); t=int(sys.argv[2]); d=e/f"case_{t}"
want=next(r for r in json.loads((e/"expected.json").read_text()) if r["t"]==t)
rows=[x.split() for x in (d/"stdout.txt").read_text().splitlines() if x.startswith("V205 ")]
actual=list(map(int,rows[0][1:])) if len(rows)==1 else None
expected=[want["c"],t]+want["expected"]
ok=actual==expected and not (d/"stderr.txt").read_bytes()
(d/"result.json").write_text(json.dumps(dict(expected=expected,actual=actual,matched=ok))+"\n")
print(t, "PASS" if ok else "FAIL",flush=True)
assert ok
VERIFY
done < "$evidence/targets.txt"
INNER
# Total build + all eight executions wall clock cap (180 seconds), same cgroup.
set +e
sudo -n systemd-run --scope --quiet -p MemoryMax=1G -p MemorySwapMax=0 \
  timeout -k 2s 178s sudo -n -u "$(id -un)" bash "$work/bounded.sh" "$work" "$evidence" > "$evidence/scope.log" 2>&1
code=$?
set -e
echo "$code" > "$evidence/exit.txt"
python3 - "$evidence" "$code" <<'PY'
import json,sys
from pathlib import Path
e=Path(sys.argv[1]); code=int(sys.argv[2])
expected=json.loads((e/"expected.json").read_text())
cases=[]
for r in expected:
    d=e/f"case_{r['t']}"
    p=d/"result.json"
    cases.append(dict(t=r["t"],attempted=(d/"F_ATTEMPT_ONCE").is_file(),
                      result=json.loads(p.read_text()) if p.exists() else None))
attempted=sum(r["attempted"] for r in cases)
matched=sum(bool(r["result"] and r["result"]["matched"]) for r in cases)
ok=code==0 and attempted==matched==8
result=dict(schema="ISSUE29_V205_REMAINING_PANEL/1",exit=code,attempted=attempted,
            matched=matched,cases=cases,whole_year_credit=0,soak=False,pass_panel=ok)
(e/"result.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result))
assert ok
PY
