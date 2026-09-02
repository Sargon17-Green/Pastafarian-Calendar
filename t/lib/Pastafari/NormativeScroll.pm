package Pastafari::NormativeScroll;
use v5.40;
use utf8;
use strict;
use warnings;
use Math::BigInt;
use Exporter 'import';
use Pastafari::SourceLanguageCatalog qw(cutlet_name_by_index month_name_by_index);

our @EXPORT_OK = qw(
    M FOUNDATION_DAY TABLETS_DAY SAVE regularMod dayCount workCounts buildStones
    buildHiddenDrops buildVisibleDrops initialBowls applyVisibleDropsToBowls postStir12 sauce
    bowlOrderFromDrop nextBowlInDrop46Order askBowl answerAt chooseRankShort chooseRankWide chooseRank
    fallingFactorial unrankDistinctIndices makeBoundedCompositionFamily makeCutletPartitionFamily
    countWeavings unrankWeaving resetGateCache ensureGateIndex exactGateIndex
    positiveGateGap negativeGateGap year5000 nextYear previousYear findTargetYear buildYearStructure calendarDate
);

use constant TABLETS_DAY_I    => -278522;
use constant FOUNDATION_DAY_I => -15055671;
use constant GATE_GAP_MIN     => 42;
use constant GATE_GAP_MAX     => 963;
use constant YEAR_MIN_DAYS    => 252;
use constant YEAR_MAX_DAYS    => 5778;

use constant WHEAT  => 1;
use constant BARLEY => 2;
use constant SALT   => 3;
use constant BITTER => 4;
use constant RED    => 5;

use constant SEAL_GATE_GAP         => 1;
use constant SEAL_YEAR_5000        => 10;
use constant SEAL_NEXT_YEAR        => 11;
use constant SEAL_PREVIOUS_YEAR    => 12;
use constant SEAL_CUTLET_COUNT     => 20;
use constant SEAL_CUTLET_PARTITION => 21;
use constant SEAL_CUTLET_NAMES     => 22;
use constant SEAL_MONTH_COUNT      => 30;
use constant SEAL_MONTH_LENGTHS    => 31;
use constant SEAL_MONTH_WEAVING    => 32;
use constant SEAL_MONTH_NAMES      => 33;

my $M_CONST = Math::BigInt->new(2)->bpow(127)->bsub(1);

sub _bi ($x) {
    return $x->copy if ref($x) && eval { $x->isa('Math::BigInt') };
    return Math::BigInt->new("$x");
}

sub M { return $M_CONST->copy }
sub FOUNDATION_DAY { return Math::BigInt->new(FOUNDATION_DAY_I) }
sub TABLETS_DAY { return Math::BigInt->new(TABLETS_DAY_I) }

sub regularMod ($x, $d) {
    my $div = _bi($d);
    die "除數必須至少為一\n" if $div->is_zero || $div->is_neg;
    return _bi($x)->bmod($div);
}

sub SAVE ($x) {
    return regularMod(_bi($x)->bsub(1), $M_CONST)->badd(1);
}

sub _square ($x) { return _bi($x)->bmul($x) }

sub _floor_div ($a, $b) {
    my $div = _bi($b);
    die "除數必須至少為一\n" if $div->is_zero || $div->is_neg;
    return _bi($a)->bdiv($div);
}

sub _ceil_div_nonnegative ($a, $b) {
    my $aa = _bi($a);
    my $bb = _bi($b);
    die "被除數不得為負\n" if $aa->is_neg;
    return $aa->copy->badd($bb)->bsub(1)->bdiv($bb);
}

sub _wrap1 ($position, $size) {
    return regularMod(_bi($position)->bsub(1), $size)->badd(1)->numify;
}

sub dayCount ($day) {
    my $d = _bi($day);
    my $f = FOUNDATION_DAY();
    return Math::BigInt->bone if $d->bcmp($f) == 0;
    if ($d->bcmp($f) > 0) {
        return $d->copy->bsub($f)->bmul(2)->badd(1);
    }
    return $f->copy->bsub($d)->bmul(2);
}

sub workCounts ($calculationDay, $targetDay) {
    my $cday = _bi($calculationDay);
    my $tday = _bi($targetDay);
    my $action = dayCount($cday);
    my $target = dayCount($tday);
    my $distance = $tday->copy->bsub($cday)->babs->badd(1);
    my $connection = $action->copy->badd($target);
    my $direction = $tday->bcmp($cday) < 0 ? 1 : $tday->bcmp($cday) == 0 ? 2 : 3;
    return {
        action => $action,
        target => $target,
        distance => $distance,
        connection => $connection,
        direction => $direction,
    };
}

