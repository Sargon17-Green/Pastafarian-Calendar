use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub read_source ($path) {
    my $file=File::Spec->catfile($Bin,'..',split('/',$path));
    open my $fh,'<:encoding(UTF-8)',$file or die "R68 找不到 $path\n";
    local $/;my $s=<$fh>;close $fh;return $s;
}
my $source=read_source('tools/audit_r68_bigint_rank.pl');
my $guard=read_source('tools/profile_r68_bigint_rank.pl');
my $wf=read_source('.github/workflows/canonical-names-lock.yml');
for my $s ('34837538497713607370','2134397833143177403516',
           '9223372036854775807','9223372036854775808',
           '9223372036854775809') {
    ok(index($source,$s)>=0,"R68 完整 BigInt 契約常數 $s");
}
like($source,qr/\$sum!=\$parent/,
     '每日檢查合法下一字元全部候選總和');
like($source,qr/independent_rank\(\$word\)/,
     '獨立反向累加確切 1-based 字序');
like($source,qr/unrankWeavingPolynomial\(\$lengths,\$rank\)/,
     '必須與正式測試反排名器交叉驗證');
like($source,qr/rankWeavingPolynomial\(\$lengths,\$decoded\)/,
     '必須與正式測試正向排名器交叉驗證');
like($source,qr/sha512_hex\(/,'至少一個獨立確定性雜湊名次');
like($source,qr/\$partition_checks!=\$days\*\$verified/,
     '任一天不可省略父前綴分割檢查');
for my $profile (qw(a b)) {
    my @jobs=($wf =~ /^  canonical-r68-int64-rank-\Q$profile\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"R68 $profile 恰好一個 opt-in Native 工作");
    next unless @jobs==1;
    like($jobs[0],qr/\[weaving-r68-int64-rank\]/,
         "R68 $profile 僅顯式標記啟動");
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         "R68 $profile GitHub 5 分鐘硬上限");
    like($jobs[0],qr/--profile \Q$profile\E --seconds 185 --rss-kib 393216/,
         "R68 $profile 上限不放寬");
    like($jobs[0],qr/set -euo pipefail/,"R68 $profile 不吞異常返回");
}
like($guard,qr/waitpid\(\$pid,WNOHANG\)/,'父進程獨立監測終止狀態');
like($guard,qr/\$rss>\$rss_limit/,'子進程 RSS 限額精確檢驗');
like($guard,qr/\$elapsed>\$seconds/,'子進程執行時間精確檢驗');
like($guard,qr/exit 3;/,'資源阻擋不能誤判為成功');
done_testing;
