use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha512_hex);
use FindBin qw($Bin);
use File::Spec;
sub contents ($name) {
    my $file=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $f,'<:encoding(UTF-8)',$file or die "無法讀取 $name\n";
    local $/;my $txt=<$f>;close $f;return $txt;
}
my $src=contents('tools/profile_canonical_memo_multi_ranks.pl');
my $ci=contents('.github/workflows/canonical-names-lock.yml');
my @known=(
    [38,0,'cc14f78969a73237112e'],
    [38,6,'e3af7ee683a0d0b61e31'],
    [39,0,'a5d27edc3a3478ec8599'],
    [39,6,'8c44dd90e4fce4016aac'],
);
for my $p (@known) {
    my ($offset,$index,$digest_prefix)=@$p;
    is(substr(sha512_hex(
        "PASTAFARIAN-5000-FOURMONTH-$offset-R56:$index"
    ),0,20),$digest_prefix,
       "第 $offset 窗樣本 $index 的 SHA-512 摘要與獨立已知值一致");
}
like($src,qr/\$case_filter\s*=~\s*\/\\Ahash\(38\|39\)-\(\[ab\]\)\\z\//,
     '只有窗口 38 或 39 的兩個半組可以啟動');
like($src,qr/\$specified_offset\s*!=\s*\$offset/,
     '不能將真實 38 月份排名誤套到 39 或相反');
like($src,qr/PASTAFARIAN-5000-FOURMONTH-\$offset-R56:\$index/,
     'R56 與既有 R55 SHA-512 種子域確實分離');
like($src,qr/\$seen\{"\$rank"\}\+\+/,
     '每窗口十二個完整 BigInt 位置均強制不同');
like($src,qr/\$sum\s*!=\s*\$parent/,
     '每一天獨立前綴的所有合法子分支數必須總和吻合');
like($src,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '每一天所有 BigInt 字典序都與磁碟索引排名器逐字對照');
my (@jobs,%names);
for my $offset (38,39) {
    for my $half (qw(a b)) {
        my $id="$offset-$half";
        my @j=($ci =~ /^  canonical-fourmonth-r56-\Q$id\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
        is(scalar(@j),1,"窗口 $id 只有一個固定原生 CI 分片");
        next if @j!=1;
        like($j[0],qr/\[weaving-fourmonth-hash24\]/,"$id 必須 opt-in");
        like($j[0],qr/timeout-minutes:\s*5\b/,"$id 保留 GitHub 五分鐘限制");
        like($j[0],qr/set -euo pipefail/,"$id 數學失敗強制 nonzero");
        like($j[0],qr/--window-offset $offset --case-filter hash\Q$id\E --seconds 185 --rss-kib 393216/,
             "$id 每一工作維持原有時間／RSS");
        push @jobs,$id;$names{$id}++;
    }
}
is_deeply(\@jobs,[qw(38-a 38-b 39-a 39-b)],
     '兩個相鄰四月窗口每個各六名次兩組，恰好 24 名次');
ok(!(grep {$_!=1} values %names),'無多餘或遺漏的 CI 工作');
done_testing;