sub buildStones () {
    my @stone;
    $stone[1] = [ map { Math::BigInt->new($_) } (17,29,43,71,101) ];
    for my $i (2 .. 46) {
        my $old = $stone[$i - 1];
        my $w = SAVE(_square($old->[WHEAT-1])->badd(_bi($old->[BARLEY-1])->bmul(3))->badd($i));
        my $b = SAVE(_square($old->[BARLEY-1])->badd(_bi($old->[SALT-1])->bmul(5))->badd($old->[WHEAT-1]));
        my $s = SAVE(_square($old->[SALT-1])->badd(_bi($old->[BITTER-1])->bmul(7))->badd($old->[BARLEY-1]));
        my $m = SAVE(_square($old->[BITTER-1])->badd(_bi($old->[RED-1])->bmul(11))->badd($old->[SALT-1]));
        my $r = SAVE(_square($old->[RED-1])->badd(_bi($old->[WHEAT-1])->bmul(13))->badd($old->[BITTER-1]));
        $stone[$i] = [$w,$b,$s,$m,$r];
    }
    return \@stone;
}

my $STONES;
sub _stones () {
    $STONES //= buildStones();
    return $STONES;
}

my @HIDDEN_COEFF = (
    undef,
    [3,4,6,8], [5,7,10,12], [7,10,14,16], [9,13,18,20],
    [11,16,22,24], [13,19,26,28], [15,22,30,32],
);
my @HIDDEN_GRIND_STONE = (undef, WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY);

sub buildHiddenDrops ($counts, $stones = undef) {
    $stones //= _stones();
    my @hidden;
    for my $k (1 .. 7) {
        my ($a,$b,$c,$d) = @{ $HIDDEN_COEFF[$k] };
        my $x = _bi($counts->{action})
            ->badd(_bi($counts->{target})->bmul($a))
            ->badd(_bi($counts->{distance})->bmul($b))
            ->badd(_bi($counts->{connection})->bmul($c))
            ->badd(_bi($counts->{direction})->bmul($d));
        for my $kind (WHEAT, BARLEY, SALT, BITTER, RED) {
            $x->badd($stones->[$k][$kind - 1]);
        }
        $x = SAVE($x);
        for my $grind (1 .. 7) {
            my $old = $x->copy;
            $x = SAVE(
                _square($old)
                    ->badd(_bi($old)->bmul(3))
                    ->badd($stones->[$k][$HIDDEN_GRIND_STONE[$grind] - 1])
                    ->badd($grind)
            );
        }
        $hidden[$k] = $x;
    }
    return \@hidden;
}

my @VISIBLE_GRINDS = (
    undef,
    [3,5,7,11,WHEAT], [5,7,11,13,BARLEY], [7,11,13,17,SALT],
    [11,13,17,19,BITTER], [13,17,19,23,RED], [17,19,23,29,WHEAT],
    [19,23,29,31,BARLEY], [23,29,31,37,SALT], [29,31,37,41,BITTER],
    [31,37,41,43,RED], [37,41,43,47,WHEAT],
);

sub buildVisibleDrops ($counts, $stones = undef, $hidden = undef) {
    $stones //= _stones();
    $hidden //= buildHiddenDrops($counts, $stones);
    my %timeline;
    for my $k (1 .. 7) {
        $timeline{1 - $k} = $hidden->[$k]->copy;
    }
    my @visible;
    for my $i (1 .. 46) {
        my $prev1 = $timeline{$i - 1};
        my $prev3 = $timeline{$i - 3};
        my $prev7 = $timeline{$i - 7};
        my $x = _bi($stones->[$i][WHEAT-1])->bmul($counts->{action})
            ->badd(_bi($stones->[$i][BARLEY-1])->bmul($counts->{target}))
            ->badd(_bi($stones->[$i][SALT-1])->bmul($counts->{distance}))
            ->badd(_bi($stones->[$i][BITTER-1])->bmul($counts->{connection}))
            ->badd(_bi($stones->[$i][RED-1])->bmul($counts->{direction}))
            ->badd($prev1)
            ->badd(_bi($prev3)->bmul(3))
            ->badd(_bi($prev7)->bmul(5))
            ->badd($i);
        $x = SAVE($x);
        for my $grind (1 .. 11) {
            my ($a,$b,$c,$d,$kind) = @{ $VISIBLE_GRINDS[$grind] };
            my $old = $x->copy;
            $x = SAVE(
                _square($old)
                    ->badd(_bi($old)->bmul($a))
                    ->badd(_bi($prev1)->bmul($b))
                    ->badd(_bi($prev3)->bmul($c))
                    ->badd(_bi($prev7)->bmul($d))
                    ->badd($stones->[$i][$kind - 1])
            );
        }
        $timeline{$i} = $x->copy;
        $visible[$i] = $x;
    }
    return \@visible;
}

