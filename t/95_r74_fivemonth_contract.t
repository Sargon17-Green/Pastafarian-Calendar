use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($path) {
 my $file=File::Spec->catfile($Bin,'..',split('/',$path));
 open my $fh,'<:encoding(UTF-8)',$file or die "R74 缺少 $path\n";
 local $/;my $s=<$fh>;close $fh;return $s;
}
my $audit=source('tools/audit_r74_fivemonth_order.pl');
my $guard=source('tools/profile_r74_fivemonth_order.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $data (
 '3703','18719','64121',
 '7081ddef2b4f08c855979a86c0eaf8323491dce1e669d7fc0885ffd2a97faf14',
 '1bbf1195a27f99d60e9ce004b7385ff379eec6f115a59927abf446c695f2d126',
 '252cc5821cb54d747c57ae131cd33b7dc0bf7ec50126e3ce01e35aacc9693f6f'
) {
 ok(index($audit,$data)>=0,"R74 五個月固定獨立真值 $data");
}
like($audit,qr/for my \$e \(1\.\.3\)/,'第五個月確實全枚舉 1..3');
like($audit,qr/my \@mirror=map \{6-\$_\} reverse \@\$word/,
     '鏡射五個月用第六個標籤互補且反轉全部實際字元');
like($audit,qr/independent_rank\(\\\@rev,\$counter_reversed,\\\@mirror\)/,
     '倒序五個月鏡射排名由獨立 DFS 重建');
like($audit,qr/\$N!=\$N_reversed/,
     '反轉後月份長度精確總數須保持不變');
like($audit,qr/countWeavingsPolynomial\(\\\@L\)/,
     '五個月 BigInt 總數對照異構位置多項式');
like($audit,qr/\$clock->count_prefix\(\\\@prefix\)!=\$correct/,
     '每條五個月測試詞須檢查真實前綴計數');
like($audit,qr/\$ranks!=\$mirrors/,
     '每條原始樣本必須完成雙射鏡射檢驗');
for my $shard (1..3) {
 my @job=($ci =~ /^  canonical-r74-fivemonth-\Q$shard\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
 is(scalar(@job),1,"R74 shard $shard 獨立 Native 工作恰一份");
 next unless @job==1;
 like($job[0],qr/\[weaving-r74-fivemonth\]/,"R74 shard $shard 僅專用標記觸發");
 like($job[0],qr/timeout-minutes:\s*5\b/,"R74 shard $shard 五分鐘 CI 限額");
 like($job[0],qr/--shard \Q$shard\E --seconds 185 --rss-kib 393216/,
      "R74 shard $shard 保留 RSS 與 185 秒界線");
 like($job[0],qr/set -euo pipefail/,"R74 shard $shard 不隱藏失敗碼");
}
like($guard,qr/waitpid\(\$pid,WNOHANG\)/,'原生父進程持續監督');
like($guard,qr/\$rss>\$rss_limit/,'RSS 超限不能 PASS');
like($guard,qr/\$elapsed>\$seconds/,'執行超時不能 PASS');
like($guard,qr/exit 3;/,'資源阻擋採非零退出碼');
my $exhaustive_sha=source('tools/audit_r74_fivemonth_order.pl');
like($exhaustive_sha,qr/sub enumerate_legal_words/,'R74 真正列舉全部完整五個月字詞');
like($exhaustive_sha,qr/\$seen_mirrors\{\$mirror\}\+\+/,'R74 全集反轉映射要求單射');
like($exhaustive_sha,qr/keys\(%seen_mirrors\)!=scalar\(\@\$reverse_words\)/,
     'R74 全集反轉映射要求滿射');
like($exhaustive_sha,qr/\$mapping_sha ne \$expected_exhaustive_sha/,
     'R74 每份鏡射位置表須比對獨立 SHA256');
done_testing;
