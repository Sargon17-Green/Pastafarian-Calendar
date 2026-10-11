use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    makeBoundedCompositionFamily makeCutletPartitionFamily
    countWeavings unrankWeaving fallingFactorial unrankDistinctIndices
);

# 窮舉微型空間；參考模型不得呼叫受測的計數或反排名函式。
sub enumerate_bounded ($total, $slots, $lo, $hi) {
    my @out;
    my $walk;
    $walk = sub ($rem, $left, $prefix) {
        if ($left == 0) {
            push @out, [@$prefix] if $rem == 0;
            return;
        }
        for my $x ($lo .. $hi) {
            next if $x > $rem;
            $walk->($rem - $x, $left - 1, [@$prefix, $x]);
        }
    };
    $walk->($total, $slots, []);
    return \@out;
}

sub enumerate_partitions ($total, $slots, $required) {
    my @out;
    my $walk;
    $walk = sub ($rem, $left, $prefix, $sum, $hit) {
        if ($left == 0) {
            push @out, [@$prefix] if $rem == 0 && (!defined($required) || $hit);
            return;
        }
        for my $x (1 .. $rem) {
            my $new_sum = $sum + $x;
            $walk->($rem - $x, $left - 1, [@$prefix, $x],
                $new_sum, $hit || (defined($required) && $new_sum == $required));
        }
    };
    $walk->($total, $slots, [], 0, 0);
    return \@out;
}

sub enumerate_weavings ($lengths) {
    my @out;
    my $m = scalar @$lengths;
    my $walk;
    $walk = sub ($remaining, $prefix) {
        my $sum = 0;
        $sum += $_ for @$remaining;
        if ($sum == 0) {
            my (%first, %last);
            for my $i (0 .. $#$prefix) {
                $first{$prefix->[$i]} //= $i;
                $last{$prefix->[$i]} = $i;
            }
            for my $j (2 .. $m) {
                return if $first{$j-1} >= $first{$j};
                return if $last{$j-1} >= $last{$j};
            }
            push @out, [@$prefix];
            return;
        }
        for my $j (1 .. $m) {
            next if $remaining->[$j - 1] == 0;
            my @next = @$remaining;
            $next[$j - 1]--;
            $walk->(\@next, [@$prefix, $j]);
        }
    };
    $walk->([@$lengths], []);
    return \@out;
}

sub enumerate_distinct ($n, $k) {
    my @out;
    my $walk;
    $walk = sub ($remaining, $prefix) {
        if (@$prefix == $k) {
            push @out, [@$prefix];
            return;
        }
        for my $i (0 .. $#$remaining) {
            my @next = @$remaining;
            my $x = splice(@next, $i, 1);
            $walk->(\@next, [@$prefix, $x]);
        }
    };
    $walk->([1 .. $n], []);
    return \@out;
}

for my $total (0 .. 12) {
    for my $slots (0 .. 4) {
        for my $lo (1 .. 3) {
            my $hi = $lo + 2;
            my $expected = enumerate_bounded($total, $slots, $lo, $hi);
            my $family = makeBoundedCompositionFamily($total, $slots, $lo, $hi);
            is('' . $family->{count}->(), '' . scalar(@$expected),
                "有界組成總數 $total/$slots/$lo/$hi");
            for my $rank (1 .. scalar @$expected) {
                is_deeply($family->{unrank1}->($rank), $expected->[$rank - 1],
                    "有界組成字典序 $total/$slots/$lo/$hi/$rank");
            }
        }
    }
}

for my $total (2 .. 10) {
    for my $slots (1 .. ($total < 4 ? $total : 4)) {
        for my $required (undef, 1 .. $total - 1) {
            my $expected = enumerate_partitions($total, $slots, $required);
            my $family = makeCutletPartitionFamily($total, $slots, $required);
            my $label = defined($required) ? $required : '無限制';
            is('' . $family->{count}->(), '' . scalar(@$expected),
                "肉排分割總數 $total/$slots/$label");
            for my $rank (1 .. scalar @$expected) {
                is_deeply($family->{unrank1}->($rank), $expected->[$rank - 1],
                    "肉排分割字典序 $total/$slots/$label/$rank");
            }
        }
    }
}

for my $m (1 .. 3) {
    my $walk;
    $walk = sub ($lengths) {
        if (@$lengths == $m) {
            my $expected = enumerate_weavings($lengths);
            my $label = join('-', @$lengths);
            is('' . countWeavings($lengths), '' . scalar(@$expected),
                "月份交織總數 $label");
            for my $rank (1 .. scalar @$expected) {
                is_deeply(unrankWeaving($lengths, $rank), $expected->[$rank - 1],
                    "月份交織字典序 $label/$rank");
            }
            return;
        }
        for my $len (1 .. 3) { $walk->([@$lengths, $len]) }
    };
    $walk->([]);
}

for my $n (1 .. 5) {
    for my $k (1 .. $n) {
        my $expected = enumerate_distinct($n, $k);
        is('' . fallingFactorial($n, $k), '' . scalar(@$expected),
            "無重複名稱排列總數 $n/$k");
        for my $rank (1 .. scalar @$expected) {
            is_deeply(unrankDistinctIndices($n, $k, $rank), $expected->[$rank - 1],
                "無重複名稱字典序 $n/$k/$rank");
        }
    }
}

done_testing;