sub _factorial_native ($n) {
    my $r = 1;
    $r *= $_ for 2 .. $n;
    return $r;
}

sub _permutation_unrank1 ($rank1, $items) {
    my $rank0 = _bi($rank1)->bsub(1);
    my @remaining = @$items;
    my @out;
    for (my $slots = scalar(@remaining); $slots >= 1; $slots--) {
        my $block = _factorial_native($slots - 1);
        my $q = $rank0->copy->bdiv($block)->numify;
        $rank0 = $rank0->copy->bmod($block);
        push @out, splice(@remaining, $q, 1);
    }
    return \@out;
}

sub bowlOrderFromDrop ($dropValue) {
    my $n = regularMod(_bi($dropValue)->bsub(1), 720)->badd(1);
    return _permutation_unrank1($n, [1,2,3,4,5,6]);
}

my @BOWL_PRIME = (undef,17,19,23,29,31,37);
my @BOWL_STIR_STONE = (undef,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT);

sub initialBowls ($counts) {
    my @bowls;
    for my $id (1 .. 6) {
        my $s = _bi($counts->{action})
            ->badd(_bi($counts->{target})->bmul($id))
            ->badd($counts->{distance})
            ->badd($counts->{connection})
            ->badd($counts->{direction})
            ->badd($BOWL_PRIME[$id] * $BOWL_PRIME[$id]);
        $bowls[$id] = SAVE(_square($s)->badd($id));
    }
    return \@bowls;
}

sub applyVisibleDropsToBowls ($bowls, $visible, $stones = undef) {
    $stones //= _stones();
    my @b = map { defined($_) ? $_->copy : undef } @$bowls;
    my $order46;
    for my $i (1 .. 46) {
        my $drop = $visible->[$i];
        my $order = bowlOrderFromDrop($drop);
        my @old = map { defined($_) ? $_->copy : undef } @b;
        my @pour = (undef, map { Math::BigInt->bzero } 1 .. 6);
        my $first = $order->[0];
        my $second = $order->[1];
        my $third = $order->[2];
        $pour[1] = SAVE(_square($drop)->badd(_bi($stones->[$i][WHEAT-1])->bmul($old[$first]))->badd(3*$i));
        $pour[2] = SAVE(_square($drop)->badd(_bi($stones->[$i][BARLEY-1])->bmul($old[$second]))->badd(5*$i));
        $pour[3] = SAVE(_square($drop)->badd(_bi($stones->[$i][SALT-1])->bmul($old[$third]))->badd(7*$i));
        my @next = @old;
        for my $position (1 .. 6) {
            my $id = $order->[$position - 1];
            my $prev = $order->[_wrap1($position - 1, 6) - 1];
            my $nextid = $order->[_wrap1($position + 1, 6) - 1];
            my $kind = $BOWL_STIR_STONE[$position];
            my $s = _bi($old[$id])
                ->badd(_bi($old[$prev])->bmul(2))
                ->badd(_bi($old[$nextid])->bmul(3))
                ->badd($pour[$position])
                ->badd($drop)
                ->badd($stones->[$i][$kind - 1]);
            $next[$id] = SAVE(_square($s)->badd(_bi($old[$prev])->bmul($old[$nextid])->bmul(5))->badd($i*$position));
        }
        @b = @next;
        $order46 = [@$order] if $i == 46;
    }
    return (\@b, $order46);
}

sub postStir12 ($bowls) {
    my @b = map { defined($_) ? $_->copy : undef } @$bowls;
    for my $stir (1 .. 12) {
        my @old = map { defined($_) ? $_->copy : undef } @b;
        my $saved = Math::BigInt->bzero;
        $saved->badd($old[$_]) for 1 .. 6;
        $saved->badd(149 * $stir);
        $saved = SAVE($saved);
        my $orderNumber = regularMod($saved->copy->bsub(1),720)->badd(1);
        my $order = _permutation_unrank1($orderNumber, [1,2,3,4,5,6]);
        my @next = @old;
        for my $position (1 .. 6) {
            my $id = $order->[$position - 1];
            my $prev = $order->[_wrap1($position - 1, 6) - 1];
            my $nextid = $order->[_wrap1($position + 1, 6) - 1];
            my $s = _bi($old[$id])
                ->badd(_bi($old[$prev])->bmul(3))
                ->badd(_bi($old[$nextid])->bmul(5))
                ->badd($saved)
                ->badd($stir)
                ->badd($position*$position);
            $next[$id] = SAVE(_square($s)->badd(_bi($old[$prev])->bmul($old[$nextid])->bmul(7)));
        }
        @b = @next;
    }
    return \@b;
}

