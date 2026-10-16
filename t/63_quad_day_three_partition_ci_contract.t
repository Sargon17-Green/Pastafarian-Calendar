use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub text_of ($path) {
    my $full=File::Spec->catfile($Bin,'..',split('/',$path));
    open my $fh,'<:encoding(UTF-8)',$full or die "無法讀取 $path：$!\n";
    local $/; my $txt=<$fh>; close $fh;
    return $txt;
}
my $script=text_of('tools/profile_canonical_window41_count.pl');
my $ci=text_of('.github/workflows/canonical-names-lock.yml');
like($script,qr/'third-day-partition!'\s*=>\s*\\\$third_day_partition/,
     '第三日分割必須由 opt-in 參數明確啟動');
like($script,qr/\$third_day_partition\s*\&\&\s*\(\$second_day_partition/,
     '第一階段兩種昂貴分割不可無意同次重跑');
for my $c (1..3) {
    like($script,qr/for\s+my\s+\$candidate\s*\(1,2,3\)/,
         "第三日包含前綴 [1,2,$c] 的完整合法候選清單");
}
like($script,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%stats\s*,\s*\\\@prefix\s*\)/,
     '每個第三日候選由獨立正向前沿獲得精確 BigInt 完工數');
like($script,qr/\$partition\s*!=\s*\$p12/,
     '三候選分割之精確和必須等於母前綴');
like($script,qr/\$word->\[2\]\s*!=\s*\$independent_third/,
     '獨立第三日分支必須與索引反排名逐符號相符');
my @jobs=($ci =~ /^  canonical-window37-third:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@jobs),1,'第三日原生測試只有一個獨立 job');
if (@jobs==1) {
    like($jobs[0],qr/\[weaving-window37-third\]/,
         'GitHub opt-in 標記嚴格分離於前一輪');
    like($jobs[0],qr/set -euo pipefail/,
         'GitHub 不能吞掉任何 Oracle 失敗');
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         '原生工作保留五分鐘上限');
    like($jobs[0],qr/--window-offset 37 --third-day-partition --seconds 185 --rss-kib 393216/,
         'Oracle 每次實驗保留 185 秒 / 393216 KiB RSS 預算');
}
done_testing;
