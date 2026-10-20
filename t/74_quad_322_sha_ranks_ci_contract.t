use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha512_hex);
use FindBin qw($Bin);
use File::Spec;

sub source ($path) {
    my $full=File::Spec->catfile($Bin,'..',split('/',$path));
    open my $h,'<:encoding(UTF-8)',$full or die "無法讀取：$path\n";
    local $/;
    my $body=<$h>;close $h;
    return $body;
}
my $script=source('tools/profile_canonical_memo_multi_ranks.pl');
my $workflow=source('.github/workflows/canonical-names-lock.yml');
for my $pair (
    [0,'9ceeaa01f2c211142c2f9507'],
    [5,'f048f32c7798d73c5106a9d0'],
    [6,'2201fee494567a3b3070f702'],
    [11,'301cceea3592cfb5b29b1be8'],
) {
    my ($i,$prefix)=@$pair;
    is(substr(sha512_hex("PASTAFARIAN-5000-FOURMONTH-40-R57:$i"),0,24),
       $prefix,"固定四月窗口第 $i 個 SHA-512 摘要未變");
}
like($script,qr/\$case_filter ne 'hash40-a' \&\& \$case_filter ne 'hash40-b'/,
     '只開啟新兩種正式選項而非任意未知 filter');
like($script,qr/\$case_filter =~ \/\\Ahash\(38\|39\|40\)-\(\[ab\]\)\\z\//,
     '原有兩個窗口的 SHA-512 case filter 不變');
like($script,qr/\$round=\$offset==40 \? 57 : 56;/,
     '第 40 窗使用完全獨立 R57 種子，舊窗口保持 R56');
like($script,qr/Math::BigInt->from_hex\("0x\$digest"\)\s*->bmod\(\$total\)->badd\(1\)/,
     '以完整 512 位 SHA 值模精確 BigInt 全部完工數加一');
like($script,qr/\$seen\{"\$rank"\}\+\+/,
     '十二個固定名次禁止重複');
like($script,qr/\$specified_offset!=\$offset/,
     '不能把第 40 窗的名次錯放到其它窗口');
like($script,qr/\$sum\s*!=\s*\$parent/,
     '所有 322 日的合法後繼 BigInt 和必須等於父前綴');
like($script,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '獨立 BigInt 前綴字序和索引解碼逐日一致');
my @slices;
for my $s (qw(a b)) {
    my @hits=($workflow =~ /^  canonical-fourmonth-r57-40-\Q$s\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@hits),1,"第 40 窗的 $s 六排名工作只可存在一次");
    next unless @hits==1;
    my $job=$hits[0];
    like($job,qr/\[weaving-fourmonth40-hash12\]/,
         '第 57 輪獨立觸發標記與歷史 R55/R56 隔離');
    like($job,qr/timeout-minutes:\s*5\b/,
         'GitHub 子工作仍為五分鐘硬上限');
    like($job,qr/set -euo pipefail/,
         '部分 FAIL 或 BLOCKED 不可被吞掉');
    like($job,qr/--window-offset 40 --case-filter hash40-\Q$s\E --seconds 185 --rss-kib 393216/,
         '保留 185 秒與 393216 KiB RSS 的原始每工作硬限制');
    push @slices,$s;
}
is_deeply(\@slices,[qw(a b)],'第 40 真實四月有互補十二名次的兩份完整原生 CI');
done_testing;