sub sauce ($calculationDay, $targetDay) {
    my $counts = workCounts($calculationDay,$targetDay);
    my $stones = _stones();
    my $hidden = buildHiddenDrops($counts,$stones);
    my $visible = buildVisibleDrops($counts,$stones,$hidden);
    my $bowls = initialBowls($counts);
    my ($after,$order46) = applyVisibleDropsToBowls($bowls,$visible,$stones);
    my $final = postStir12($after);
    return { bowls => $final, orderAtDrop46 => $order46 };
}

sub nextBowlInDrop46Order ($sauceResult, $queriedBowlId) {
    my $order = $sauceResult->{orderAtDrop46};
    for my $p (0 .. $#$order) {
        return $order->[($p + 1) % 6] if $order->[$p] == $queriedBowlId;
    }
    die "查詢的碗不存在於第 46 滴順序\n";
}

sub askBowl ($sauceResult, $queriedBowlId, $seal) {
    my $next = nextBowlInDrop46Order($sauceResult,$queriedBowlId);
    my $first = SAVE(
        _square(_bi($sauceResult->{bowls}[$queriedBowlId])->badd($seal)->badd(181))
            ->badd(_bi($sauceResult->{bowls}[$next])->bmul(179))
            ->badd($seal)
    );
    my $directionNumber = SAVE(
        _square(_bi($first)->badd($seal)->badd(1)->badd(193))
            ->badd(_bi($first)->bmul(193))
            ->badd(_bi($sauceResult->{bowls}[6])->bmul(197))
    );
    my $step = regularMod($directionNumber,2)->is_one ? 1 : -1;
    return { first => $first, directionStep => $step };
}

sub answerAt ($stream, $k) {
    return regularMod(_bi($stream->{first})->bsub(1)->badd(_bi($stream->{directionStep})->bmul($k)), $M_CONST)->badd(1);
}

sub chooseRankShort ($stream, $N) {
    my $n = _bi($N);
    die "選擇空間超出短選擇範圍\n" if $n < 1 || $n > $M_CONST;
    my $limit = $M_CONST->copy->bdiv($n)->bmul($n);
    my $k = 0;
    while (1) {
        my $x = answerAt($stream,$k);
        return regularMod($x->copy->bsub(1),$n)->badd(1) if $x <= $limit;
        $k++;
    }
}

sub chooseRankWide ($stream, $N) {
    my $n = _bi($N);
    die "寬選擇只接受大於 M 的空間\n" if $n <= $M_CONST;
    my $k = 1;
    my $space = $M_CONST->copy;
    while ($space < $n) {
        $k++;
        $space->bmul($M_CONST);
    }
    my $wide = Math::BigInt->bone;
    my $weight = Math::BigInt->bone;
    for my $j (0 .. $k - 1) {
        $wide->badd(answerAt($stream,$j)->bsub(1)->bmul($weight));
        $weight->bmul($M_CONST);
    }
    my $limit = $space->copy->bdiv($n)->bmul($n);
    while ($wide > $limit) {
        $wide = regularMod($wide->copy->bsub(1)->badd($stream->{directionStep}),$space)->badd(1);
    }
    return regularMod($wide->copy->bsub(1),$n)->badd(1);
}

sub chooseRank ($stream, $N) {
    return _bi($N) <= $M_CONST ? chooseRankShort($stream,$N) : chooseRankWide($stream,$N);
}

sub fallingFactorial ($n, $k) {
    my $r = Math::BigInt->bone;
    for my $j (0 .. $k - 1) { $r->bmul($n - $j) }
    return $r;
}

sub unrankDistinctIndices ($n, $k, $rank1) {
    my @remaining = (1 .. $n);
    my @out;
    my $r = _bi($rank1);
    for my $position (1 .. $k) {
        my $suffix = $k - $position;
        my $block = fallingFactorial(scalar(@remaining)-1,$suffix);
        for my $ci (0 .. $#remaining) {
            if ($r > $block) {
                $r->bsub($block);
            } else {
                push @out, splice(@remaining,$ci,1);
                last;
            }
        }
    }
    return \@out;
}

