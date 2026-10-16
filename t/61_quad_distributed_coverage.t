use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use FindBin qw($Bin);
use File::Spec;

sub slurp ($relative) {
    my $full=File::Spec->catfile($Bin,'..',split('/',$relative));
    open my $fh,'<:encoding(UTF-8)',$full
        or die "無法讀取 Stage 1 原始檔：$relative：$!\n";
    local $/;
    my $text=<$fh>;
    close $fh;
    return $text;
}
my $profile=slurp('tools/profile_canonical_window41_count.pl');
my $workflow=slurp('.github/workflows/canonical-names-lock.yml');

my ($raw)=$profile=~/my\s+\@year\s*=\s*\(([\d,\s]+)\)\s*;/s;
ok(defined $raw,'四月份工具明文宣告第 5000 年月份快照');
my @year=defined($raw) ? map {0+$_} split(/,\s*/,$raw) : ();
is(scalar(@year),45,'完整固定年份仍恰有四十五個月');
is(sha256_hex(join(',',@year)),
   '6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134',
   '三種算法採用已確認的原生 Year 5000 精確向量');
my $sum=0; $sum+=$_ for @year;
is($sum,4244,'來源年份仍有 4244 日');

my %expected;
while ($profile=~/^\s*(10|20|28|36|41)\s*=>\s*'([\d,]+)',\s*$/mg) {
    $expected{0+$1}=$2;
}
is_deeply([sort {$a<=>$b} keys %expected],[10,20,28,36,41],
          '只啟用明示審核的四月份窗口，不做任意靜默外推');
for my $index (sort {$a<=>$b} keys %expected) {
    my $actual=join(',',@year[$index..$index+3]);
    is($expected{$index},$actual,
       "月份起始 $index 的原生年份四月快照未錯置");
}
like($profile,qr/my\s+\$window_offset\s*=\s*41\s*;/,
     '既有 402 日最後四月工作仍以 41 為預設');
like($profile,qr/'window-offset=i'\s*=>\s*\\\$requested_offset/,
     '額外月份偏移經命令列顯式解析');
like($profile,qr/\$window_offset\s*=\s*\$requested_offset\s+if\s+defined\s+\$requested_offset/,
     '正確使用要求的四月窗口索引');
like($profile,qr/\bcountWeavingsFrontier\b/,
     '全新窗口仍使用獨立正向合法狀態計數');
like($profile,qr/\bcountWeavingsPolynomialStream\b/,
     '磁碟串流精確 BigInt 計數器沒有被刪除');

my (@jobs,@offsets,%seen);
while ($workflow =~ /^  canonical-quad-frontier-(\d+):[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg) {
    my ($idx,$body)=(0+$1,$2);
    push @jobs,$idx;
    my @in_job=($body =~ /--window-offset\s+(\d+)\s+--seconds/g);
    is_deeply(\@in_job,[$idx],
              "四月窗口 $idx 只受控呼叫本窗口一次");
    like($body,qr/\[weaving-quad-distributed\]/,
         "窗口 $idx 有 opt-in 標記");
    like($body,qr/timeout-minutes:\s*5\b/,
         "窗口 $idx GitHub 有五分鐘獨立總上限");
    like($body,qr/set -euo pipefail/,
         "窗口 $idx 的失敗不會被吞掉");
    like($body,qr/timeout --signal=TERM --kill-after=5s 260s perl -Ilib -It\/lib tools\/profile_canonical_window41_count\.pl --window-offset \d+ --seconds 185 --rss-kib 393216/,
         "窗口 $idx 保留原本的受控資源界線");
    $seen{$idx}++;
    push @offsets,$idx;
}
is_deeply(\@jobs,[10,28,36],
          '三個分散窗口的獨立 CI 工作均有且僅有一份');
ok(!(grep {$_!=1} values %seen),'每個新窗口只有一份受控工作');
done_testing;
