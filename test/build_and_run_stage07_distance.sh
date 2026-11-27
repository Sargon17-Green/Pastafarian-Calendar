#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/stage07 evidence
exec > >(tee evidence/stage07-distance.log) 2>&1
echo PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
echo "SOURCE_SHA=$(git rev-parse HEAD)"
echo "SOURCE_TREE=$(git rev-parse HEAD^{tree})"
echo "FPC_VERSION=$(fpc -iV)"
test "$(fpc -iV)" = 3.2.2
python3 docs/stage06_distance_tag_scale_oracle.py --emit build/stage07/vectors.tsv
fpc -B -Fu./src -Fu./test -FUbuild/stage07 -FEbuild/stage07 test/stage07_distance_probe.pas
set +e
timeout 240s build/stage07/stage07_distance_probe build/stage07/vectors.tsv evidence/stage07-observed.tsv >evidence/stage07-native.log 2>&1
rc=$?
set -e
cat evidence/stage07-native.log
echo "NATIVE_EXIT=$rc"
test "$rc" = 0
grep -Fxq STAGE07_NATIVE_ROWS=8100 evidence/stage07-native.log
grep -Fxq STAGE07_NATIVE_MISMATCH_ROWS=0 evidence/stage07-native.log
python3 docs/stage07_distance_verify.py build/stage07/vectors.tsv evidence/stage07-observed.tsv
sha256sum build/stage07/vectors.tsv evidence/stage07-observed.tsv evidence/stage07-native.log
echo STAGE07_ACCEPTANCE=NOT_CLAIMED