sub makeBoundedCompositionFamily ($total, $slots, $lo, $hi) {
    my %memo;
    my $count;
    $count = sub ($rem,$k) {
        return Math::BigInt->new($rem == 0 ? 1 : 0) if $k == 0;
        return Math::BigInt->bzero if $rem < $k*$lo || $rem > $k*$hi;
        my $key = "$rem|$k";
        return $memo{$key}->copy if exists $memo{$key};
        my $sum = Math::BigInt->bzero;
        for my $x ($lo .. $hi) {
            last if $x > $rem;
            $sum->badd($count->($rem-$x,$k-1));
        }
        $memo{$key} = $sum->copy;
        return $sum;
    };
    my $count_all = sub { return $count->($total,$slots) };
    my $unrank = sub ($rank1) {
        my $r = _bi($rank1);
        my ($rem,$k) = ($total,$slots);
        my @out;
        for my $position (1 .. $slots) {
            for my $x ($lo .. $hi) {
                next if $x > $rem;
                my $block = $count->($rem-$x,$slots-$position);
                if ($r > $block) {
                    $r->bsub($block);
                } else {
                    push @out,$x;
                    $rem -= $x;
                    $k--;
                    last;
                }
            }
        }
        return \@out;
    };
    return { count => $count_all, unrank1 => $unrank };
}

sub makeCutletPartitionFamily ($G, $K, $required = undef) {
    my %memo;
    my $count;
    $count = sub ($rem,$slots,$cumulative,$hit) {
        if ($slots == 0) {
            return Math::BigInt->bzero if $rem != 0;
            return Math::BigInt->bone if !defined $required;
            return Math::BigInt->new($hit ? 1 : 0);
        }
        return Math::BigInt->bzero if $rem < $slots;
        my $key = join('|',$rem,$slots,$cumulative,$hit?1:0);
        return $memo{$key}->copy if exists $memo{$key};
        my $sum = Math::BigInt->bzero;
        my $maxx = $rem - ($slots - 1);
        for my $x (1 .. $maxx) {
            my $nextcum = $cumulative + $x;
            my $nexthit = $hit;
            if (defined($required) && !$hit) {
                if ($nextcum == $required) { $nexthit = 1 }
                elsif ($nextcum > $required) { next }
            }
            $sum->badd($count->($rem-$x,$slots-1,$nextcum,$nexthit));
        }
        $memo{$key} = $sum->copy;
        return $sum;
    };
    my $count_all = sub { return $count->($G,$K,0,0) };
    my $unrank = sub ($rank1) {
        my $r = _bi($rank1);
        my ($rem,$slots,$cum,$hit) = ($G,$K,0,0);
        my @out;
        while ($slots > 0) {
            my $maxx = $rem - ($slots - 1);
            for my $x (1 .. $maxx) {
                my $nextcum = $cum + $x;
                my $nexthit = $hit;
                if (defined($required) && !$hit) {
                    if ($nextcum == $required) { $nexthit = 1 }
                    elsif ($nextcum > $required) { next }
                }
                my $block = $count->($rem-$x,$slots-1,$nextcum,$nexthit);
                if ($r > $block) {
                    $r->bsub($block);
                } else {
                    push @out,$x;
                    $rem -= $x;
                    $slots--;
                    $cum = $nextcum;
                    $hit = $nexthit;
                    last;
                }
            }
        }
        return \@out;
    };
    return { count => $count_all, unrank1 => $unrank };
}

sub _weave_counter ($lengths) {
    my $m = scalar @$lengths;
    my %memo;
    my $count;
    $count = sub ($remaining,$opened,$closed) {
        my $done = 1;
        for my $v (@$remaining) { if ($v != 0) { $done = 0; last } }
        return Math::BigInt->bone if $done;
        my $key = join(',',@$remaining) . "|$opened|$closed";
        return $memo{$key}->copy if exists $memo{$key};
        my $sum = Math::BigInt->bzero;
        for my $j (1 .. $m) {
            next if $remaining->[$j-1] == 0;
            my $alreadyOpened = $remaining->[$j-1] < $lengths->[$j-1];
            next if !$alreadyOpened && $j != $opened + 1;
            my $willClose = $remaining->[$j-1] == 1;
            next if $willClose && $j != $closed + 1;
            my @next = @$remaining;
            my $nextOpened = $opened;
            my $nextClosed = $closed;
            $nextOpened = $j if $next[$j-1] == $lengths->[$j-1];
            $next[$j-1]--;
            $nextClosed = $j if $next[$j-1] == 0;
            $sum->badd($count->(\@next,$nextOpened,$nextClosed));
        }
        $memo{$key} = $sum->copy;
        return $sum;
    };
    return $count;
}

