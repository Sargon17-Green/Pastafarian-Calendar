#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/stage05 evidence
LOG=evidence/stage05-foundation-tag.log
exec > >(tee "$LOG") 2>&1
echo PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
echo "SOURCE_SHA=$(git rev-parse HEAD)"
echo "FPC_VERSION=$(fpc -iV)"
test "$(fpc -iV)" = 3.2.2
python3 docs/stage04_foundation_day_tag_oracle.py --emit build/stage05/vectors.tsv
python3 docs/stage04_foundation_day_tag_oracle.py --check build/stage05/vectors.tsv
echo '74dc3e3d4ea07eeebed2647c798c7a3e1cbf91877e73a65351370a58c7e7ecab  build/stage05/vectors.tsv' | sha256sum -c -
fpc -B -Fu./src -FUbuild/stage05 -FEbuild/stage05 test/stage04_foundation_tag_probe.pas
timeout 180s build/stage05/stage04_foundation_tag_probe build/stage05/vectors.tsv | tee evidence/stage05-production-probe.log
for marker in STAGE04_CASES=1072 STAGE04_TAG_COMPARISONS=5360 STAGE04_MISMATCH_ROWS=0; do
  grep -Fxq "$marker" evidence/stage05-production-probe.log
done
fpc -B -Fu./src -FUbuild/stage05 -FEbuild/stage05 test/stage05_foundation_tag_legacy.pas
timeout 180s build/stage05/stage05_foundation_tag_legacy build/stage05/vectors.tsv | tee evidence/stage05-legacy-probe.log
for marker in STAGE05_LEGACY_CASES=1072 STAGE05_LEGACY_EXPECTED_RED=1 STAGE05_LEGACY_MATCH=1071 STAGE05_FAILURES=0; do
  grep -Fxq "$marker" evidence/stage05-legacy-probe.log
done
grep -Fxq 'SEEDED_LEGACY_RED day=-15055671 expected=1 legacy=0 fixed=1' evidence/stage05-legacy-probe.log
echo STAGE05_PRODUCTION_GREEN=YES
echo STAGE05_LEGACY_RETAINED=YES
echo STAGE05_ACCEPTANCE=NOT_CLAIMED
