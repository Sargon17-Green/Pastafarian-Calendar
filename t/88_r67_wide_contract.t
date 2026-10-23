use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub readfile ($name) {
    my $f=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $h,'<:encoding(UTF-8)',$f or die "R67 缺少檔案 $name\n";
    local $/;my $s=<$h>;close $h;return $s;
}
my $src=readfile('t/87_r67_wide_bigint_prefix.t');
my $wf=readfile('.github/workflows/canonical-names-lock.yml');
for my $value (
    '34837538497713607370','2134397833143177403516',
    '474042534302340556453992',
    '1331903513327335554982512328'
) {
    like($src,qr/\Q$value\E/,"四個獨立固定 BigInt 值之一");
}
like($src,qr/for my \$j \(1\.\.\(\$opened<\$m\?\$opened\+1:\$m\)\)/,
     '獨立 DFS 自行枚舉合法新月份');
like($src,qr/\$total->badd\(\$walk->\(/,'每條合法後繼以 BigInt 無損相加');
like($src,qr/countWeavingsPolynomial\(\$sizes\)/,'不同演算法之精確多項式');
like($src,qr/early_final_closed_form=>1/,'有界 FIFO 和 CLOCK 均使用候選閉式');
like($src,qr/cache_limit=>16/,'私有快取硬上限十六項');
ok(index($src, 'independent_prefix($sizes,\\@prefix,$walk)')>=0,
     '完整詞真實前綴必須重算獨立參考值');
my @job=($wf =~ /^  canonical-r67-wide-boundary:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@job),1,'R67 專用驗證恰有一個 opt-in CI 工作');
if (@job==1) {
    like($job[0],qr/\[weaving-r67-wide-boundary\]/,'工作只由專用提交啟動');
    like($job[0],qr/timeout-minutes:\s*5\b/,'GitHub 工作五分鐘上限');
    like($job[0],qr/timeout --signal=TERM --kill-after=5s 195s/,
         '外層仍有 195 秒子程序清理上限');
    like($job[0],qr/--seconds 185 --rss-kib 393216/,
         '內層監督守衛 185 秒和 393216 KiB');
    like($job[0],qr/set -euo pipefail/,'失敗結果不可靜默忽略');
}
my $supervisor=readfile('tools/profile_r67_wide_bigint_prefix.pl');
like($supervisor,qr/waitpid\(\$child,WNOHANG\)/,
     '監督父程序會檢查真正執行中的子程序');
like($supervisor,qr/\$rss>\$rss_limit/,
     '超過 RSS 硬限額不得算 PASS');
like($supervisor,qr/\$elapsed>\$seconds/,
     '超過時間硬限額不得算 PASS');
like($supervisor,qr/exit 3;/,
     '資源阻擋以不同於正常完成的狀態回傳');
done_testing;