sub countWeavings ($lengths) {
    my $counter = _weave_counter($lengths);
    return $counter->([@$lengths],0,0);
}

sub unrankWeaving ($lengths, $rank1) {
    my $m = scalar @$lengths;
    my $counter = _weave_counter($lengths);
    my @remaining = @$lengths;
    my ($opened,$closed) = (0,0);
    my $r = _bi($rank1);
    my @out;
    my $total = 0; $total += $_ for @$lengths;
    while (@out < $total) {
        for my $j (1 .. $m) {
            next if $remaining[$j-1] == 0;
            my $alreadyOpened = $remaining[$j-1] < $lengths->[$j-1];
            next if !$alreadyOpened && $j != $opened + 1;
            my $willClose = $remaining[$j-1] == 1;
            next if $willClose && $j != $closed + 1;
            my @next = @remaining;
            my $nextOpened = $opened;
            my $nextClosed = $closed;
            $nextOpened = $j if $next[$j-1] == $lengths->[$j-1];
            $next[$j-1]--;
            $nextClosed = $j if $next[$j-1] == 0;
            my $block = $counter->(\@next,$nextOpened,$nextClosed);
            if ($r > $block) {
                $r->bsub($block);
            } else {
                push @out,$j;
                @remaining = @next;
                ($opened,$closed) = ($nextOpened,$nextClosed);
                last;
            }
        }
    }
    return \@out;
}

my %GATE;
my ($MIN_GATE,$MAX_GATE);

sub resetGateCache () {
    %GATE = (0 => FOUNDATION_DAY());
    ($MIN_GATE,$MAX_GATE) = (0,0);
    return 1;
}
resetGateCache();

sub positiveGateGap ($n) {
    die "正向閘門索引必須至少為一\n" if $n < 1;
    my $r = sauce(FOUNDATION_DAY(), FOUNDATION_DAY()->badd($n));
    my $stream = askBowl($r,1,SEAL_GATE_GAP);
    return 41 + chooseRank($stream,922)->numify;
}

sub negativeGateGap ($n) {
    die "負向閘門幅度必須至少為一\n" if $n < 1;
    my $r = sauce(FOUNDATION_DAY(), FOUNDATION_DAY()->bsub($n));
    my $stream = askBowl($r,1,SEAL_GATE_GAP);
    return 41 + chooseRank($stream,922)->numify;
}

sub ensureGateIndex ($k) {
    if ($k > $MAX_GATE) {
        for my $n ($MAX_GATE + 1 .. $k) {
            $GATE{$n} = $GATE{$n-1}->copy->badd(positiveGateGap($n));
        }
        $MAX_GATE = $k;
    }
    if ($k < $MIN_GATE) {
        my $n = $MIN_GATE - 1;
        while ($n >= $k) {
            $GATE{$n} = $GATE{$n+1}->copy->bsub(negativeGateGap(abs($n)));
            $n--;
        }
        $MIN_GATE = $k;
    }
    return $GATE{$k}->copy;
}

sub _ensure_gates_cover ($lowDay,$highDay) {
    my $low = _bi($lowDay); my $high = _bi($highDay);
    die "閘門涵蓋範圍順序錯誤\n" if $low > $high;
    while ($GATE{$MIN_GATE} > $low) { ensureGateIndex($MIN_GATE-1) }
    while ($GATE{$MAX_GATE} < $high) { ensureGateIndex($MAX_GATE+1) }
}

sub _gate_index_at_or_before ($day) {
    my $d = _bi($day);
    _ensure_gates_cover($d,$d);
    my ($lo,$hi) = ($MIN_GATE,$MAX_GATE);
    while ($lo < $hi) {
        my $mid = $lo + int(($hi-$lo+1)/2);
        if ($GATE{$mid} <= $d) { $lo = $mid } else { $hi = $mid-1 }
    }
    return $lo;
}

sub exactGateIndex ($day) {
    my $i = _gate_index_at_or_before($day);
    return $GATE{$i} == _bi($day) ? $i : undef;
}

sub _valid_year_pair ($i,$j) {
    return 0 if $j-$i < 6;
    my $L = $GATE{$j}->copy->bsub($GATE{$i});
    return $L >= YEAR_MIN_DAYS && $L <= YEAR_MAX_DAYS;
}

sub _year_record ($number,$i,$j) {
    return {
        number => _bi($number),
        openGateIndex => $i,
        closeGateIndex => $j,
        openGateDay => $GATE{$i}->copy,
        closeGateDay => $GATE{$j}->copy,
    };
}

