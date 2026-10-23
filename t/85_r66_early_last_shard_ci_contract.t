use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;

sub slurp ($f) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$f));
    open my $fh,'<:encoding(UTF-8)',$p or die "不能讀取：$f\n";
    local $/;my $s=<$fh>;close $fh;return $s;
}
my $src=slurp('tools/profile_r66_exhaustive_early_last.pl');
my $wf=slurp('.github/workflows/canonical-names-lock.yml');
my @seen;
my ($n_vec,$n_early,$n_states)=(0,0,0);
my @expected=(
 [1,1000,25750,150125],[2,1000,46000,267000],
 [3,1000,66250,383875],[4,1000,86500,500750],
 [5,1000,106750,617625],[6,1000,127000,734500],
 [7,1000,147250,851375],[8,1000,167500,968250],
 [9,1000,187750,1085125],[10,1000,208000,1202000]
);
for my $x (@expected) {
    my ($a,$vec,$early,$all)=@$x;
    $n_vec+=$vec;$n_early+=$early;$n_states+=$all;
    like($src,qr/'\Q$a-$a\E'=>\[\Q$vec,$early,$all\E\]/,
         "獨立凍結的 a=$a 完整總量不可變");
    my @jobs=($wf =~ /^  canonical-r66-early-last-\Q$a\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"a=$a 只允許一個原生工作");
    next unless @jobs==1;
    my $body=$jobs[0];
    like($body,qr/\[weaving-fourmonth-r66-exhaustive\]/,
        "a=$a 嚴格 opt-in");
    like($body,qr/timeout-minutes:\s*5\b/,
        "a=$a GitHub 工作上限五分鐘");
    like($body,qr/set -euo pipefail/,
        "a=$a 不吞 FAIL/BLOCKED");
    like($body,qr/--a-min $a --a-max $a --seconds 185 --rss-kib 393216/,
        "a=$a 保持 185 秒／393216 KiB 上限");
    push @seen,$a;
}
is_deeply(\@seen,[1..10],'恰好十個 a 分片，每個長度 1..10');
is($n_vec,10000,'10^4 個四月向量不重不漏');
is($n_early,1168750,'第 4 個月未開的早期關閉狀態總數');
is($n_states,6760625,'全部可達合法符號狀態總數');
for my $m (qw(b c d)) {
    like($src,qr/for my \$$m \(1\.\.10\)/,
        "月份 $m 枚舉全部十種長度");
}
like($src,qr/\$wide=\(\$a==10 \&\& \$b==10 \&\& \$c==10 \&\& \$d==10\)/,
    '只有全長 10,10,10,10 的獨立模型需要 64-bit 跨界運算');
like($src,qr/Math::BigInt->bzero/,
    '溢位參考遞迴必須使用獨立無損 BigInt 加法');
like($src,qr/\$ways->badd\(\$part\)/,
    '每個合法字序路徑累加不得先在 int64 中溢位');
like($src,qr/9754478684858928020/,
    '最大向量的精確 BigInt 參考計數固定');
like($src,qr/\$full>=9223372036854775807/,
    '其它向量必須拒絕超 int64 參考');
like($src,qr/\$reference_states!=\$reachable_states/,
    '每個可達狀態都應在獨立遞迴中出現');
like($src,qr/cache_limit=>16/,'FIFO/CLOCK 仍然只有十六個私有狀態');
# R66 執行結果識別不得沿用 R65，尤其是錯誤與資源限制分支。
unlike($src,qr/\bR65_EARLY_LAST_SHARD(?:_COMPLETE)?\b/,
    'R66 日誌不得誤用 R65 狀態識別');
like($src,qr/R66_EARLY_LAST_SHARD status=FAIL reason=/,
    'R66 失敗紀錄須可被正確歸屬');
like($src,qr/R66_EARLY_LAST_SHARD status=BLOCKED reason=/,
    'R66 時間或記憶體上限須可被正確歸屬');
like($src,qr/R66_EARLY_LAST_SHARD_COMPLETE passed=1 blocked=0 failed=0/,
    'R66 成功終態須有正確識別');
like($src,qr/R66_EARLY_LAST_SHARD_COMPLETE passed=0 blocked=0 failed=1/,
    'R66 失敗終態須有正確識別');
like($src,qr/R66_EARLY_LAST_SHARD_COMPLETE passed=0 blocked=1 failed=0/,
    'R66 阻擋終態須有正確識別');
done_testing;
