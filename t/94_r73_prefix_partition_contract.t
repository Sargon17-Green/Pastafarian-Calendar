use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($path) {
 my $file=File::Spec->catfile($Bin,'..',split('/',$path));
 open my $fh,'<:encoding(UTF-8)',$file or die "R73 缺少 $path\n";
 local $/;my $text=<$fh>;close $fh;return $text;
}
my $code=source('tools/audit_r73_prefix_partition.pl');
my $guard=source('tools/profile_r73_prefix_partition.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $value (
 '84493','816161','4556227','18985221','65276665',
 'aa475e200df43fae9f912003cd5799a08d756b14a8652947d4e64a106442b2b3',
 '62524d0c43078bdc5836406ebdb71646ea617cc02615287a2949d2c0844942dd',
 '9081e5cf00e2249317f71a07574bb5d9fb5f8bd40f0ebd53b70ab9c1746a903c',
 'e94f0ea563a1489db7cbf13bd9ea79a92f79dbf9f0f8fcad590ed897f1ac1c39',
 '79112d59ca0e0f25cfe6ca7eb7d63e79ed42ba61a9ce8d8ebc346cad6d809d04'
) {
 ok(index($code,$value)>=0,"R73 外部固定的獨立基線：$value");
}
like($code,qr/for my \$b \(1\.\.5\)/,'分片第二個月全部 1..5');
like($code,qr/for my \$c \(1\.\.5\)/,'分片第三個月全部 1..5');
like($code,qr/for my \$d \(1\.\.5\)/,'分片第四個月全部 1..5');
like($code,qr/\$sum!=\$ways/,'每個真實節點驗證合法孩子分割');
like($code,qr/\$cursor!=\$end->copy->badd\(1\)/,
 '每個節點的所有子區間必須按序緊密覆蓋');
like($code,qr/\$rf!=\$start/,'原生排名須等於真實字典序左端');
like($code,qr/\$rl!=\$end/,'原生排名須等於真實字典序右端');
like($code,qr/\$memo_answer!=\$ways/,'葉節點的另一 memo Oracle 完工數必須一致');
like($code,qr/\$endpoint_checks!=\$total_nodes\*4/,
 '所有前綴節點均需四次原生 rank/unrank');
like($code,qr/\$memo_checks!=\$nodes\[0\]\+\$nodes\[4\]/,
 '全部根和第四層的 memo cross-check 不可漏驗');
for my $shard (1..5) {
 my @job=($ci =~ /^  canonical-r73-prefix-partition-\Q$shard\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
 is(scalar(@job),1,"R73 shard $shard 一份獨立 Native 工作");
 next unless @job==1;
 like($job[0],qr/\[weaving-r73-prefix-partitions\]/,"R73 shard $shard 顯式 opt-in");
 like($job[0],qr/timeout-minutes:\s*5\b/,"R73 shard $shard GitHub 五分鐘限額");
 like($job[0],qr/--shard \Q$shard\E --seconds 185 --rss-kib 393216/,
      "R73 shard $shard Perl 185s/393216KiB 硬界線");
 like($job[0],qr/set -euo pipefail/,"R73 shard $shard 失敗不吞");
}
like($guard,qr/waitpid\(\$pid,WNOHANG\)/,'子程序由獨立父程序監督');
like($guard,qr/\$rss>\$rss_limit/,'RSS 超限不通過');
like($guard,qr/\$elapsed>\$seconds/,'walltime 超限不通過');
like($guard,qr/exit 3;/,'資源阻擋使用非零碼');
done_testing;
