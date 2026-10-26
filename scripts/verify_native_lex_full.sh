#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
# This is a CONTINUATION in the same CI job that generated native H(s,N).
# Do not read Python-generated word, rank interval ledger, or child counts.
test "$(wc -c < build/native_H_table.hex)" -eq 572279002
test "$(wc -c < build/native_lex_rank.bin)" -eq 2809
test -f build/native_lex_fast.vvp

# 3-GiB virtual-memory ulimit belongs to the enclosing CI job.
# This isolated full-year cap allows resource exhaustion to FAIL,
# never to be misreported as a valid partial calendar.
timeout 850s vvp build/native_lex_fast.vvp +max_positions=4244 \
    2>&1 | tee build/native_lex_full.log
grep -Fq 'STAGE1_NATIVE_LEX_FAST_SV_PASS positions=4244' build/native_lex_full.log
grep -Fq 'STAGE1_NATIVE_LEX_ALL4244_TERMINAL_RANK_ONE_PASS' build/native_lex_full.log
grep -Fq 'STAGE1_NATIVE_LEX_MONTH1_FINISH_PASS position=4137' build/native_lex_full.log
grep -Fq 'STAGE1_NATIVE_LEX_EXHAUSTED_MONTH1_GATE_PASS position=4138' build/native_lex_full.log
grep -Fq 'STAGE1_NATIVE_LEX_MONTH2_FINISH_PASS position=4148' build/native_lex_full.log
grep -Fq 'STAGE1_NATIVE_LEX_EXHAUSTED_MONTH2_GATE_PASS position=4149' build/native_lex_full.log
grep -Fq 'NATIVE_LEX_PREFIX_PROGRESS position=2032 ordinal=8' build/native_lex_full.log
test "$(wc -c < build/native_lex_fast_prefix.bin)" -eq 4244

# Only rename the byte sequence that the SV decoder just generated.
cp build/native_lex_fast_prefix.bin build/native_lex_full.bin
printf '%s\n' 'e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29  build/native_lex_full.bin' | sha256sum -c
echo STAGE1_NATIVE_LEX_ALL4244_WORD_SHA256_PASS

# Independent *structural verifier of SV OUTPUT*, never an input to
# the decoder: no per-step Python H, no selected word, no rank ledger.
python3 - <<'PY' 2>&1 | tee build/native_lex_full_structural.log
from pathlib import Path
from collections import Counter
word=Path("build/native_lex_full.bin").read_bytes()
lengths=[115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,97,
         115,96,107,61,106,115,119,39,84,103,115,107,55,119,97,50,
         122,110,81,54,101,83,88,40,25,77,98,122,105]
assert len(word)==4244
assert [word.count(i) for i in range(1,46)]==lengths
assert [word.index(i) for i in range(1,46)]==sorted(word.index(i) for i in range(1,46))
assert [word.rindex(i) for i in range(1,46)]==sorted(word.rindex(i) for i in range(1,46))
assert word[:11]==bytes([1,2,3,4,5,6,7,4,8,9,10])
assert word[254]==45
assert word[2031]==8 and word[:2032].count(8)==56
assert word.rindex(1)==4136 and word.rindex(2)==4147
assert word[-1]==45
print("STAGE1_NATIVE_LEX_ALL4244_SV_OUTPUT_STRUCTURE_PASS days=4244 months=45 firstlast=ordered foundation_month=8 day=56",flush=True)
PY
grep -Fq 'STAGE1_NATIVE_LEX_ALL4244_SV_OUTPUT_STRUCTURE_PASS' build/native_lex_full_structural.log
echo STAGE1_NATIVE_LEX_FULL_YEAR_TEST_ONLY_GREEN_GATE_PASS
