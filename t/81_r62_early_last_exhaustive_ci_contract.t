use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($file) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$file));
    open my $fh,'<:encoding(UTF-8)',$path
        or die "不能讀取 Stage 1 QA：$file\n";
    local $/;my $text=<$fh>;close $fh;return $text;
}
my $tool=source('tools/profile_r62_exhaustive_early_last.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
like($tool,qr/for my \$a \(1\.\.5\)/,'第一個月窮舉 1..5');
like($tool,qr/for my \$b \(1\.\.5\)/,'第二個月窮舉 1..5');
like($tool,qr/for my \$c \(1\.\.5\)/,'第三個月窮舉 1..5');
like($tool,qr/for my \$d \(1\.\.5\)/,'第四個月窮舉 1..5');
like($tool,qr/\$vectors!=625/,'625 個完整四月份小向量');
like($tool,qr/\$states!=9375/,'9375 個前三月已開之可達狀態');
like($tool,qr/my \$reference\s*;/,'確實建立另一獨立合法詞遞迴');
like($tool,qr/\$ways\+=\$reference->\(/,'直接合法下一步數字遞迴，不依賴新閉式');
like($tool,qr/early_final_closed_form=>1/,'FIFO 和 CLOCK 均啟用待核對的精確閉式');
like($tool,qr/cache_limit=>16/,'以小於標準限制的 16 項壓力測試快取淘汰');
like($tool,qr/\$diag->\{entries\}>16/,'任何時刻 16 項硬界線強制有效');
like($tool,qr/\$oracle->count_prefix\(\[\]\)!\=\$full/,'所有向量完整計數與直接列舉相同');
my @jobs=($ci =~ /^  canonical-r62-early-last-exhaustive:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@jobs),1,'只設一個獨立 R62 opt-in 原生工作');
if (@jobs==1) {
    my $body=$jobs[0];
    like($body,qr/\[weaving-fourmonth-r62-exhaustive\]/,'只有專用提交標記啟動');
    like($body,qr/timeout-minutes:\s*5\b/,'GitHub Job 仍以五分鐘為硬上限');
    like($body,qr/set -euo pipefail/,'任何子測試失敗必須讓 CI 失敗');
    like($body,qr/--seconds 185 --rss-kib 393216/,
         '每次原生驗證仍保留 185 秒和 393216 KiB RSS');
}
done_testing;
