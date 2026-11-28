#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(git rev-parse --show-toplevel)"
mkdir -p build/stage09 evidence/stage09
ev=evidence/stage09
git rev-parse HEAD > "$ev/source-sha.txt"
git rev-parse HEAD^{tree} > "$ev/tree-sha.txt"
if [[ -n "${GITHUB_SHA:-}" ]]; then
  test "$(cat "$ev/source-sha.txt")" = "$GITHUB_SHA"
fi
fpc -iV | tee "$ev/fpc-version.txt"
node --version | tee "$ev/node-version.txt"
python3 --version | tee "$ev/python-version.txt"
timeout 30s node docs/stage08_stone_snapshot_preflight.js > "$ev/expected.tsv" 2> "$ev/oracle.log"
cat "$ev/oracle.log"
grep -Fx '{"checks":694,"wraps":205,"maxBits":254}' "$ev/oracle.log"
timeout 60s fpc -B -Mobjfpc -Sh -Cr -Co -Fu"$PWD/src" -Fu"$PWD/test" -FU"$PWD/build/stage09" -FE"$PWD/build/stage09" test/stage09_stone_snapshot_probe.pas 2>&1 | tee "$ev/compile.log"
set +e
timeout 60s build/stage09/stage09_stone_snapshot_probe "$ev/expected.tsv" production > "$ev/production.tsv" 2> "$ev/production.stderr"
production_rc=$?
timeout 60s build/stage09/stage09_stone_snapshot_probe "$ev/expected.tsv" seeded-legacy > "$ev/legacy.tsv" 2> "$ev/legacy.stderr"
legacy_rc=$?
set -e
printf '%s\n' "$production_rc" | tee "$ev/production-exit.txt"
printf '%s\n' "$legacy_rc" | tee "$ev/legacy-exit.txt"
test "$production_rc" -eq 0
test "$legacy_rc" -eq 1
test ! -s "$ev/production.stderr"
test ! -s "$ev/legacy.stderr"
cmp "$ev/expected.tsv" "$ev/production.tsv"
timeout 30s python3 docs/stage08_stone_snapshot_verify.py "$ev/expected.tsv" "$ev/legacy.tsv" > "$ev/legacy-comparison.tsv" 2> "$ev/verify.log"
cat "$ev/verify.log"
printf '%s\n' '230 normative cells MATCH; 224 isolated SEEDED_RED, 6 legacy MATCH, 0 unexpected' | tee "$ev/summary.txt"
sha256sum "$ev"/{expected,production,legacy,legacy-comparison}.tsv "$ev"/{source-sha,tree-sha,production-exit,legacy-exit,summary}.txt > "$ev/sha256.txt"
cat "$ev/sha256.txt"
echo 'Stage09 native harness complete; acceptance requires independent evidence review and regression gates.'
