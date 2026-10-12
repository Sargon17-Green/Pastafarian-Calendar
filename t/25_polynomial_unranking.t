use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib','t/lib';
use Pastafari::WeavingUnrank qw(unrankWeavingPolynomial);
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::NormativeScroll qw(unrankWeaving);

my $checked = 0;
for my $m (1 .. 4) {
    my $generate;
    $generate = sub ($lengths) {
        if (@$lengths == $m) {
            my $total = countWeavingsPolynomial($lengths);
            my @ranks;
            # 小規模完整枚舉所有合法字典序排名。
            if ($m <= 3 || $total <= 24) {
                @ranks = (1 .. 0+"$total");
            } else {
                @ranks = (1,2,3,int("$total"/2),0+"$total"-1,0+"$total");
            }
            my %seen;
            for my $rank (@ranks) {
                next if $seen{$rank}++;
                my $got = unrankWeavingPolynomial($lengths, $rank);
                my $expected = unrankWeaving($lengths,$rank);
                is_deeply($got,$expected,
                    '多項式前綴排名與原本字典序完全相同：'
                        .join('-',@$lengths)."/$rank");
                $checked++;
            }
            return;
        }
        my @length_choices = $m == 4 ? (1,2) : (1,2,3);
        $generate->([@$lengths,$_]) for @length_choices;
    };
    $generate->([]);
}
cmp_ok($checked,'>=',100,'至少一百個獨立字典序排名比對');
for my $lengths ([4,4,4],[4,4,4,4],[(4)x5]) {
    my $total=countWeavingsPolynomial($lengths);
    my $middle=$total->copy->bdiv(2);
    $middle->badd(1) if $middle < 1;
    for my $rank (Math::BigInt->bone,$middle,$total) {
        my %stats;
        my $answer=unrankWeavingPolynomial($lengths,$rank,\%stats);
        is_deeply($answer,unrankWeaving($lengths,$rank),
            '大排名和規範字典序相同：'.join('-',@$lengths)."/$rank");
        is($stats{days},scalar(@$answer),'診斷總日數與解碼一致');
        is($stats{suffix_calls} + $stats{shortcut_steps},
           $stats{considered},'計算後綴次數加上推導數量等於所考察候選數');
        cmp_ok($stats{suffix_calls},'<=',$stats{considered},
            '最後候選無須重新執行後綴計數');
    }
}
my $input=Math::BigInt->new('2');
my $answer=unrankWeavingPolynomial([2,2],$input);
is("$input",'2','排名物件未遭修改');
is_deeply($answer,[1,2,1,2],'二月排名二正確');
my $total=countWeavingsPolynomial([2,2]);
for my $bad (undef,0,-1,'1e0','2.5','NaN',[],{},3,Math::BigInt->new('9'x300)) {
    my $ok=eval { unrankWeavingPolynomial([2,2],$bad);1 };
    ok(!$ok,'拒絕不合法或越界排名');
    like($@,qr/交織排名/,'拒絕訊息一致');
}
done_testing;
