use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($name) {
    my $file=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $fh,'<:encoding(UTF-8)',$file or die "R72 缺少 $name\n";
    local $/;my $s=<$fh>;close $fh;return $s;
}
my $audit=source('tools/audit_r72_prefix_intervals.pl');
my $watch=source('tools/profile_r72_prefix_intervals.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $v ('4056','27697','116768','380893',
    '23e29a89c0b0ae4d769d121bd1109e1d21752114227236c810390b7c6bd33da2',
    '9831bee46cbf9d49a203ac3b530064d41c6ad074fe325c25f039a4a3da170e93',
    '9c703bd25c34f7512945c2ffb80cb648b2722b1b7c0bdc33c3e862736594f224',
    'aee9969ee80e407efccb96ea36e1ff68c07a1fa3d568e0bd93a7f0e032f7078c') {
    ok(index($audit,$v)>=0,"R72 64 向量分組的基線值 $v");
}
like($audit,qr/\$finish=\$start->copy->badd\(\$ways\)->bsub\(1\)/,
    '預計算區間終點確實是 start+ways-1');
like($audit,qr/\$rank_first!=\$start/,
    '合法最小完整詞排名必須恰等於區間起點');
like($audit,qr/\$rank_last!=\$end/,
    '合法最大完整詞排名必須恰等於區間終點');
like($audit,qr/\$answer!=\$ways/,
    '有界 clock oracle 對每個合法前綴都核對完工數');
like($audit,qr/\$outside=unrankWeavingPolynomial/,
    '區間外的鄰接 BigInt 排名也必須排除同一前綴');
like($audit,qr/\$endpoint_checks!=\$intervals\*4/,
    '每個區間有四次 Native rank/unrank 交叉檢查');
for my $shard (1..4) {
    my @jobs=($ci =~ /^  canonical-r72-prefix-interval-\Q$shard\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"R72 shard $shard 有且僅有一個 opt-in CI 工作");
    next unless @jobs==1;
    like($jobs[0],qr/\[weaving-r72-prefix-intervals\]/,
         "R72 shard $shard 需要專用提交標記");
    like($jobs[0],qr/timeout-minutes:\s*5\b/,
         "R72 shard $shard 五分鐘 CI 硬上限");
    like($jobs[0],qr/--shard \Q$shard\E --seconds 185 --rss-kib 393216/,
         "R72 shard $shard 時間和 RSS 明確限制");
    like($jobs[0],qr/set -euo pipefail/,
         "R72 shard $shard 任一步失敗不能繼續假陽性");
}
like($watch,qr/waitpid\(\$pid,WNOHANG\)/,'原生父程序監督');
like($watch,qr/\$rss>\$rss_limit/,'RSS 超限必須 BLOCKED');
like($watch,qr/\$elapsed>\$seconds/,'walltime 超限必須 BLOCKED');
like($watch,qr/exit 3;/,'超限不同於成功退出碼');
done_testing;
