use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub read_file ($file) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$file));
    open my $fh,'<:encoding(UTF-8)',$path or die "不能讀取 $file\n";
    local $/;
    my $text=<$fh>;
    close $fh;
    return $text;
}
my $script=read_file('tools/profile_canonical_memo_multi_ranks.pl');
my $workflow=read_file('.github/workflows/canonical-names-lock.yml');
like($script,qr/\$offset\s*!=\s*37\s*\&\&\s*\$offset\s*!=\s*38/,
     '擴充真實 37 視窗，同時保留此前 38..40 窗口');
like($script,qr/\$offset\s*==\s*37\s*\?\s*'83,88,40,25'/,
     '固定第 37 窗口為經權威 SHA 核對的 236 日月份');
like($script,qr/\$offset\s*==\s*37\s*\?\s*236/,
     '第 37 窗口實際應為 236 日');
like($script,qr/\$case_filter\s+eq\s+'middle'/,
     '獨立受控只計算中間一基 BigInt 樣本');
like($script,qr/my\s+\$counter=Pastafari::WeavingMemoOracle->new/,
     '獨立合法前綴完工數不是索引排名器自己的快取');
like($script,qr/my\s+\$parent=\$counter->count_prefix\(\\\@prefix\)/,
     '每一日都直接向獨立 Oracle 計算母前綴');
like($script,qr/\$sum\s*!=\s*\$parent/,
     '每一天全部合法下一標籤的 BigInt 和必須等於母前綴');
like($script,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '每一日獨立字典序選擇必須等於磁碟索引反排名的字元');
like($script,qr/\$local\s*!=\s*1/,
     '完整 236 日後當前局部 BigInt 名次必須歸 1');
my @jobs=($workflow =~ /^  canonical-window37-full-independent-middle:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@jobs),1,'獨立 236 日全長中位字序只啟動一個受控工作');
if (@jobs==1) {
    like($jobs[0],qr/\[weaving-window37-full-middle\]/,
         '新的完整 236 日驗證有獨立 opt-in 標記');
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         'GitHub CI 整體仍限五分鐘');
    like($jobs[0],qr/set -euo pipefail/,
         '任何一天的差異不可被吞掉');
    like($jobs[0],qr/--window-offset 37 --case-filter middle --seconds 185 --rss-kib 393216/,
         '185 秒／393216 KiB RSS 有界工作完整保留');
}
done_testing;
