#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/stage06 evidence
exec > >(tee evidence/stage06-distance.log) 2>&1
echo PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
echo "SOURCE_SHA=$(git rev-parse HEAD)"
echo "SOURCE_TREE=$(git rev-parse HEAD^{tree})"
echo "FPC_VERSION=$(fpc -iV)"
test "$(fpc -iV)" = 3.2.2
python3 docs/stage06_distance_tag_scale_oracle.py --emit build/stage06/vectors.tsv
fpc -B -Fu./src -FUbuild/stage06 -FEbuild/stage06 test/stage06_distance_probe.pas
set +e
timeout 240s build/stage06/stage06_distance_probe build/stage06/vectors.tsv evidence/stage06-observed.tsv >evidence/stage06-native.log 2>&1
rc=$?
set -e
cat evidence/stage06-native.log
echo "NATIVE_EXIT=$rc"
test "$rc" = 1
grep -Fxq STAGE06_NATIVE_ROWS=8100 evidence/stage06-native.log
grep -Fxq STAGE06_NATIVE_MISMATCH_ROWS=8010 evidence/stage06-native.log
python3 docs/stage06_distance_tag_scale_oracle.py --verify build/stage06/vectors.tsv evidence/stage06-observed.tsv
sha256sum build/stage06/vectors.tsv evidence/stage06-observed.tsv evidence/stage06-native.log
echo STAGE06_SEEDED_RED_CONFIRMED_BY_HARNESS=YES
echo STAGE06_ACCEPTANCE=NOT_CLAIMED
