use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use File::Temp qw(tempdir);
use lib 'lib', 't/lib';
use Pastafari::WeavingSuffix qw(countWeavingSuffixPolynomial);
use Pastafari::WeavingSuffixFactor qw(countWeavingSuffixFactored);

# Stage 1 only. For every valid prefix in several heterogeneous small
# month vectors, compare all three factor engines with the independent
# normative suffix counter. Deliberately vary call order and mutate the
# returned BigInt to detect aliasing of cached exact counts.
my @vectors = (
    [2,2,2], [1,2,2], [3,1,2], [2,1,2,1]
);
my @engines = ('resident', 'stream', 'stream-indexed');
my $scratch = tempdir(CLEANUP => 1);
my ($prefix_count, $comparison_count, $mutability_count) = (0,0,0);
my @owned_paths;
{
    local $ENV{TMPDIR} = $scratch;
    my %shared;
    for my $lengths (@vectors) {
        my $m = scalar @$lengths;
        my @prefixes;
        my $visit;
        $visit = sub ($prefix, $remaining, $opened, $closed) {
            push @prefixes, [@$prefix];
            my $upper = $opened < $m ? $opened + 1 : $m;
            for my $j (1 .. $upper) {
                next if !$remaining->[$j-1];
                next if $remaining->[$j-1] == 1 && $j != $closed + 1;
                my @next = @$remaining;
                $next[$j-1]--;
                my $next_opened = $j > $opened ? $j : $opened;
                my $next_closed = $next[$j-1] ? $closed : $j;
                $visit->([@$prefix,$j],\@next,$next_opened,$next_closed);
            }
        };
        $visit->([],[@$lengths],0,0);
        ok(@prefixes > $m, '各月份向量具多種合法的部分前綴');
        # Reverse prefix query order; rotate engine order between queries.
        for my $ordinal (reverse(0 .. $#prefixes)) {
            my $prefix = $prefixes[$ordinal];
            my $expected = countWeavingSuffixPolynomial($lengths,$prefix);
            cmp_ok($expected,'>',0,'合法前綴仍可完工');
            my @saved = @$prefix;
            my $rotation = $prefix_count % scalar(@engines);
            for my $step (0 .. $#engines) {
                my $engine = $engines[($rotation + $step) % @engines];
                my $options = {profile_engine=>$engine};
                $options->{max_temp_file_bytes} = 32_768
                    if $engine ne 'resident';
                my $value = countWeavingSuffixFactored(
                    $lengths,$prefix,\%shared,undef,$options
                );
                is("$value","$expected",'三種引擎精確計數符合獨立規範');
                $comparison_count++;
                $value->badd(987_654_321);
                my $again = countWeavingSuffixFactored(
                    $lengths,$prefix,\%shared,undef,$options
                );
                is("$again","$expected",'回傳 BigInt 變異不污染共享快取');
                $mutability_count++;
            }
            is_deeply($prefix,\@saved,'計算不改動呼叫者的前綴');
            $prefix_count++;
        }
    }
    my @stores = grep {ref($_) eq 'Pastafari::WeavingProfileDisk'} values %shared;
    is(scalar(@stores),scalar(@vectors),
       '同一快取為四種月份向量分別持有索引物件');
    @owned_paths = map {$_->{path}} @stores;
    for my $path (@owned_paths) {
        ok(-f $path,'共享快取仍存活時索引暫存檔存在');
    }
}
for my $path (@owned_paths) {
    ok(!-e $path,'最後持有者解除時索引暫存檔立即刪除');
}
is($comparison_count,3*$prefix_count,'全部合法前綴都經三引擎核對');
is($mutability_count,3*$prefix_count,'全部返回值都經 BigInt 所有權核對');
cmp_ok($prefix_count,'>',35,'涵蓋多種開啟與關閉月份狀態');

# Public audit input normalization must not mutate Math::BigInt objects.
my @big_lengths = map {Math::BigInt->new($_)} (2,3,2);
my @big_prefix = (Math::BigInt->bone,Math::BigInt->new(2));
my $before_lengths = join(',',map {"$_"} @big_lengths);
my $before_prefix = join(',',map {"$_"} @big_prefix);
my $expected = countWeavingSuffixPolynomial([2,3,2],[1,2]);
my $actual = countWeavingSuffixFactored(\@big_lengths,\@big_prefix,
    undef,undef,{profile_engine=>'stream-indexed',max_temp_file_bytes=>32_768});
is("$actual","$expected",'BigInt 月長及前綴與一般整數等價');
is(join(',',map {"$_"} @big_lengths),$before_lengths,'BigInt 月長不被改動');
is(join(',',map {"$_"} @big_prefix),$before_prefix,'BigInt 前綴不被改動');
done_testing;
