use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Digest::SHA qw(sha256_hex);
use lib 'lib','t/lib';
use Pastafari::NormativeScroll qw(countWeavings unrankWeaving);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 只做 Stage 1 的可重現稽核。
# 這個實測快照由 year5000 + sauce + 規範月份選擇器取得，
# 非另造月份假裝為規範年份；亦不是正式曆法的生產輸出。
# 獨立的受控流程每次可以重新生成相同 SHA-256。
my @selected = (
    115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
    97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
    97,50,122,110,81,54,101,83,88,40,25,77,98,122,105
);
my $signature='6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134';
is(scalar(@selected),45,'已由真實年份選擇器量得的月份數為 45');
my $total=0; $total+=$_ for @selected;
is($total,4244,'實測月份總日數吻合規範錨定年');
is(sha256_hex(join(',',@selected)),$signature,'45 月份原生證據摘要完全一致');
ok(!grep({$_<4 || $_>123} @selected),'每個規範月份長度均在 4..123');
is(join(',',@selected[0,1,2]),'115,108,119','原生規範年份前三月保持相同');
is(join(',',@selected[42,43,44]),'98,122,105','原生規範年份末三月保持相同');

# 在同一固定真實月長樣本上，挑選較長、一般、中間極端短月、
# 及年份末端四種彼此不同的三月視窗。
my @windows = (
    ['first',0],
    ['middle',23],
    ['short',39],
    ['last',42],
);
for my $case (@windows) {
    my ($name,$offset)=@$case;
    my @L=@selected[$offset .. $offset+2];
    my $reference=countWeavings(\@L);
    my $polynomial=countWeavingsPolynomial(\@L);
    is("$polynomial","$reference","$name: 多項式精確總數符合獨立規範計數");
    my $middle=$reference->copy->bdiv(2)->badd(1);
    ok($middle>1 && $middle<$reference,"$name: 中間一基排名合法且非邊界");
    my $immutable_rank="$middle";
    my $oracle=unrankWeaving(\@L,$middle);
    my %decode;
    my $unranked=unrankWeavingPolynomial(
        \@L,$middle,\%decode,
        {profile_engine=>'stream-indexed',max_temp_file_bytes=>8*1024*1024}
    );
    is_deeply($unranked,$oracle,"$name: 真實三月中間字典序與獨立規範 Oracle 一致");
    is($decode{indexed_profile_builds}//0,1,
       "$name: 反排名確實建立一份私人磁碟索引");
    my %rank;
    my $back=rankWeavingPolynomial(
        \@L,$unranked,\%rank,
        {profile_engine=>'stream-indexed',max_temp_file_bytes=>8*1024*1024}
    );
    is("$back",$immutable_rank,"$name: 正向 BigInt 排名重建原始中間排名");
    is($rank{indexed_profile_builds}//0,1,
       "$name: 正向排名另外建立自己的私人磁碟索引");
    is("$middle",$immutable_rank,"$name: 原始 BigInt 排名未遭修改");
    is(scalar(@$unranked),$L[0]+$L[1]+$L[2],
       "$name: 反排名得到完整三月日序列");
}
done_testing;
