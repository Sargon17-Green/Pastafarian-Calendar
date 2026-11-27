#!/usr/bin/env bash
# PREPARED_NOT_AUTHORIZED_NOT_RUN. No workflow trigger.
# Exactly one new witness; requires explicit authorization separate from this commit.
set -euo pipefail
if [[ "${ISSUE29_V204_AUTHORIZATION:-}" != "ONE_F_FIRST_DIVERGENCE_ONLY" ]]; then
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
c,t=-15055671,-15057695
fields=["YEAR","CUTLET_INDEX","CUTLET_DAY","MONTH_INDEX","MONTH_DAY"]
expected=[int(rows[t-(-15057702)][k]) for k in fields]
assert expected==[5000,15,8,28,2],expected
(e/"expected.json").write_text(json.dumps(dict(c=c,t=t,expected=expected))+"\n")
PY
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
git -C "$repo_root" archive "$live" src | tar -x -C "$work"
mkdir "$work/tests"
cat > "$work/v204.gpr" <<'GPR'
with "gnatcoll_gmp.gpr";
project V204 is
   for Source_Dirs use ("src", "tests");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("issue29_v204_single.adb");
   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2022", "-gnatW8", "-gnata", "-gnato");
   end Compiler;
end V204;
GPR
cat > "$work/tests/issue29_v204_single.adb" <<'ADA'
with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Normative_Oracle;
procedure Issue29_V204_Single is
   use Ada.Text_IO;
   use Ada.Numerics.Big_Numbers.Big_Integers;
   C : constant Big_Integer := To_Big_Integer (-15_055_671);
   T : constant Big_Integer := To_Big_Integer (-15_057_695);
   R : constant Normative_Oracle.Calendar_Result :=
     Normative_Oracle.Calendar_Date (C, T);
begin
   Put_Line ("V204 " & To_String (C) & " " & To_String (T) & " " &
     To_String (R.Year_Number) & " " & Positive'Image (R.Cutlet_Canonical) &
     " " & To_String (R.Day_In_Cutlet) & " " &
     Positive'Image (R.Month_Canonical) & " " & To_String (R.Day_In_Month));
end Issue29_V204_Single;
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
gprbuild -p -j2 -P v204.gpr > "$evidence/build.log" 2>&1
sha256sum bin/issue29_v204_single > "$evidence/binary.sha256"
# Create one-attempt marker before F. Never retry within this script.
( set -o noclobber; printf '%s\n' "$(date -u +%FT%TZ)" > "$evidence/F_ATTEMPT_ONCE" )
PC_STAGE13_DIAGNOSTIC=1 /usr/bin/time -v -o "$evidence/time.txt" bin/issue29_v204_single > "$evidence/stdout.txt" 2> "$evidence/stderr.txt"
INNER
# Total build + execution wall clock cap, enforced in the same cgroup.
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
out=(e/"stdout.txt").read_text() if (e/"stdout.txt").exists() else ""
rows=[x.split() for x in out.splitlines() if x.startswith("V204 ")]
actual=list(map(int,rows[0][1:])) if len(rows)==1 else None
want=[expected["c"],expected["t"]]+expected["expected"]
ok=code==0 and (e/"F_ATTEMPT_ONCE").is_file() and actual==want
result=dict(schema="ISSUE29_V204_SINGLE_F/1",exit=code,expected=want,actual=actual,matched=ok,attempt_marker=(e/"F_ATTEMPT_ONCE").is_file(),whole_year_credit=0,soak=False)
(e/"result.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result))
assert ok
PY
