use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);

my $cases=0;
for my $lengths ([],[3],[1,1],[2,3],[2,2,2],[3,2,3],
                 [1,2,1,2],[2,3,2,3],[4,4,4,4],[(4)x8]) {
    my @original_hist;
    my $expected=countWeavingsPolynomial($lengths,undef,\@original_hist);
    my (%calls,@received,%stats);
    my $actual=countWeavingsPolynomialStream(
        $lengths,\%stats,undef,{max_temp_file_bytes=>1048576},
        sub ($stage,$histogram) {
            $calls{$stage}++;
            $received[$stage]=[map {defined($_) ? "$_" : undef} @$histogram];
        });
    is("$actual","$expected",'流式回呼不得變更精確全域 BigInt');
    is(scalar(keys %calls),scalar(@$lengths),
       '只有每個實際月份階段得到恰好一次回呼');
    is($stats{histogram_sink_calls},scalar(@$lengths),
       '診斷計數與接收的階段數完全一致');
    for my $stage (1 .. @$lengths) {
        is($calls{$stage},1,'每階段只接收一次');
        my $sum=0;
        $sum+=$_ for @$lengths[0 .. $stage-1];
        for my $u (1 .. $sum) {
            is(''.($received[$stage][$u]//0),
               ''.($original_hist[$stage][$u]//0),
               '逐階段首次位置 BigInt 與記憶體 Oracle 相等');
        }
    }
    $cases++;
}
is($cases,10,'十種不同月份分布包括空分布、單月份、八月份');

# 同時請求傳統的所有位置陣列及即時回呼，結果也不可不同。
my (@retained,%stats,@seen);
my @L=(3,2,4);
my $total=countWeavingsPolynomialStream(\@L,\%stats,\@retained,undef,
    sub ($stage,$hist) {$seen[$stage]=[map {defined($_) ? "$_" : undef} @$hist];});
is($stats{histogram_sink_calls},3,'雙重輸出模式每階段仍只回呼一次');
for my $stage (1 .. 3) {
    is_deeply([map {defined($_) ? "$_" : undef} @{$retained[$stage]}],
              $seen[$stage],'傳統和回呼雙輸出無差異');
}

# 回呼失敗必須向外拋出，不能被吞沒或誤報 PASS。
my $calls=0;
my $ok=eval {
    countWeavingsPolynomialStream([3,3,3],undef,undef,undef,
        sub ($stage,$hist) {
            $calls++;
            die "預定的接收器失敗\n" if $stage==2;
        });
    1
};
ok(!$ok,'接收器在第二階段失敗會中止計算');
like($@,qr/預定的接收器失敗/,'原始回呼失敗原因可追查');
is($calls,2,'沒有再執行後續階段');
for my $wrong ([],{},'callback',Math::BigInt->bone) {
    $ok=eval {
        countWeavingsPolynomialStream([2,2],undef,undef,undef,$wrong);
        1
    };
    ok(!$ok,'非法直方圖接收器必須拒絕');
    like($@,qr/位置直方圖接收器/,'拒絕有明確原因');
}
done_testing;
