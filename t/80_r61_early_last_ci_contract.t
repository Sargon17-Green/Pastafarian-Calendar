use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub src ($relative) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$relative));
    open my $fh,'<:encoding(UTF-8)',$path
        or die "不能讀取 $relative\n";
    local $/;my $text=<$fh>;close $fh;return $text;
}
my $oracle=src('t/lib/Pastafari/WeavingMemoOracle.pm');
my $tool=src('tools/profile_canonical_memo_multi_ranks.pl');
my $wf=src('.github/workflows/canonical-names-lock.yml');
like($oracle,qr/\$m==4 && \$opened==3 && \$self->\{early_final_closed_form\}/,
     '只在四月份前三月已開而末月未開時使用精確閉式');
like($oracle,qr/\$self->_last_order\(\$remaining,\$closed\)/,
     '使用不依賴受測多項式排名的末次序閉式');
like($oracle,qr/\$early_final && !\$bounded/,
     '非明確 bounded QA 不得啟用提前閉式');
like($oracle,qr/\$limit>200000/,
     '有界前沿同時 BigInt 上限仍為 200000');
like($tool,qr/\$cache_options->\{early_final_closed_form\}=1/,
     'R61 以明確選項啟用而不改歷史預設');
like($tool,qr/\$case_filter =~ \/\\Ahash36-\(\?:08\|09\)\\z\//,
     'R61 僅涵蓋 R60 被 TIME_LIMIT 擋下的 08 和 09');
like($tool,qr/phase=R61_EARLY_LAST_ORDER_PASS/,
     '有真實閉式運行證據而非僅設開關');
my @names;
for my $n (qw(08 09)) {
    my @jobs=($wf =~ /^  canonical-fourmonth-r61-early-last-\Q$n\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"R61 $n 只有一個原生 opt-in 工作");
    next unless @jobs==1;
    my $body=$jobs[0];
    like($body,qr/\[weaving-fourmonth-r61-early-last\]/,
         "R61 $n 獨立啟動標記");
    like($body,qr/timeout-minutes:\s*5\b/,
         "R61 $n GitHub job 硬上限仍五分鐘");
    like($body,qr/set -euo pipefail/,
         "R61 $n 子進程 BLOCKED/FAIL 都傳播");
    like($body,qr/--window-offset 36 --case-filter hash36-\Q$n\E --seconds 185 --rss-kib 393216/,
         "R61 $n 每個完整 312 日排名仍 185 秒及 393216 KiB");
    push @names,$n;
}
is_deeply(\@names,[qw(08 09)],
          'R61 剛好兩個未完成固定 SHA-512 名次，無新增冗餘');
done_testing;
