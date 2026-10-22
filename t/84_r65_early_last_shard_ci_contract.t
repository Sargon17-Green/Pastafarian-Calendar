use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($name) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $h,'<:encoding(UTF-8)',$p or die "原始檔無法開啟 $name\n";
    local $/;my $s=<$h>;close $h;return $s;
}
my $s=source('tools/profile_r65_exhaustive_early_last.pl');
my $wf=source('.github/workflows/canonical-names-lock.yml');
my @expected=(
    [1,2,1458,42282,226719],
    [3,4,1458,88938,474579],
    [5,6,1458,135594,722439],
    [7,8,1458,182250,970299],
    [9,9,729,108621,578097]
);
my ($vectors,$opened3,$reachable)=(0,0,0);
for my $record (@expected) {
    my ($a,$b,$v,$state,$all)=@$record;
    $vectors+=$v;$opened3+=$state;$reachable+=$all;
    like($s,qr/'\Q$a-$b\E'=>\[\Q$v,$state,$all\E\]/,
         "子批 $a..$b 的已凍結獨立參考值完整存在");
    my @jobs=($wf =~ /^  canonical-r65-early-last-\Q$a-$b\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"子批 $a..$b 恰有一個原生工作");
    next unless @jobs==1;
    my $body=$jobs[0];
    like($body,qr/\[weaving-fourmonth-r65-exhaustive\]/,
         "子批 $a..$b 是獨立 opt-in");
    like($body,qr/timeout-minutes:\s*5\b/,
         "子批 $a..$b 工作上限不超過五分鐘");
    like($body,qr/set -euo pipefail/,
         "子批 $a..$b 將 FAIL/BLOCKED 傳播回 CI");
    like($body,qr/--a-min $a --a-max $b --seconds 185 --rss-kib 393216/,
         "子批 $a..$b 的原有時間與 RSS 限制不變");
}
is($vectors,6561,'四個月全部 1..9 的 6561 個向量不重不漏');
is($opened3,557685,'全部提前末次序可達狀態的固定獨立總數');
is($reachable,2972133,'全部合法可達狀態的固定獨立總數');
for my $part (qw(b c d)) {
    like($s,qr/for my \$$part \(1\.\.9\)/,
         "月份 $part 枚舉全部九種原生長度");
}
like($s,qr/for my \$a \(\$a_min\.\.\$a_max\)/,
     '第一月份依固定五個互斥區段執行');
like($s,qr/!exists\(\$expected\{"\$a_min-\$a_max"\}\)/,
     '不得輸入未核對的任意分片界線');
like($s,qr/\$full!=45407181480430770/,
     '最長 9,9,9,9 另須符合 17 位獨立 BigInt 整數');
like($s,qr/\$full>=9223372036854775807/,
     '獨立 native int64 參考不得溢位');
like($s,qr/\$ways\+=\$reference->\(/,
     '參考遞迴只以合法下一月份求和，不調用受測閉式');
like($s,qr/\$oracle->count_prefix\(\$prefix\)/,
     '逐個實際可達前綴，比對原 DFS、FIFO 和 CLOCK');
like($s,qr/cache_limit=>16/,
     '兩種循環快取每個最多 16 個 BigInt 項');
like($s,qr/\$reference_states!=\$reachable_states/,
     '所有可達狀態都由獨立參考模型覆蓋');
done_testing;
