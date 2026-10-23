use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
sub source ($path) {
 my $file=File::Spec->catfile($Bin,'..',split('/',$path));
 open my $fh,'<:encoding(UTF-8)',$file or die "R70 找不到 $path\n";
 local $/;my $text=<$fh>;close $fh;return $text;
}
my $audit=source('tools/audit_r70_permutation_mirror.pl');
my $guard=source('tools/profile_r70_permutation_mirror.pl');
my $ci=source('.github/workflows/canonical-names-lock.yml');
for my $text ('a25ac18f972ade732c44f4e672a22f03f5b98b5bd16d979a58bfddb97c6c26be',
  '25513687727559962223774','28434255912845240954002',
  '22091572533315142223392') {
 ok(index($audit,$text)>=0,"R70 固定 24 排列的哈希／精確 BigInt 值存在");
}
like($audit,qr/if keys\(%unique\)!=12/,
    '24 排列有 12 個不同的 BigInt 總數');
like($audit,qr/my \@mirror=map \{5-\$_\} reverse \@\$word/,
    '真正反轉詞並交換月份標籤，不使用任何排名函式構造');
like($audit,qr/independently_rank\(\\\@reverse,\$rev,\\\@mirror\)/,
    '反轉詞以獨立 DFS 數前方子樹重建排名');
like($audit,qr/rankWeavingPolynomial\(\\\@reverse,\\\@mirror\)/,
    '交叉檢查受測反向排名');
like($audit,qr/countWeavingsPolynomial\(\$lengths\)/,
    '24 排列需與不同位置多項式對照');
like($audit,qr/early_final_closed_form=>1/,
    '有界 CLOCK 實際 opt-in 早期末次序閉式');
for my $shard (0..3) {
 my @jobs=($ci =~ /^  canonical-r70-permutation-shard-\Q$shard\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
 is(scalar(@jobs),1,"R70 shard $shard 恰好一份");
 next unless @jobs==1;
 like($jobs[0],qr/\[weaving-r70-mirror-permutations\]/,
      "R70 shard $shard 特殊標記 opt-in");
 like($jobs[0],qr/timeout-minutes:\s*5\b/,
      "R70 shard $shard 五分鐘外部上限");
 like($jobs[0],qr/--shard \Q$shard\E --seconds 185 --rss-kib 393216/,
      "R70 shard $shard 原生限時及 RSS");
 like($jobs[0],qr/set -euo pipefail/,"R70 shard $shard 不吞非零狀態");
}
like($guard,qr/waitpid\(\$pid,WNOHANG\)/,'父進程監督子程序終止');
like($guard,qr/\$rss>\$rss_limit/,'母進程檢查 RSS');
like($guard,qr/\$elapsed>\$seconds/,'母進程檢查時間');
like($guard,qr/exit 3;/,'超出界線保留為 BLOCKED');
done_testing;
