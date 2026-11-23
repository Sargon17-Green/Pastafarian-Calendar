#!/usr/bin/env bash
# Native differential gate. Run from repository root.
set -u -o pipefail
mkdir -p evidence build
(
  set -euo pipefail
  echo "PROJECT_ID=PC-BRANCH-OBJECT-PASCAL-PORTUGUESE"
  echo "SOURCE_SHA=$(git rev-parse HEAD)"
  echo "UTC_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "FPC_VERSION=$(fpc -iV)"
  test "$(fpc -iV)" = "3.2.2"
  python3 docs/stage02_workcounts_oracle.py --self-test
  python3 docs/stage02_workcounts_oracle.py --emit build/stage02_workcounts_vectors.tsv
  python3 docs/stage02_workcounts_oracle.py --check build/stage02_workcounts_vectors.tsv
  digest="$(sha256sum build/stage02_workcounts_vectors.tsv | cut -d' ' -f1)"
  echo "STAGE02_TSV_SHA256=$digest"
  test "$digest" = "1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12"
  (
    cd test
    fpc -B -Fu../src -FE../build stage02_workcounts_regression.pas
  )
  ./build/stage02_workcounts_regression build/stage02_workcounts_vectors.tsv
  (
    cd test
    fpc -B -Fu../src -FE../build stage02_context_integration.pas
  )
  ./build/stage02_context_integration build/stage02_workcounts_vectors.tsv
) 2>&1 | tee evidence/stage02-native-fpc.log
status=$?
echo "STAGE02_EXIT=$status" | tee -a evidence/stage02-native-fpc.log
exit "$status"
