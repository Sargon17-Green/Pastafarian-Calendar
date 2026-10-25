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
