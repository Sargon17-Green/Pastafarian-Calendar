use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha512_hex);
use FindBin qw($Bin);
use File::Spec;
sub src ($p) {
    my $path=File::Spec->catfile($Bin,'..',split('/',$p));
    open my $h,'<:encoding(UTF-8)',$path or die "無法讀取：$p\n";
    local $/;my $s=<$h>;close $h;return $s;
}
my $tool=src('tools/profile_canonical_memo_multi_ranks.pl');
my $wf=src('.github/workflows/canonical-names-lock.yml');
like($tool,qr/\$case_filter\s*=~\s*\/\\Ahash\(34\|36\)-\(0\[0-9\]\|1\[01\]\)\\z\//,
     '新工作只允許 34/36 窗口和 00..11 SHA-512 名次');
like($tool,qr/PASTAFARIAN-5000-FOURMONTH-\$offset-R58:\$i/,
     '所有單名次恰好沿用 R58 種子');
like($tool,qr/\@named=\(\$samples\[\$selected_index\]\)/,
     '每個獨立 job 只對照一條完整名次');
like($tool,qr/\$seen\{"\$rank"\}\+\+/,
     '仍全面檢查全部十二名次是否碰撞');
like($tool,qr/\$sum\s*!=\s*\$parent/,
     '任何一天精確合法分支總和不等於母前綴必須 FAIL');
like($tool,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '逐字按獨立 BigInt 排名和解碼比較');
my @offsets;
for my $off (34,36) {
    my @jobs=($wf =~ /^  canonical-fourmonth-r59-shard-$off:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@jobs),1,"窗口 $off 恰有一個固定 rank matrix 工作");
    next unless @jobs==1;
    my $body=$jobs[0];
    my @configs=($body =~ /^\s+index:\s*\[([^\]]+)\]/mg);
    is(scalar(@configs),1,"窗口 $off 僅一組 12 個 rank 名次");
    if (@configs==1) {
        my @indices=($configs[0] =~ /"(\d\d)"/g);
        is_deeply(\@indices,[map {sprintf('%02d',$_)} 0..11],
                  "窗口 $off 連續 00..11 不重複不漏");
    }
    like($body,qr/\[weaving-fourmonth-r59-shards\]/,
         '新 opt-in 不可再次啟動舊六名次 BLOCKED 工作');
    like($body,qr/fail-fast:\s*false/,
         '任何 shard FAIL 不取消其它原生名次證據');
    like($body,qr/timeout-minutes:\s*5\b/,
         '每個完整子工作 GitHub 最多五分鐘');
    like($body,qr/--window-offset $off --case-filter hash$off-\$\{\{ matrix\.index \}\} --seconds 185 --rss-kib 393216/,
         '185 秒與 393216 KiB RSS 上限完全未放寬');
    like($body,qr/set -euo pipefail/,'每個 FAIL 或 BLOCKED 必須回傳');
    push @offsets,$off;
}
is_deeply(\@offsets,[34,36],'二組各十二名次涵蓋全部 24 原名次');
done_testing;
