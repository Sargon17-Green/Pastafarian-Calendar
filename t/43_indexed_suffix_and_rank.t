use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

my $cases=0;
for my $lengths ([2,2,2],[3,3,3],[4,4,4,4],[(4)x8],
                 [(4)x47],[(6)x17,(5)x30]) {
    # 留下至少一個尚未首次出現的月份，強制真正建表。
    my @prefix=(1,2);
    my %cache;
    my %resident_stats;
    my $resident=countWeavingSuffixFactored($lengths,\@prefix,
                                  \%cache,\%resident_stats);
    my %indexed_stats;
    my $indexed=countWeavingSuffixFactored($lengths,\@prefix,
                                  \%cache,\%indexed_stats,
                                  {profile_engine=>'stream-indexed'});
    my %disk_stats;
    my $stream=countWeavingSuffixFactored($lengths,\@prefix,
                                  \%cache,\%disk_stats,
                                  {profile_engine=>'stream'});
    is("$indexed","$resident",'索引／常駐後綴計數完全相等');
    is("$indexed","$stream",'索引／全部直方圖串流計數完全相等');
    is("$indexed",''.countWeavingSuffixPolynomial($lengths,\@prefix),
       '索引後綴和原始前綴規範模型相等');
    is($indexed_stats{profile_indexed_builds},1,
       '分階段二進位索引真正建構一次');
    is($indexed_stats{profile_builds},1,'全部前綴使用同一構造批次');
    cmp_ok($indexed_stats{profile_spool_bytes},'>',0,
       '分階段二進位索引使用暫存磁碟');
    my %hits;
    is(''.countWeavingSuffixFactored($lengths,\@prefix,\%cache,\%hits,
                  {profile_engine=>'stream-indexed'}),"$resident",
       '索引引擎的既有前綴結果能被重用');
    is($hits{future_cache_hits},1,'相同引擎相同磁碟預算命中');
    $cases++;
}
is($cases,6,'不同月數及 47 月份兩個向量全部核對');

my @lengths=(4,4,4,4);
my %shared;
countWeavingSuffixFactored(\@lengths,[1,2,3],\%shared);
my $bad=eval {
    countWeavingSuffixFactored(\@lengths,[1,2,3],\%shared,undef,
        {profile_engine=>'stream-indexed',max_temp_file_bytes=>1});
    1
};
ok(!$bad,'不能用 resident 快取繞過索引磁碟預算');
like($@,qr/暫存檔超過容量限制/,
    '索引預算失敗具明確的資源原因');
my %big;
countWeavingSuffixFactored(\@lengths,[1,2,3],\%shared,\%big,
        {profile_engine=>'stream-indexed',max_temp_file_bytes=>1048576});
is($big{profile_indexed_builds},1,'較大獨立預算可建立索引');
$bad=eval {
    countWeavingSuffixFactored(\@lengths,[1,2,3],\%shared,undef,
        {profile_engine=>'stream-indexed',max_temp_file_bytes=>1});
    1
};
ok(!$bad,'大預算的既有索引不能繞過小預算');

my $count=0;
for my $lengths ([2,2,2],[3,3,3],[4,4,4,4],[(4)x8]) {
    my $maximum=countWeavingsPolynomial($lengths);
    my @rank=(1,2,$maximum->copy->bdiv(2)->badd(1),$maximum);
    my %seen;
    for my $rank (@rank) {
        next if $rank<1 || $rank>$maximum || $seen{"$rank"}++;
        my $original="$rank";
        my %unrank_stats;
        my $got=unrankWeavingPolynomial($lengths,$rank,\%unrank_stats,
                           {profile_engine=>'stream-indexed'});
        is_deeply($got,unrankWeaving($lengths,$rank),
                 '索引式反排名保持原始規範字典序');
        my %rank_stats;
        my $back=rankWeavingPolynomial($lengths,$got,\%rank_stats,
                           {profile_engine=>'stream-indexed'});
        is("$back",$original,'索引式精確回推原始 BigInt 一基排名');
        if ($unrank_stats{suffix_calls}) {
            is($unrank_stats{indexed_profile_builds},1,
               '反排名每次只建立一份索引');
            cmp_ok($unrank_stats{indexed_spool_bytes},'>',0,
               '反排名的私有索引確實寫入磁碟');
        }
        if ($rank_stats{candidates}) {
            is($rank_stats{indexed_profile_builds},1,
               '正向排名也獨立建立其私有索引');
        }
        $count++;
    }
}
cmp_ok($count,'>=',11,'小空間中位和邊界的雙向字典序核對');

for my $invalid ({profile_engine=>'invalid'},
                 {profile_engine=>'stream-indexed',max_temp_file_bytes=>0},
                 {profile_engine=>'stream-indexed',max_temp_file_bytes=>'bad'},
                 {profile_engine=>'resident',max_temp_file_bytes=>100}) {
    my $ok=eval{unrankWeavingPolynomial([2,2],1,undef,$invalid);1};
    ok(!$ok,'首名貪婪路徑仍嚴格驗證索引式選項');
}
done_testing;
