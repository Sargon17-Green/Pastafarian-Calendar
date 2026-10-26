#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
# Reuse exact H built in this SAME native-SV CI job.
test "$(wc -c < build/native_H_table.hex)" -eq 572279002
test "$(wc -c < build/native_H_root.bin)" -eq 2809
# Python derives only the rank from the NATIVE root and fixed bowl-4
# inputs; NO branch counts, word, or rank-interval ledger are loaded.
python3 - <<'PY'
from hashlib import sha256
from pathlib import Path
root=int.from_bytes(Path("build/native_H_root.bin").read_bytes(),"big")
base=(1<<127)-1
a0=106458209471735273212934705135928382248
answer=1
place=1
for digit in range(177):
    answer+=(a0-1-digit)*place
    place*=base
rank=(answer-1)%root+1
Path("build/native_lex_rank.bin").write_bytes(rank.to_bytes(2809,"big"))
if sha256(rank.to_bytes((rank.bit_length()+7)//8,"big")).hexdigest() != "2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06":
    raise SystemExit("NATIVE_LEX_INITIAL_RANK_SHA_MISMATCH")
print("STAGE1_NATIVE_LEX_INITIAL_RANK_SHA_PIN_PASS",flush=True)
PY
iverilog -g2012 -Wall -s tb_weave_native_lex_prefix \
    -o build/native_lex_prefix.vvp tests/tb_weave_native_lex_prefix.sv
timeout 240s vvp build/native_lex_prefix.vvp +max_positions=16 \
    2>&1 | tee build/native_lex_prefix.log
grep -Fq 'STAGE1_NATIVE_LEX_EXHAUSTED_MONTH_CASES_PASS cases=6' build/native_lex_prefix.log
grep -Fq 'STAGE1_NATIVE_LEX_PREFIX_SV_PASS positions=16' build/native_lex_prefix.log
test "$(wc -c < build/native_lex_prefix.bin)" -eq 16
echo 'STAGE1_NATIVE_LEX_DIRECT16_REFERENCE_PASS_PENDING_FAST64_HASH'
echo 'STAGE1_NATIVE_LEX_DIRECT16_PREFIX_COMPLETED'
# Mutate one native H(old) lookup. The independently computed
# H(fresh) conservation must reject it as mathematically inconsistent.
if timeout 240s vvp build/native_lex_prefix.vvp +max_positions=16 +mutate_old_H \
    > build/native_lex_prefix_negative.log 2>&1; then
    echo 'STAGE1_NATIVE_LEX_H_MUTANT_FALSE_PASS' >&2
    exit 1
fi
grep -Fq 'NATIVE_LEX_FRESH_PARTITION_MISMATCH' build/native_lex_prefix_negative.log
echo 'STAGE1_NATIVE_LEX_FRESH_PARTITION_MUTANT_REJECTED_PASS'
