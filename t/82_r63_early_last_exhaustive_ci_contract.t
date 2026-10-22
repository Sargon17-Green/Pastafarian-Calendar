use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($file) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$file));
    open my $fh,'<:encoding(UTF-8)',$p or die "不能讀取 $file\n";
    local $/; my $v=<$fh>;close $fh;return $v;
}
my $s=source('tools/profile_r63_exhaustive_early_last.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $c (qw(a b c d)) {
    like($s,qr/for my \$$c \(1\.\.7\)/,
         "第 $c 月涵蓋 1..7 的全部月長");
}
like($s,qr/\$vectors!=2401/,'7^4=2401 四月份小向量');
like($s,qr/\$states!=96040/,'96040 前三個月已開的狀態');
like($s,qr/\$reachable_states!=429779/,'429779 整體合法可達狀態');
like($s,qr/\$reference_states!=\$reachable_states/,
     '獨立直接遞迴的可達空間必須和另一合法後繼枚舉一致');
like($s,qr/\$ways\+=\$reference->\(/,
     '獨立前綴模型不調用任何受測閉式');
like($s,qr/\$oracle->count_prefix\(\$prefix\)/,
     '三個真正 Oracle 都逐狀態核對');
like($s,qr/early_final_closed_form=>1/,
     '受測 FIFO、CLOCK 確實啟用末次序閉式');
like($s,qr/cache_limit=>16/,'最多 16 個私有 BigInt 快取項');
like($s,qr/\$diag->\{entries\}>16/,'強制 16 項即時上限');
like($s,qr/\$oracle->count_prefix\(\[\]\)!=\$full/,
     '回傳 BigInt 修改不得汙染私有快取');
my @jobs=($ci =~ /^  canonical-r63-early-last-exhaustive:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@jobs),1,'只新增一個受控 R63 工作');
if (@jobs==1) {
    like($jobs[0],qr/\[weaving-fourmonth-r63-exhaustive\]/,'獨立 CI opt-in');
    like($jobs[0],qr/timeout-minutes:\s*5\b/,'GitHub job 上限不變');
    like($jobs[0],qr/set -euo pipefail/,'所有錯誤均傳遞');
    like($jobs[0],qr/--seconds 185 --rss-kib 393216/,
         '185 秒和 393216 KiB RSS 限制不變');
}
done_testing;
