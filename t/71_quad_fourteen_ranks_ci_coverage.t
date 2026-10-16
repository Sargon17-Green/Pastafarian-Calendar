use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub contents ($name) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $fh,'<:encoding(UTF-8)',$p or die "不能讀取 $name\n";
    local $/;my $text=<$fh>;close $fh;return $text;
}
my $script=contents('tools/profile_canonical_memo_multi_ranks.pl');
my $ci=contents('.github/workflows/canonical-names-lock.yml');
like($script,qr/\$offset==37\s*\?\s*\{bounded_cache=>1,cache_limit=>200000\}/,
     '第 37 窗的全部十四排名沿用總額 200000 項 FIFO 上限');
like($script,qr/\@named=\@named\[0\.\.6\]\s+if\s+\$case_filter\s+eq\s+'first-half'/,
     '前七名嚴格含原本排序集合之 0..6');
like($script,qr/\@named=\@named\[7\.\.13\]\s+if\s+\$case_filter\s+eq\s+'last-half'/,
     '後七名嚴格含原本排序集合之 7..13');
like($script,qr/\$sum\s*!=\s*\$parent/,
     '每一天獨立 BigInt 分支候選和仍等於父前綴');
like($script,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '各個排名的 236 個字元逐日獨立核對');
my @filters;
for my $filter (qw(first-half last-half)) {
    my @jobs=($ci =~ /^  canonical-window37-\Q$filter\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"$filter BigInt 七排名工作恰好一個");
    next unless @jobs==1;
    my $body=$jobs[0];
    like($body,qr/\[weaving-window37-all14\]/,
         "$filter 工作有獨立提交標記");
    like($body,qr/timeout-minutes:\s*5\b/,
         "$filter 工作仍有五分鐘外層上限");
    like($body,qr/set -euo pipefail/,
         "$filter 並非容忍部分排名失敗");
    like($body,qr/--window-offset 37 --case-filter \Q$filter\E --seconds 185 --rss-kib 393216/,
         "$filter 原生完整七排名沿用個別子程序 185 秒 / 393216 KiB RSS");
    push @filters,$filter;
}
is_deeply(\@filters,[qw(first-half last-half)],
          '兩批七排名恰好補足全部 14 種 BigInt 字典序名次');
done_testing;
