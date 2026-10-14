use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);

# 直接從引擎契約核對首／末字序貪婪快速路徑：
# 不建索引是預期優化，不應被「必須建立索引」的測試誤判。
for my $lengths ([2,3,2],[3,2,4],[3,3,3]) {
    my $total=countWeavingsPolynomial($lengths);
    ok($total>3,'三月樣本至少有首／中／末不同排名');
    for my $case (
        ['first',Math::BigInt->bone,'first_rank_fastpath'],
        ['last',$total->copy,'last_rank_fastpath'],
    ) {
        my ($name,$rank,$flag)=@$case;
        my %stats;
        my $word=unrankWeavingPolynomial(
            $lengths,$rank,\%stats,
            {profile_engine=>'stream-indexed',max_temp_file_bytes=>1048576}
        );
        is($stats{$flag}//0,1,
            "$name: 原生反排名器明確標示邊界捷徑");
        is($stats{indexed_profile_builds}//0,0,
            "$name: 邊界捷徑沒有建不必要的索引");
        my %rank_stats;
        my $back=rankWeavingPolynomial(
            $lengths,$word,\%rank_stats,
            {profile_engine=>'stream-indexed',max_temp_file_bytes=>1048576}
        );
        is("$back","$rank","$name: 正向排名精確還原原始一基 BigInt");
        is($rank_stats{candidates}//0,0,
            '首名不計較小候選')
            if $name eq 'first';
        is($rank_stats{indexed_profile_builds}//0,0,
            '首名正向排名不建立索引')
            if $name eq 'first';
    }
    my %middle_stats;
    my $middle=$total->copy->bdiv(2)->badd(1);
    my $decoded=unrankWeavingPolynomial(
        $lengths,$middle,\%middle_stats,
        {profile_engine=>'stream-indexed',max_temp_file_bytes=>1048576}
    );
    is($middle_stats{first_rank_fastpath}//0,0,
       '內部中位沒有誤用首名快速路徑');
    is($middle_stats{last_rank_fastpath}//0,0,
       '內部中位沒有誤用末名快速路徑');
    is("".rankWeavingPolynomial($lengths,$decoded),"$middle",
       '中間排名仍可完整還原');
}
done_testing;
