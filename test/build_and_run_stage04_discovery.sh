#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/stage04 evidence
LOG=evidence/stage04-foundation-tag.log
exec > >(tee "$LOG") 2>&1
echo PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
echo "SOURCE_SHA=$(git rev-parse HEAD)"
echo "FPC_VERSION=$(fpc -iV)"
test "$(fpc -iV)" = 3.2.2
python3 docs/stage04_foundation_day_tag_oracle.py --emit build/stage04/vectors.tsv
python3 docs/stage04_foundation_day_tag_oracle.py --check build/stage04/vectors.tsv
echo '74dc3e3d4ea07eeebed2647c798c7a3e1cbf91877e73a65351370a58c7e7ecab  build/stage04/vectors.tsv' | sha256sum -c -
fpc -B -Fu./src -FUbuild/stage04 -FEbuild/stage04 test/stage04_foundation_tag_probe.pas
set +e
timeout 180s build/stage04/stage04_foundation_tag_probe build/stage04/vectors.tsv > evidence/stage04-native-probe.log 2>&1
rc=$?
set -e
cat evidence/stage04-native-probe.log
echo "NATIVE_PROBE_EXIT=$rc"
test "$rc" = 1
grep -Fxq 'STAGE04_CASES=1072' evidence/stage04-native-probe.log
grep -Fxq 'STAGE04_TAG_COMPARISONS=5360' evidence/stage04-native-probe.log
grep -Fxq 'STAGE04_MISMATCH_ROWS=1' evidence/stage04-native-probe.log
test "$(grep -c '^MISMATCH ' evidence/stage04-native-probe.log)" = 1
grep -Fxq 'MISMATCH day=-15055671 expected=1 direct=0 decimal=0/0 context=0/0' evidence/stage04-native-probe.log
echo STAGE04_SEEDED_EXPECTED_RED_CONFIRMED=YES
echo STAGE04_PRODUCTION_CORRECT=NO
echo STAGE04_ACCEPTANCE=NOT_CLAIMED
