
use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;

# 驗證 GitHub Actions 計畫「本身」恰好覆蓋真實年份的
# 43 個零起始三月份窗口，避免稽核者誤漏月或重複月。
my $workflow=File::Spec->catfile(
    $Bin,'..','.github','workflows','canonical-names-lock.yml'
);
open my $fh,'<:encoding(UTF-8)',$workflow
    or die "無法讀取 Stage 1 規範 CI 工作流：$!\n";
local $/;
my $yaml=<$fh>;
close $fh;

my (@batch_jobs,@indices,%seen);
while ($yaml =~ /^  canonical-triple-rank-batch-(\d+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
    my ($start,$body)=($1,$2);
    push @batch_jobs,$start;
    my @loops=($body =~ /^\s+for offset in ([0-9 ]+); do[ \t]*$/mg);
    is(scalar(@loops),1,"三月批次 $start 恰好有一個明確列出的窗口循環");
    next unless @loops==1;
    my @this=split(/\s+/, $loops[0]);
    my @expected=$start..($start+3>42 ? 42 : $start+3);
    is_deeply(\@this,\@expected,
       "批次 $start 只含連續 1..4 個真正相鄰三月窗口");
    like($body,qr/\[weaving-all-triple-ranks\]/,
       "批次 $start 需要獨立 opt-in 標記");
    like($body,qr/timeout-minutes:\s*15\b/,
       "批次 $start 的 GitHub Job 有明確 15 分鐘最高預算");
    like($body,qr/set -euo pipefail/,
       "批次 $start 中任何子窗口非零狀態必須傳播失敗");
    like($body,qr/timeout --signal=TERM --kill-after=5s 260s perl -Ilib -It\/lib tools\/profile_canonical_triple_rank_paths\.pl --window-offset "\$offset" --seconds 185 --rss-kib 393216/,
       "批次 $start 中各窗口保留自身 185 秒和 393216 KiB RSS 上限");
    like($body,qr/CANONICAL_TRIPLE_RANK_BATCH status=PASS start=$start count=/,
       "批次 $start 完整跑完才記錄結果");
    for my $i (@this) {
        push @indices,$i;
        $seen{$i}++;
    }
}
is(scalar(@batch_jobs),11,'總共有十一個不重疊的三月字典序批次');
is_deeply(\@batch_jobs,[0,4,8,12,16,20,24,28,32,36,40],
    '批次依序從 0 至 40 覆蓋全部起點');
is_deeply(\@indices,[0..42],'四十三個相鄰三月窗口全部精確覆蓋一次');
ok(!(grep {$_!=1} values %seen),'每個三月起始下標出現恰好一次');
is(scalar(keys %seen),43,'總共四十三個不同的月份起點');
done_testing;
