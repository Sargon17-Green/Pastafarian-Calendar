use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingProfileDisk qw(buildWeavingProfileDisk);

my $cases=0;
for my $lengths ([1],[1,1],[2,3],[2,2,2],[3,2,3,2],
                 [4,4,4,4],[(4)x8],[(4)x47],
                 [(6)x17,(5)x30]) {
    my @expected;
    my $reference=countWeavingsPolynomial($lengths,undef,\@expected);
    my $store=buildWeavingProfileDisk($lengths,16_777_216);
    my $stats=$store->diagnostics;
    is(''.$store->total,"$reference",
        '磁碟直方圖索引與常駐模型精確總數一致');
    is($stats->{stages},scalar(@$lengths),
        '磁碟索引階段數與月份數一致');
    if (@$lengths) {
        cmp_ok($stats->{spool_bytes},'>',0,'已在磁碟保存索引資料');
    }
    my @stages=(1,scalar(@$lengths),2,2,scalar(@$lengths),scalar(@$lengths));
    for my $stage (@stages) {
        next if $stage<1 || $stage>@$lengths;
        my $hist=$store->histogram($stage);
        my $sum=0;$sum+=$_ for @$lengths[0 .. $stage-1];
        for my $u (1 .. $sum) {
            is(''.($hist->[$u]//0),''.($expected[$stage][$u]//0),
               '按索引亂序讀取的首次位置 BigInt 完全一致');
        }
        for my $value (@$hist) {
            next if !defined($value);
            $value->badd(7);
            last;
        }
        my $repeat=$store->histogram($stage);
        for my $u (1 .. $sum) {
            is(''.($repeat->[$u]//0),''.($expected[$stage][$u]//0),
               '呼叫者修改讀取副本不會污染後續索引');
        }
    }
    if (@$lengths > 1) {
        my $detail=$store->diagnostics;
        cmp_ok($detail->{histogram_reads},'>=',2,
            '跨階段讀取會從實際索引取值');
        cmp_ok($detail->{histogram_hits},'>=',1,
            '連續重複階段使用單一階段的快取');
    }
    $cases++;
}
is($cases,9,'九組月份分布含 47 個月份／252 日');

my $ok=eval{buildWeavingProfileDisk([4,4,4],1);1};
ok(!$ok,'極小直方圖暫存預算明確失敗');
like($@,qr/暫存檔超過容量限制/,
     '磁碟預算錯誤不會被誤判成功');
for my $invalid (undef,0,'12MB',1_073_741_825,[]) {
    my $good=eval{buildWeavingProfileDisk([2,2],$invalid);1};
    ok(!$good,'拒絕無效的磁碟預算');
}
my $single=buildWeavingProfileDisk([2,2]);
for my $bad (0,3,'banana',[],undef) {
    $ok=eval{$single->histogram($bad);1};
    ok(!$ok,'拒絕無效階段查詢');
    like($@,qr/範圍內整數/,'提供明確的索引階段錯誤');
}
my $first=$single->total;
$first->badd(12345);
is(''.$single->total,''.countWeavingsPolynomial([2,2]),
   '總數回傳值具有獨立 BigInt 所有權');
done_testing;