sub year5000 ($calculationDay) {
    my $c = _bi($calculationDay);
    _ensure_gates_cover($c->copy->bsub(YEAR_MAX_DAYS),$c->copy->badd(YEAR_MAX_DAYS));
    my @candidates;
    for my $i ($MIN_GATE .. $MAX_GATE-1) {
        for my $j ($i+1 .. $MAX_GATE) {
            next if !_valid_year_pair($i,$j);
            next if !($GATE{$i} < $c && $c <= $GATE{$j});
            push @candidates, [$i,$j,$GATE{$j}->copy->bsub($GATE{$i})];
        }
    }
    @candidates = sort {
        my $cmp = $a->[2]->bcmp($b->[2]);
        $cmp ||= $GATE{$a->[0]}->bcmp($GATE{$b->[0]});
        $cmp;
    } @candidates;
    die "找不到第 5000 年候選區間\n" if !@candidates;
    my $r = sauce($c,$c);
    my $stream = askBowl($r,1,SEAL_YEAR_5000);
    my $rank = chooseRank($stream,scalar @candidates)->numify;
    my ($i,$j) = @{ $candidates[$rank-1] }[0,1];
    return _year_record(5000,$i,$j);
}

sub nextYear ($calculationDay,$known) {
    my $open = $known->{closeGateIndex};
    _ensure_gates_cover($GATE{$MIN_GATE},$GATE{$open}->copy->badd(YEAR_MAX_DAYS));
    my @candidates;
    my $j = $open + 1;
    while (1) {
        ensureGateIndex($j);
        last if $GATE{$j}->copy->bsub($GATE{$open}) > YEAR_MAX_DAYS;
        push @candidates,$j if _valid_year_pair($open,$j);
        $j++;
    }
    die "下一年沒有候選區間\n" if !@candidates;
    my $r = sauce($calculationDay,$GATE{$open});
    my $stream = askBowl($r,1,SEAL_NEXT_YEAR);
    my $rank = chooseRank($stream,scalar @candidates)->numify;
    my $close = $candidates[$rank-1];
    return _year_record($known->{number}->copy->badd(1),$open,$close);
}

sub previousYear ($calculationDay,$known) {
    my $close = $known->{openGateIndex};
    _ensure_gates_cover($GATE{$close}->copy->bsub(YEAR_MAX_DAYS),$GATE{$MAX_GATE});
    my @candidates;
    my $i = $close - 1;
    while (1) {
        ensureGateIndex($i);
        last if $GATE{$close}->copy->bsub($GATE{$i}) > YEAR_MAX_DAYS;
        push @candidates,$i if _valid_year_pair($i,$close);
        $i--;
    }
    die "上一年沒有候選區間\n" if !@candidates;
    @candidates = sort { $GATE{$close}->copy->bsub($GATE{$a}) <=> $GATE{$close}->copy->bsub($GATE{$b}) } @candidates;
    my $r = sauce($calculationDay,$GATE{$close});
    my $stream = askBowl($r,1,SEAL_PREVIOUS_YEAR);
    my $rank = chooseRank($stream,scalar @candidates)->numify;
    my $open = $candidates[$rank-1];
    return _year_record($known->{number}->copy->bsub(1),$open,$close);
}

sub findTargetYear ($calculationDay,$targetDay) {
    my $t = _bi($targetDay);
    my $y = year5000($calculationDay);
    while ($t > $y->{closeGateDay}) { $y = nextYear($calculationDay,$y) }
    while ($t <= $y->{openGateDay}) { $y = previousYear($calculationDay,$y) }
    die "目標日不在開開閉閉的年份區間內\n" if !($y->{openGateDay} < $t && $t <= $y->{closeGateDay});
    return $y;
}

sub _choose_cutlet_count ($r,$year) {
    my $gaps = $year->{closeGateIndex} - $year->{openGateIndex};
    my @candidates = grep { $_ <= $gaps } 6 .. 17;
    my $stream = askBowl($r,2,SEAL_CUTLET_COUNT);
    return $candidates[chooseRank($stream,scalar @candidates)->numify - 1];
}

sub _choose_cutlet_partition ($calculationDay,$r,$year,$K) {
    my $G = $year->{closeGateIndex} - $year->{openGateIndex};
    my $g = exactGateIndex($calculationDay);
    my $required;
    if (defined($g) && $year->{openGateIndex} < $g && $g < $year->{closeGateIndex}) {
        $required = $g - $year->{openGateIndex};
    }
    my $family = makeCutletPartitionFamily($G,$K,$required);
    my $stream = askBowl($r,2,SEAL_CUTLET_PARTITION);
    my $rank = chooseRank($stream,$family->{count}->());
    return $family->{unrank1}->($rank);
}

