use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;

# 在原生 Linux CI 使用一秒封頂真正的 252 日 BigInt 工具，
# 而不是藉由虛構 stdout 假裝測過 BLOCKED 路徑。
if ($^O ne 'linux' || !-r '/proc/self/status') {
    plan skip_all => '需要 Linux /proc 的原生資源監督';
}
my $script='tools/profile_indexed_rank_roundtrip.pl';
ok(-f $script,'被測的 47 月份索引式驗證工具存在');
open my $pipe,'-|',$^X,'-Ilib','-It/lib',$script,
    '--seconds','1','--rss-kib','262144'
    or die "無法啟動索引式封頂路徑：$!\n";
my $output=do { local $/; <$pipe> } // '';
close $pipe;
my $status=$?;
cmp_ok(($status >> 8),'==',3,'時間 BLOCKED 返回非成功的專用退出碼 3');
like($output,qr/INDEXED_ROUNDTRIP status=BLOCKED reason=TIME_LIMIT/,
     '確定由真實一秒時間封頂而非演算法錯誤中止');
like($output,qr/INDEXED_ROUNDTRIP_CHECK_COMPLETE passed=0 blocked=1 failed=0/,
     '既有監督摘要保留 BLOCKED 與 PASS 的清楚區別');
unlike($output,qr/INDEXED_ROUNDTRIP status=PASS/,
       'BLOCKED 路徑不得同時輸出任何虛假 PASS');
done_testing;
