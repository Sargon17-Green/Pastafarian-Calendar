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

my @cases=(
    [[2,2,2],[1,2]],
    [[3,3,3,3],[1,2,3,2]],
    [[4,4,4,4,4,4],[1,2,3,1,2]],
    [[(4)x47],[1,2,3]],
    [[(6)x17,(5)x30],[1,2,3,1]],
);
for my $case (@cases) {
    my ($lengths,$prefix)=@$case;
    my %shared;
    my %resident_stats;
    my $resident=countWeavingSuffixFactored($lengths,$prefix,
                                             \%shared,\%resident_stats);
    my %disk_stats;
    my $disk=countWeavingSuffixFactored($lengths,$prefix,
                            \%shared,\%disk_stats,{profile_engine=>'stream'});
    my $old=countWeavingSuffixPolynomial($lengths,$prefix);
    is("$disk","$resident",'磁碟/記憶體後綴精確 BigInt 完全相等');
    is("$disk","$old",'磁碟後綴與規範前綴完整計數相等');
    is($resident_stats{profile_builds},1,'常駐模型建立專屬反序分布');
    is($disk_stats{profile_disk_builds},1,'磁碟模型建立另一份反序分布');
    is($disk_stats{profile_builds},1,'兩種引擎互不污染同一共享快取');
    cmp_ok($disk_stats{profile_rows_serialized},'>',0,
        '磁碟模型真正寫出暫存列');
    cmp_ok($disk_stats{profile_max_temp_file_bytes},'>',0,
        '記錄實際暫存檔最大空間');
    my %hit_stats;
    my $again=countWeavingSuffixFactored($lengths,$prefix,
                   \%shared,\%hit_stats,{profile_engine=>'stream'});
    is("$again","$resident",'共享磁碟快取命中值不變');
    is($hit_stats{future_cache_hits},1,'同一預算重用完整未開啟因子');
    ok(!exists($hit_stats{profile_builds}),'命中既有快取無須重建');
}

my @lengths=(4,4,4,4);
my %cache;
countWeavingSuffixFactored(\@lengths,[1,2,3],\%cache);
my $bad=eval {
    countWeavingSuffixFactored(\@lengths,[1,2,3],\%cache,undef,
              {profile_engine=>'stream',max_temp_file_bytes=>48});
    1;
};
ok(!$bad,'小磁碟預算不得命中不同引擎的已建快取');
like($@,qr/暫存檔超過容量限制/,
    '預算失敗必須來自實際磁碟模型');
my %disk_first;
countWeavingSuffixFactored(\@lengths,[1,2,3],\%cache,\%disk_first,
     {profile_engine=>'stream',max_temp_file_bytes=>1048576});
ok($disk_first{profile_disk_builds},'增加磁碟預算後可以獨立建立分布');
my $failed_low=eval {
    countWeavingSuffixFactored(\@lengths,[1,2,3],\%cache,undef,
         {profile_engine=>'stream',max_temp_file_bytes=>48});
    1;
};
ok(!$failed_low,'已快取的大預算不會繞過小預算的限制');

for my $invalid (
    {profile_engine=>'foo'},
    {profile_engine=>'resident',max_temp_file_bytes=>2048},
    {profile_engine=>'stream',max_temp_file_bytes=>0},
    {profile_engine=>'stream',max_temp_file_bytes=>'3MiB'},
    {profile_engine=>'stream',max_temp_file_bytes=>1073741825},
    {unknown=>1},
) {
    my $ok=eval{ countWeavingSuffixFactored([2,2],[1],undef,undef,
                         $invalid);1 };
    ok(!$ok,'明確拒絕非法引擎或磁碟預算選項');
}
my @big=(Math::BigInt->new(4),Math::BigInt->new(4));
my @before=map {"$_"} @big;
is(''.countWeavingSuffixFactored(\@big,[1],undef,undef,
         {profile_engine=>'stream'}),
   ''.countWeavingSuffixPolynomial(\@big,[1]),
   'BigInt 月份輸入在磁碟模式仍保持精確');
is_deeply([map {"$_"} @big],\@before,'不修改來源月份長度');
done_testing;
