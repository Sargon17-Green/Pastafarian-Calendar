use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Scalar::Util qw(refaddr);
use File::Temp qw(tempdir);
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);

sub histogram_as_strings ($h) {
    return [map {defined($_) ? "$_" : undef} @$h];
}
my @lengths=(3,2,4);
my @oracle;
my $expected=countWeavingsPolynomial(\@lengths,undef,\@oracle);
my (@retained,@delivered,%stats);
my $answer=countWeavingsPolynomialStream(
    \@lengths,\%stats,\@retained,undef,
    sub ($stage,$h) {
        $delivered[$stage]=$h;
        for my $v (@$h) {
            next unless defined($v);
            $v->badd(1_000_000+$stage);
            last;
        }
        push @$h,Math::BigInt->new(7777);
    });
is("$answer","$expected",'接收器改寫不會改變最終精確 BigInt');
is($stats{histogram_sink_calls},3,'回呼階段數正確');
for my $stage (1 .. 3) {
    is_deeply(histogram_as_strings($retained[$stage]),histogram_as_strings($oracle[$stage]),
       "第 $stage 階段保留的完整位置分布不受改寫");
    isnt(refaddr($retained[$stage]),refaddr($delivered[$stage]),
       "第 $stage 階段 ARRAY 並非相同參照");
    my $first;
    for my $u (0 .. $#{$oracle[$stage]}) {
        if (defined($oracle[$stage][$u])) {$first=$u;last}
    }
    ok(defined($first),'每個階段至少含一個非空 BigInt');
    isnt(refaddr($retained[$stage][$first]),
         refaddr($delivered[$stage][$first]),
         "第 $stage 階段 BigInt 並非相同參照");
    $delivered[$stage][$first]->badd(8000);
    is_deeply(histogram_as_strings($retained[$stage]),histogram_as_strings($oracle[$stage]),
        "第 $stage 階段接收器的延後修改不污染保留值");
}
my $calls=0;
my $only_sink=countWeavingsPolynomialStream([2,3,2],undef,undef,undef,
    sub ($stage,$h) {
        $calls++;
        $_->badd(1) for grep {defined($_)} @$h;
    });
is("$only_sink",''.countWeavingsPolynomial([2,3,2]),
   '只有回呼時修改也不能影響總數');
is($calls,3,'沒有保留值時仍交付三個階段');

my $scratch=tempdir(CLEANUP=>1);
{
    local $ENV{TMPDIR}=$scratch;
    my $ok=eval {
        countWeavingsPolynomialStream([4,4,4,4],undef,undef,undef,
            sub ($stage,$h) {
                die "刻意接收器失敗\n" if $stage==2;
            });
        1;
    };
    ok(!$ok,'第二階段例外使串流停止');
    like($@,qr/刻意接收器失敗/,'保留回呼原始例外');
    opendir my $dh,$scratch or die "無法開啟私有暫存目錄：$!\n";
    my @left=grep {$_ ne '.' && $_ ne '..'} readdir($dh);
    closedir $dh;
    is_deeply(\@left,[],'回呼例外後立刻回收全部暫存列');
}
done_testing;
