use v5.40;
use utf8;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha512_hex);
use FindBin qw($Bin);
use File::Spec;
sub readfile ($name) {
    my $p=File::Spec->catfile($Bin,'..',split('/',$name));
    open my $h,'<:encoding(UTF-8)',$p or die "無法讀取 $name\n";
    local $/;
    my $s=<$h>;close $h;return $s;
}
my $source=readfile('tools/profile_canonical_memo_multi_ranks.pl');
my $wf=readfile('.github/workflows/canonical-names-lock.yml');
for my $case ([0,'9f870733c45691f8f2d4'],
              [5,'de300a8a2738fcefa50b'],
              [6,'f4d8508fd57b58f2e07f'],
              [11,'e812872ad514560e45c8']) {
    my ($n,$prefix)=@$case;
    is(substr(sha512_hex("PASTAFARIAN-5000-FOURMONTH-37-R55:$n"),0,20),
       $prefix,"SHA-512 種子 $n 與獨立公開摘要值一致");
}
like($source,qr/use Digest::SHA qw\(sha256_hex sha512_hex\)/,
     '新抽取序列確實使用 SHA-512 的 512 位元全摘要');
like($source,qr/Math::BigInt->from_hex\("0x\$digest"\)\s*->bmod\(\$total\)->badd\(1\)/,
     '512 位 BigInt 對完整 N 取模，並形成 1..N 名次');
like($source,qr/\$observed\{"\$rank"\}\+\+/,
     '十二個樣本有明確去重防護，不能無聲漏驗');
like($source,qr/\@hash_samples\[0\.\.5\]/,
     '前六個名次的固定抽取區間');
like($source,qr/\@hash_samples\[6\.\.11\]/,
     '後六個名次的固定抽取區間');
like($source,qr/\$sum\s*!=\s*\$parent/,
     '每一天合法後繼的精確 BigInt 和核對');
like($source,qr/\$chosen\s*!=\s*\$word->\[\$day-1\]/,
     '每一天必須比對獨立名次和索引式反排名');
my @jobs;
for my $case (qw(hash-a hash-b)) {
    my @found=($wf =~ /^  canonical-window37-r55-\Q$case\E:[^\n]*\n(.*?)(?=^  [A-Za-z][\w-]*:|\z)/msg);
    is(scalar(@found),1,"$case 僅有一個 native job");
    next unless @found==1;
    my $body=$found[0];
    like($body,qr/\[weaving-window37-hash12\]/,
         "$case 工作 opt-in 標記獨立");
    like($body,qr/timeout-minutes:\s*5\b/,
         "$case 不放寬 GitHub 整體硬限制");
    like($body,qr/set -euo pipefail/,
         "$case 仍將子驗證器失敗傳播至 GitHub");
    like($body,qr/--window-offset 37 --case-filter \Q$case\E --seconds 185 --rss-kib 393216/,
         "$case 保留 185 秒與 393216 KiB RSS");
    push @jobs,$case;
}
is_deeply(\@jobs,[qw(hash-a hash-b)],'兩個互補六樣本工作均存在');
done_testing;
