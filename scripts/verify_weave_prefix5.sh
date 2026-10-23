#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

# The CI job must download artifact "stage1-full-weave-root-qa"
# from the pinned, known-good run 39946357557. Avoid recomputing
# older 34-minute fullroot/prefix verification when verifying one
# more prefix. SHA-256 checks below are the actual data boundary.
test -s build/fullroot_head.txt
sha256sum -c <<'CHECKED'
925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da  build/foundation_weave_root.bin
2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06  build/foundation_weave_rank.bin
642e6ddd164593dd415bc78ea87142e949a1cc4728accff2c8693a9120f81cac  build/foundation_weave_prefix11.bin
0a29d31d02e980a1ae807575c85a908bd31a05eb73b521a80f7ee3f2e925f1a7  build/foundation_weave_prefix121.bin
50064b46e82a20681a0e100e8a1516e0b4c151398231dd2f898be22f07bb9866  build/foundation_weave_prefix122.bin
a89a9799db0649b78a5b24bf150f57dc11e549ce2d0d42088929974237762dde  build/foundation_weave_prefix123.bin
b66cf4cc1afb8b2b604e574ff0ba1d788b0eb83bb7dbfc67a103a08ef220d340  build/foundation_weave_prefix1231.bin
47a2f7fa694e5bd1d85307df85ad5067c7f7aee18c441ec7c47b38a6a66c5531  build/foundation_weave_prefix1232.bin
8f680a1e1ee8f272f8ec2b243f2b9a5d4c63c7aa73e6866ba4dc610353440b1a  build/foundation_weave_prefix1233.bin
cbc01e54edc50fc880531214fc5fe5aa6c72252483a4b70a58458711570f37f5  build/foundation_weave_prefix1234.bin
CHECKED
for file in build/foundation_weave_{root,rank,prefix11,prefix121,prefix122,prefix123,prefix1231,prefix1232,prefix1233,prefix1234}.bin; do
  test "$(wc -c < "$file")" -eq 2809
done
echo "STAGE1_REUSED_PRIOR_VERIFIED_SHA_ARTIFACT_PASS source_run=39946357557"
iverilog -g2012 -Wall -s tb_weave_full_root \
  -Ptb_weave_full_root.WIDTH=22528 \
  -o build/weave_fullroot.vvp tests/tb_weave_full_root.sv
timeout 1000s vvp build/weave_fullroot.vvp +stop_after=45 +prefix12341 \
  2>&1 | tee build/weave_prefix12341_run.log
test "$(wc -c < build/foundation_weave_prefix12341.bin)" -eq 2809
printf '%s  %s\n' \
  bc967f4955b01f6e2564642f220289ed48c76e317d86e0ef6a2400f085e9dd04 \
  build/foundation_weave_prefix12341.bin | sha256sum -c -
echo "STAGE1_WEAVE_PREFIX12341_SHA256_PASS"

iverilog -g2012 -Wall -s tb_weave_prefix5 \
  -o build/weave_prefix5.vvp tests/tb_weave_prefix5.sv
timeout 90s vvp build/weave_prefix5.vvp \
  2>&1 | tee build/weave_prefix5_run.log
sha256sum -c <<'FIFTH_BLOCKS'
2c9bc37b3ae5aa280948e798249489e51952b193a8f602724fcb2d7099bdf788  build/foundation_weave_prefix12342.bin
94f50d45b0e38755896a6c03f640091ef7ef79ca526f1f8ded92db436393da84  build/foundation_weave_prefix12343.bin
fe41feb02523a0a4308ad3e529a9111d77cecb796e0e3c71280331a251d14f61  build/foundation_weave_prefix12344.bin
3966afe882f4ef8d1d1ac1b7e9fc79b6065a01751f2bd51d315ecaa264c572a5  build/foundation_weave_prefix12345.bin
FIFTH_BLOCKS
for file in build/foundation_weave_prefix1234{2,3,4,5}.bin; do
  test "$(wc -c < "$file")" -eq 2809
done
echo "STAGE1_WEAVE_FIFTH_ORDINAL_SHA256_PASS"
