#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
# Hash-checked sources: full-root 39965349618 and fifth 39981519434.
grep -Fxq 'b41d09d58c02adbbbf05c931e447f584d6a1cbef' build/fullroot_head.txt
grep -Fxq 'cb667fffcb916d2e2d679eb1f518e2a8b07fef5d' build/prefix5_checked_sha.txt
echo "STAGE1_SIXTH_SOURCE_SHA_PIN_PASS"
for suffix in root rank prefix11 prefix121 prefix122 prefix123 prefix1231 prefix1232 prefix1233 prefix1234 prefix12341 prefix12342 prefix12343 prefix12344 prefix12345; do
  file="build/foundation_weave_$suffix.bin"
  test -f "$file" || { echo "PREFIX6_INPUT_MISSING:$file" >&2; exit 1; }
  test "$(wc -c < "$file")" -eq 2809
done
sha256sum -c <<'KNOWN'
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
bc967f4955b01f6e2564642f220289ed48c76e317d86e0ef6a2400f085e9dd04  build/foundation_weave_prefix12341.bin
2c9bc37b3ae5aa280948e798249489e51952b193a8f602724fcb2d7099bdf788  build/foundation_weave_prefix12342.bin
94f50d45b0e38755896a6c03f640091ef7ef79ca526f1f8ded92db436393da84  build/foundation_weave_prefix12343.bin
fe41feb02523a0a4308ad3e529a9111d77cecb796e0e3c71280331a251d14f61  build/foundation_weave_prefix12344.bin
3966afe882f4ef8d1d1ac1b7e9fc79b6065a01751f2bd51d315ecaa264c572a5  build/foundation_weave_prefix12345.bin
KNOWN
echo "STAGE1_SIXTH_ALL_PRIOR_INPUT_HASHES_PASS"
iverilog -g2012 -Wall -s tb_weave_full_root \
  -Ptb_weave_full_root.WIDTH=22528 \
  -o build/weave_fullroot_prefix6.vvp tests/tb_weave_full_root.sv
timeout 1100s vvp build/weave_fullroot_prefix6.vvp +stop_after=45 +prefix123451 \
  2>&1 | tee build/weave_prefix123451_run.log
test "$(wc -c < build/foundation_weave_prefix123451.bin)" -eq 2809
printf '%s  %s\n' \
  d8e4482e4011c525254fc9fbf7ff8c0b38d8f03debda9dc3db43c1058fc3cdf7 \
  build/foundation_weave_prefix123451.bin | sha256sum -c -
echo "STAGE1_PREFIX123451_FULLWIDTH_HASH_PASS"
iverilog -g2012 -Wall -s tb_weave_prefix6 \
  -o build/weave_prefix6.vvp tests/tb_weave_prefix6.sv
timeout 90s vvp build/weave_prefix6.vvp \
  2>&1 | tee build/weave_prefix6_run.log
sha256sum -c <<'SIXTH'
9f7fab49d0e0929992d4c5f397c26c4c5529af4ea46a429ca22c43362c1fed48  build/foundation_weave_prefix123452.bin
3572d06920a232605350f00195b0498a7bf504bb722fdf54350a843595b311c5  build/foundation_weave_prefix123453.bin
34d34643583f8fa6271eaefba1bc16ba635874693a26a27991853c8245f93b50  build/foundation_weave_prefix123454.bin
d3f9e4fa50a40a7ff5cb7738cf014efb6551b36336cc03c1eab0b60619f2662d  build/foundation_weave_prefix123455.bin
262ef3db56038db64fba34de4d013437c0f49fd6b99852e800491221d7836f2d  build/foundation_weave_prefix123456.bin
SIXTH
for i in 2 3 4 5 6; do
  test "$(wc -c < build/foundation_weave_prefix12345$i.bin)" -eq 2809
done
echo "STAGE1_FOUNDATION_SIXTH_ORDINAL_SHA256_PASS"
