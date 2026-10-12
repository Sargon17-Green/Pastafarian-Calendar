use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingRank qw(rankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

my $samples=0;
for my $lengths ([2,2],[2,2,2],[3,3,3],[4,4,4],[4,4,4,4]) {
    my $total=countWeavingsPolynomial($lengths);
    my @ranks=(1,2,$total->copy->bdiv(2)->badd(1),$total->copy);
    my %seen;
    for my $rank (@ranks) {
        next if $rank<1 || $rank>$total || $seen{"$rank"}++;
        my @before=@$lengths;
        my $in="$rank";
        my %stats;
        my $disk=unrankWeavingPolynomial($lengths,$rank,\%stats,
                                         {profile_engine=>'stream'});
        my $default=unrankWeavingPolynomial($lengths,$rank);
        is_deeply($disk,$default,'磁碟與常駐解碼的月份次序相同');
        is_deeply($disk,unrankWeaving($lengths,$rank),
                  '磁碟解碼與獨立規範 Oracle 相同');
        my %rank_stats;
        my $restored=rankWeavingPolynomial($lengths,$disk,\%rank_stats,
                                           {profile_engine=>'stream'});
        is("$restored",$in,'串流反向排名精確還原原始一基排名');
        is_deeply($lengths,\@before,'不修改月份長度輸入');
        is("$rank",$in,'不修改輸入 BigInt 排名');
        if ($stats{suffix_calls}) {
            is($stats{stream_profile_builds},1,
               '實際使用串流後綴時僅構建一次反序分布');
            cmp_ok($stats{stream_rows_serialized},'>',0,
                   '實際使用磁碟暫存模型');
        }
        if ($rank_stats{candidates}) {
            is($rank_stats{stream_profile_builds},1,
               '反向排名的每一呼叫均擁有私有串流分布');
        }
        $samples++;
    }
}
cmp_ok($samples,'>=',14,'核對多個非極端排名與端點排名');

# 47 月份的非極端排名：實際走字典序反解與順序重建，
# 並檢查精確 BigInt 一基值；此處不是 5,778 日極限驗證。
my @large=(4)x47;
my $total=countWeavingsPolynomial(\@large);
my $rank=$total->copy->bdiv(2)->badd(1);
my %unrank_stats;
my $word=unrankWeavingPolynomial(\@large,$rank,\%unrank_stats,
                                 {profile_engine=>'stream'});
my %rank_stats;
my $back=rankWeavingPolynomial(\@large,$word,\%rank_stats,
                               {profile_engine=>'stream'});
is("$back","$rank",'47 月份 188 日以磁碟直方圖完成精確雙向往返');
is($unrank_stats{stream_profile_builds},1,
   '188 日非極端解碼只建立一次串流直方圖');
is($rank_stats{stream_profile_builds},1,
   '188 日反向排名重新建立獨立串流直方圖');

for my $opt (
    {profile_engine=>'invalid'},
    {profile_engine=>'resident',max_temp_file_bytes=>10},
    {profile_engine=>'stream',max_temp_file_bytes=>0},
    {profile_engine=>'stream',max_temp_file_bytes=>'two'},
    {other=>1}
) {
    my $ok=eval {
        unrankWeavingPolynomial([2,2],1,undef,$opt);
        1;
    };
    ok(!$ok,'第一名快速路徑不能避開引擎選項驗證');
    $ok=eval {
        unrankWeavingPolynomial([2,2],
              countWeavingsPolynomial([2,2]),undef,$opt);
        1;
    };
    ok(!$ok,'最後一名快速路徑不能避開引擎選項驗證');
    $ok=eval {rankWeavingPolynomial([2,2],[1,1,2,2],undef,$opt);1};
    ok(!$ok,'反向排名不接受非法引擎選項');
}
my $blocked=eval {
    unrankWeavingPolynomial([4,4,4,4],
        countWeavingsPolynomial([4,4,4,4])->copy->bdiv(2)->badd(1),
        undef,{profile_engine=>'stream',max_temp_file_bytes=>48});
    1;
};
ok(!$blocked,'解碼不能繞過磁碟暫存檔配額');
like($@,qr/暫存檔超過容量限制/,
     '解碼的超限原因可被確認');
done_testing;