sub _materialize_cutlets ($year,$partition,$names) {
    my @cutlets;
    my $cursor = $year->{openGateIndex};
    for my $k (0 .. $#$partition) {
        my $open = $cursor;
        my $close = $cursor + $partition->[$k];
        ensureGateIndex($close);
        push @cutlets, {
            nameIndex => $names->[$k],
            openGateIndex => $open,
            closeGateIndex => $close,
            firstDay => $GATE{$open}->copy->badd(1),
            lastDay => $GATE{$close}->copy,
        };
        $cursor = $close;
    }
    return \@cutlets;
}

sub _choose_month_count ($r,$year) {
    my $L = $year->{closeGateDay}->copy->bsub($year->{openGateDay})->numify;
    my $lo = _ceil_div_nonnegative($L,123)->numify;
    my $hi = int($L/4); $hi = 47 if $hi > 47;
    die "月份數量界限無效\n" if $lo < 3 || $lo > $hi || $hi > 47;
    my $stream = askBowl($r,3,SEAL_MONTH_COUNT);
    return $lo + chooseRank($stream,$hi-$lo+1)->numify - 1;
}

sub _choose_month_lengths ($r,$year,$K) {
    my $L = $year->{closeGateDay}->copy->bsub($year->{openGateDay})->numify;
    my $family = makeBoundedCompositionFamily($L,$K,4,123);
    my $stream = askBowl($r,3,SEAL_MONTH_LENGTHS);
    my $rank = chooseRank($stream,$family->{count}->());
    return $family->{unrank1}->($rank);
}

sub _choose_month_weaving ($r,$lengths) {
    my $N = countWeavings($lengths);
    my $stream = askBowl($r,4,SEAL_MONTH_WEAVING);
    my $rank = chooseRank($stream,$N);
    return unrankWeaving($lengths,$rank);
}

sub buildYearStructure ($calculationDay,$year) {
    my $firstDay = $year->{openGateDay}->copy->badd(1);
    my $r = sauce($calculationDay,$firstDay);
    my $cutletCount = _choose_cutlet_count($r,$year);
    my $partition = _choose_cutlet_partition($calculationDay,$r,$year,$cutletCount);
    my $cutletNameRank = chooseRank(askBowl($r,5,SEAL_CUTLET_NAMES),fallingFactorial(17,$cutletCount));
    my $cutletNames = unrankDistinctIndices(17,$cutletCount,$cutletNameRank);
    my $cutlets = _materialize_cutlets($year,$partition,$cutletNames);
    my $monthCount = _choose_month_count($r,$year);
    my $monthLengths = _choose_month_lengths($r,$year,$monthCount);
    my $monthWeaving = _choose_month_weaving($r,$monthLengths);
    my $monthNameRank = chooseRank(askBowl($r,5,SEAL_MONTH_NAMES),fallingFactorial(47,$monthCount));
    my $monthNames = unrankDistinctIndices(47,$monthCount,$monthNameRank);
    return {
        cutletCount => $cutletCount,
        cutletPartition => $partition,
        cutletNames => $cutletNames,
        cutlets => $cutlets,
        monthCount => $monthCount,
        monthLengths => $monthLengths,
        monthWeaving => $monthWeaving,
        monthNames => $monthNames,
    };
}

sub calendarDate ($calculationDay,$targetDay) {
    my $target = _bi($targetDay);
    my $year = findTargetYear($calculationDay,$target);
    my $structure = buildYearStructure($calculationDay,$year);
    my $chosen;
    for my $c (@{ $structure->{cutlets} }) {
        if ($c->{firstDay} <= $target && $target <= $c->{lastDay}) { $chosen = $c; last }
    }
    die "找不到目標日所屬肉排\n" if !$chosen;
    my $dayInCutlet = $target->copy->bsub($chosen->{firstDay})->badd(1);
    my $offset = $target->copy->bsub($year->{openGateDay}->copy->badd(1))->numify;
    my $monthId = $structure->{monthWeaving}[$offset];
    my $dayInMonth = 0;
    for my $p (0 .. $offset) { $dayInMonth++ if $structure->{monthWeaving}[$p] == $monthId }
    return [
        $year->{number}->copy,
        cutlet_name_by_index($chosen->{nameIndex}),
        $dayInCutlet,
        month_name_by_index($structure->{monthNames}[$monthId-1]),
        Math::BigInt->new($dayInMonth),
    ];
}

1;
