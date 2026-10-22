use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($file) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$file));
    open my $fh,'<:encoding(UTF-8)',$p or die "不能讀取 $file\n";
    local $/; my $body=<$fh>; close $fh; return $body;
}
my $s=source('tools/profile_r64_exhaustive_early_last.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $c (qw(a b c d)) {
    like($s,qr/for my \$$c \(1\.\.8\)/,
         "月份 $c 的所有 1..8 長度均被逐一執行");
}
like($s,qr/\$vectors!=4096/,'完全覆蓋 4096 個四月份向量');
like($s,qr/\$states!=244224/,'244224 個提前末次序可達狀態');
like($s,qr/\$reachable_states!=1194240/,'1194240 個所有合法可達狀態');
like($s,qr/\$reference_states!=\$reachable_states/,
     '獨立合法後繼模型覆蓋全部可達狀態');
like($s,qr/\$full!=216355766851224/,
     '8,8,8,8 對稱最長向量另有獨立精確總數檢查');
like($s,qr/\$full>=9223372036854775807/,
     '單一純整數參考數量必須安全放入 int64');
like($s,qr/\$ways\+=\$reference->\(/,
     '參考合法後繼遞迴完全獨立於受測閉式');
like($s,qr/\$oracle->count_prefix\(\$prefix\)/,
     '三個原生 Oracle 全部逐前綴核對');
like($s,qr/early_final_closed_form=>1/,
     'FIFO CLOCK 確實 opt-in 提前末次序閉式');
like($s,qr/cache_limit=>16/,'私有記憶 BigInt 上限仍 16');
like($s,qr/\$diag->\{entries\}>16/,
     '不容許任何一個 Oracle 突破 16 項常駐快取');
like($s,qr/\$oracle->count_prefix\(\[\]\)!=\$full/,
     '修改回傳值不可污染內部 BigInt 快取');
my @jobs=($ci =~ /^  canonical-r64-early-last-exhaustive:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
is(scalar(@jobs),1,'唯一的受控 R64 原生 CI 工作');
if (@jobs==1) {
    like($jobs[0],qr/\[weaving-fourmonth-r64-exhaustive\]/,
         'R64 opt-in 與歷史 R63 隔離');
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         '原生 GitHub 工作上限仍五分鐘');
    like($jobs[0],qr/set -euo pipefail/,
         '任何數學 FAIL 或資源 BLOCKED 均視為錯誤');
    like($jobs[0],qr/--seconds 185 --rss-kib 393216/,
         '不放寬 185 秒／393216 KiB RSS 限制');
}
done_testing;
