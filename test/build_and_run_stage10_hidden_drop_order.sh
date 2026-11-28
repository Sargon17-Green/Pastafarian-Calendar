#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8
cd "$(git rev-parse --show-toplevel)"
mkdir -p build/stage10 evidence/stage10
ev=evidence/stage10
git rev-parse HEAD > "$ev/source-sha.txt"
git rev-parse HEAD^{tree} > "$ev/tree-sha.txt"
if [[ -n "${GITHUB_SHA:-}" ]]; then
  test "$(cat "$ev/source-sha.txt")" = "$GITHUB_SHA"
fi
fpc -iV | tee "$ev/fpc-version.txt"
python3 --version | tee "$ev/python-version.txt"
timeout 30s python3 docs/stage10_hidden_drop_order_oracle.py generate "$ev/expected.tsv"
timeout 90s fpc -B -Mobjfpc -Sh -Cr -Co -Fu"$PWD/src" -FU"$PWD/build/stage10" -FE"$PWD/build/stage10" test/stage10_hidden_drop_order_probe.pas 2>&1 | tee "$ev/compile.log"
set +e
timeout 120s build/stage10/stage10_hidden_drop_order_probe "$ev/expected.tsv" > "$ev/observed.tsv" 2> "$ev/probe.stderr"
rc=$?
set -e
printf '%s\n' "$rc" | tee "$ev/probe-exit.txt"
test "$rc" -eq 1
test ! -s "$ev/probe.stderr"
timeout 30s python3 docs/stage10_hidden_drop_order_oracle.py verify "$ev/expected.tsv" "$ev/observed.tsv" > "$ev/comparison.tsv" 2> "$ev/summary.txt"
cat "$ev/summary.txt"
grep -Fx '100 pairs; 5600 trace MATCH; 600 SEEDED_RED slots; 100 slot MATCH; 0 unexpected' "$ev/summary.txt"
(cd "$ev" && sha256sum expected.tsv observed.tsv comparison.tsv source-sha.txt tree-sha.txt probe-exit.txt summary.txt fpc-version.txt compile.log probe.stderr > sha256.txt)
cat "$ev/sha256.txt"
echo 'Stage10 seeded RED harness complete; independent acceptance review still required.'
