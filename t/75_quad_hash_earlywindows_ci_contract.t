use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha512_hex);
use FindBin qw($Bin);
use File::Spec;
sub source_text ($file) {
    my $full=File::Spec->catfile($Bin,'..',split('/',$file));
    open my $handle,'<:encoding(UTF-8)',$full or die "無法讀取 $file：$!\n";
    local $/;
    my $body=<$handle>;close $handle;return $body;
}
my $tool=source_text('tools/profile_canonical_memo_multi_ranks.pl');
my $workflow=source_text('.github/workflows/canonical-names-lock.yml');
for my $case (
    [34,0,'6939993df540d0860bfeaf96'],
    [34,5,'aaebad17fa3c6941f1107e0a'],
    [34,6,'bfe86a30baa0e73aa57fab45'],
    [34,11,'bc35b707fb75c68bed5ed143'],
    [36,0,'12a7dbb11b2948714cc85b52'],
    [36,5,'b6a34b75649e6929c93bc24e'],
    [36,6,'885767e15f0c1ab403d82970'],
    [36,11,'0960678a131fb39870384fa1'],
) {
    my ($offset,$i,$digest)=@$case;
    is(substr(sha512_hex("PASTAFARIAN-5000-FOURMONTH-$offset-R58:$i"),0,24),
       $digest,"第 $offset 窗第 $i 個 SHA-512 獨立已知摘要片段");
}
like($tool,qr/\$offset==34\s*\?\s*'81,54,101,83'/,
     '第 34 個真實四月窗口固定為 319 日');
like($tool,qr/\$offset==36\s*\?\s*'101,83,88,40'/,
     '第 36 個真實四月窗口固定為 312 日');
like($tool,qr/\$offset==37\s*\?\s*'83,88,40,25'/,
     '既有第 37 窗及後續月長不變');
like($tool,qr/\$case_filter\s*=~\s*\/\\Ahash\(34\|36\)-\(\[ab\]\)\\z\//,
     'R58 僅接受兩個明列窗口的互補分組');
like($tool,qr/PASTAFARIAN-5000-FOURMONTH-\$offset-R58:\$index/,
     'R58 種子與 R55、R56、R57 嚴格域分離');
like($tool,qr/\$seen\{"\$rank"\}\+\+/,
     'R58 十二個 BigInt 排名必須不重複');
like($tool,qr/\$sum\s*!=\s*\$parent/,
     '所有合法後繼 BigInt 數量和必須等於父前綴');
like($tool,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '每一天需與索引式反排名的字元完全一致');
my @seen;
for my $offset (34,36) {
    for my $half (qw(a b)) {
        my @matches=($workflow =~ /^  canonical-fourmonth-r58-\Q$offset\E-\Q$half\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
        is(scalar(@matches),1,"窗口 $offset 分組 $half 只有一份原生 CI");
        next unless @matches==1;
        my $job=$matches[0];
        like($job,qr/\[weaving-fourmonth-r58-hash24\]/,
             'R58 的 opt-in 提交標記不觸發舊工作');
        like($job,qr/timeout-minutes:\s*5\b/,
             'GitHub 原生工作總額不超過五分鐘');
        like($job,qr/set -euo pipefail/,
             'FAIL / BLOCKED 必須傳到整個工作結果');
        like($job,qr/--window-offset $offset --case-filter hash$offset-$half --seconds 185 --rss-kib 393216/,
             '單獨 Oracle 仍維持原有 185 秒與 393216 KiB RSS');
        push @seen,"$offset-$half";
    }
}
is_deeply(\@seen,[qw(34-a 34-b 36-a 36-b)],
          '兩窗口各六個 BigInt 排名全部唯一列入四個 CI 工作');
done_testing;
