#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(git rev-parse --show-toplevel)"
mkdir -p build/stage08 evidence/stage08
ev=evidence/stage08
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
timeout 60s fpc -B -Mobjfpc -Sh -Cr -Co -Fu"$PWD/src" -FU"$PWD/build/stage08" -FE"$PWD/build/stage08" test/stage08_stone_snapshot_probe.pas 2>&1 | tee "$ev/compile.log"
set +e
timeout 60s build/stage08/stage08_stone_snapshot_probe "$ev/expected.tsv" > "$ev/observed.tsv" 2> "$ev/probe.stderr"
rc=$?
set -e
printf '%s\n' "$rc" | tee "$ev/probe-exit.txt"
test "$rc" -eq 1
timeout 30s python3 docs/stage08_stone_snapshot_verify.py "$ev/expected.tsv" "$ev/observed.tsv" > "$ev/comparison.tsv" 2> "$ev/verify.log"
cat "$ev/verify.log"
sha256sum "$ev"/{expected,observed,comparison}.tsv "$ev"/{source-sha,tree-sha,probe-exit}.txt > "$ev/sha256.txt"
cat "$ev/sha256.txt"
echo 'Stage08 harness verified expected seeded RED; not production GREEN or stage acceptance.'
