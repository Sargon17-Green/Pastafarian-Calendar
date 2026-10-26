#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

# Generated ONLY by native SystemVerilog +dump_H. 101,594 fixed-width
# ASCII-HEX rows, with exactly 5632 digits and one LF per row.
expected_records=101594
record_bytes=5633
expected_bytes=572279002
test -f build/native_H_table.hex
test "$(wc -c < build/native_H_table.hex)" -eq "$expected_bytes"
test "$(wc -l < build/native_H_table.hex)" -eq "$expected_records"

iverilog -g2012 -Wall -s tb_weave_native_H_lookup \
  -o build/native_H_lookup.vvp tests/tb_weave_native_H_lookup.sv
timeout 180s vvp build/native_H_lookup.vvp \
  2>&1 | tee build/native_H_lookup.log
grep -Fq 'STAGE1_NATIVE_H_INDEXED_TABLE_LOOKUP_PASS' build/native_H_lookup.log

sha256sum -c <<'INDEXED_WITNESSES'
925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da  build/native_H_read_s1_max.bin
642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac  build/native_H_read_s1_prev.bin
903228a4685940927cf8bf8be4163ae28f956a3a41344bacff62acfa84fb3255  build/native_H_read_s2_max.bin
6199811b24db53a04bef33b5555dccaeb1df85a20a041653fab100e5931fa490  build/native_H_read_s2_prev.bin
fb354fadea7c1562da47697de899e9907e8220cc0cd3dd3d0133b497890c5bac  build/native_H_read_s3_max.bin
9f394fa33476905419e7df15ffaa13f28cbc5213da83d7d3b45c08ba2249fe58  build/native_H_read_s3_prev.bin
d1e58bc2d883383337f52f7ce02fc1013a93c87d8812c04fd27702a8a379530c  build/native_H_read_s7_max.bin
5f6977434fb4dd8edc88240b925cd57df89fd60c804e5990794382894c12977a  build/native_H_read_s7_prev.bin
a17e63c69b16cb0687e05da01afd685a49d9dac448e45e19506be9769177736b  build/native_H_read_s8_max.bin
5af65f4ec9628620c4eccb398eceba7a31cc51a7358b36fe5044d985b856e89f  build/native_H_read_s8_prev.bin
59cb0fc88be55607db8d593203f4bc3f459ae3be94c723abd325a35f5847272c  build/native_H_read_s15_max.bin
ab87e6af820fbcae8cc7aa7a1d0a956b633409526da8d9ab6985d3940b87471c  build/native_H_read_s15_prev.bin
125d0161f929daf2242cf495cbc7dc9b7be36f7eadab6cab19bf17075d6b8ea7  build/native_H_read_s44_max.bin
609c33d0ef49e11583385c23c4bd7bdd49258fa78dda63e7b6df5edfa652ccf6  build/native_H_read_s44_prev.bin
a0a22c77a263b53c576362896bcc6498e942d1c1c82bafcc93f1f27b7937bd9a  build/native_H_read_s45_max.bin
a0a22c77a263b53c576362896bcc6498e942d1c1c82bafcc93f1f27b7937bd9a  build/native_H_read_s45_prev.bin
INDEXED_WITNESSES
echo "STAGE1_NATIVE_H_INDEXED_16_GOLDEN_HASHES_PASS"

# Deliberately shift the first seek one hex digit. The native
# lookup must reject it with a specific fatal before any PASS.
if timeout 30s vvp build/native_H_lookup.vvp +mutate_address \
    > build/native_H_lookup_negative.log 2>&1; then
  echo 'STAGE1_NATIVE_H_INDEXED_MUTATION_FALSE_PASS' >&2
  exit 1
fi
grep -Fq 'NATIVE_H_INDEXED_ROOT_MISMATCH' build/native_H_lookup_negative.log
echo 'STAGE1_NATIVE_H_INDEXED_TAMPER_REJECTED_PASS'

# Full native SystemVerilog A(r) combinatorial factor and
# lex branch counts for the first seven selected month labels.
# No Python block counts are loaded: all 9 values are computed
# from the native H(7,746)/H(7,745) indexed table values.
iverilog -g2012 -Wall -s tb_weave_native_H_children7 \
  -o build/native_H_children7.vvp tests/tb_weave_native_H_children7.sv
timeout 180s vvp build/native_H_children7.vvp \
  2>&1 | tee build/native_H_children7.log
for item in parent 1 2 3 4 5 6 7 8; do
  test "$(wc -c < "build/native_H_children7_$item.bin")" -eq 2809
done
sha256sum -c <<'NATIVE_CHILDREN7_GOLDENS'
c89443f21642a9cbacbc12f4e6d970ab4815806d3b1b6dc836f247c1a4cc8849  build/native_H_children7_parent.bin
0b72169fe3c363a5a56b37f225bc1b45ec78793a430eca85419a3700a576f727  build/native_H_children7_1.bin
0f23e693e34c220dcc004ff9c7b02bfd421c957bd4f8a273f3e1e5663b81db17  build/native_H_children7_2.bin
9616b8efa8fadbecc7edf35a9577807f96f46311840a46dac3127a2d9a71fba1  build/native_H_children7_3.bin
d38ddf106d30d6cdf6be7cd24015d2ee499dcf149e3d83004c1c6eafe5b1f074  build/native_H_children7_4.bin
66c270cb320cf87e59e93216273279c2eba4a8509c71b3028897c793610671ef  build/native_H_children7_5.bin
d563dfc476051de9f88006796f71cb4fe5614a546f77da485912ff3ec427cfaf  build/native_H_children7_6.bin
bbdfde541270cc68fe80e726546e220c34c0e5dfe918f5a5d2f5e4ec3b8dd2c7  build/native_H_children7_7.bin
002b3835ca88649360d71268823385c79d12d5ff1f9950e2bd4fd77eb3e2b1fb  build/native_H_children7_8.bin
NATIVE_CHILDREN7_GOLDENS
echo 'STAGE1_NATIVE_H_CHILDREN7_NINE_FULLWIDTH_GOLDENS_PASS'

