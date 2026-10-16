use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub read_source ($relative) {
    my $file=File::Spec->catfile($Bin,'..',split('/',$relative));
    open my $fh,'<:encoding(UTF-8)',$file or die "原始碼無法讀取 $relative：$!\n";
    local $/;
    my $content=<$fh>;
    close $fh;
    return $content;
}
my $script=read_source('tools/profile_canonical_window41_count.pl');
my $workflow=read_source('.github/workflows/canonical-names-lock.yml');
like($script,qr/\b37\s*=>\s*'83,88,40,25'/,
     '第 37 四月窗具有已核對的真實 Year 5000 月長');
like($script,qr/\$window_offset\s*=\s*\$requested_offset\s+if\s+defined\s+\$requested_offset/,
     '真正使用受控 window-offset，而不只列印窗口名稱');
like($script,qr/my\s+\$window_offset\s*=\s*41\s*;/,
     '未改動歷史 402 日原本的預設窗口');
like($script,qr/'second-day-partition!'\s*=>\s*\\\$second_day_partition/,
     '第二日精確分割僅在明確 opt-in 時執行');
like($script,qr/\$requested_offset\s*!=\s*37/,
     '只能對第 37 窗執行新獨立分支檢查');
like($script,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%a_stats\s*,\s*\[1,1\]\s*\)/,
     '前沿獨立列舉第二日選 1 的完工詞');
like($script,qr/countWeavingsFrontier\s*\(\s*\\\@L\s*,\s*\\%b_stats\s*,\s*\[1,2\]\s*\)/,
     '前沿獨立列舉第二日選 2 的完工詞');
like($script,qr/\$sum\s*!=\s*\$oracle/,
     '兩個第二日分支總數必須等於完整獨立 BigInt');
like($script,qr/\$word->\[1\]\s*!=\s*\$independent_second/,
     '獨立第二日 BigInt 決策必須核對索引反排名');
my @jobs=($workflow =~ /^  canonical-window37-prefix:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@jobs),1,'窗口 37 opt-in CI 工作只建立一份');
if (@jobs==1) {
    like($jobs[0],qr/\[weaving-window37-prefix\]/,'嚴格的獨立 opt-in 標記');
    like($jobs[0],qr/timeout-minutes:\s*5\b/,'獨立 CI 總時限五分鐘');
    like($jobs[0],qr/set -euo pipefail/,'任何子程序失敗都會使工作失敗');
    like($jobs[0],qr/--window-offset 37 --second-day-partition --seconds 185 --rss-kib 393216/,
         '原始 185 秒、393216 KiB RSS 資源預算保留');
}
done_testing;
