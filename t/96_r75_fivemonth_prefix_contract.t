use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub read_source ($file) {
 my $path=File::Spec->catfile($Bin,'..',split('/',$file));
 open my $f,'<:encoding(UTF-8)',$path or die "R75 缺少 $file\n";
 local $/;my $text=<$f>;close $f;return $text;
}
my $code=read_source('tools/audit_r75_fivemonth_prefix_tree.pl');
my $guard=read_source('tools/profile_r75_fivemonth_prefix_tree.pl');
my $ci=read_source('.github/workflows/canonical-names-lock.yml');
unlike($code,qr/WeavingMemoOracle/,'五個月份禁止調用四月 Oracle');
unlike($code,qr/for my \$b \(/,'不能遮蔽 Perl sort 比較器特殊變數');
like($code,qr/sub walk_prefix/,'須走遍全部合法深度前綴');
like($code,qr/\$sum!=\$ways/,'每個合法前綴的孩子完工數等於父前綴');
like($code,qr/\$cursor!=\$end->copy->badd\(1\)/,'孩子區間完全且連續');
like($code,qr/rankWeavingPolynomial\(\$L,\$low\)/,'驗證精確左端 rank');
like($code,qr/rankWeavingPolynomial\(\$L,\$high\)/,'驗證精確右端 rank');
like($code,qr/\$w=unrankWeavingPolynomial\(\$L,\$n\)/,'逐個排除區間外相鄰詞');
like($code,qr/\$checks!=\$n\*4/,'全部前綴端點接受四次原生交叉檢驗');
for my $a (1..3) {
 for my $b (1..3) {
  my @jobs=($ci =~ /^  canonical-r75-fivemonth-prefix-\Q$a\E-\Q$b\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
  is(scalar(@jobs),1,"R75 $a,$b 只有一份 Native 分片");
  next unless @jobs==1;
  like($jobs[0],qr/\[weaving-r75-fivemonth-prefix\]/,"R75 $a,$b opt-in 標記");
  like($jobs[0],qr/timeout-minutes:\s*5\b/,"R75 $a,$b 工作硬限時");
  like($jobs[0],qr/--first \Q$a\E --second \Q$b\E --seconds 185 --rss-kib 393216/,
      "R75 $a,$b 真正原生資源上限");
  like($jobs[0],qr/set -euo pipefail/,"R75 $a,$b 不隱藏退出碼");
 }
}
like($guard,qr/waitpid\(\$pid,WNOHANG\)/,'獨立父程序監督');
like($guard,qr/\$rss>\$limit/,'真正 RSS 上限');
like($guard,qr/\$elapsed>\$seconds/,'真正 walltime 上限');
like($guard,qr/exit 3;/,'BLOCKED 不等於 PASS');
done_testing;
