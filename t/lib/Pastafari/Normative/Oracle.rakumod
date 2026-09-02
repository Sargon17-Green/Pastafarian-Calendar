unit module Pastafari::Normative::Oracle;

use Pastafari::SourceLanguageCatalog;

our constant TABLETS_DAY is export = -278522;
our constant FOUNDATION_DAY is export = -15055671;
our constant M is export = 2**127 - 1;
our constant YEAR_MIN_DAYS is export = 252;
our constant YEAR_MAX_DAYS is export = 5778;

our constant WHEAT = 1;
our constant BARLEY = 2;
our constant SALT = 3;
our constant BITTER = 4;
our constant RED = 5;

our constant SEAL_GATE_GAP = 1;
our constant SEAL_YEAR_5000 = 10;
our constant SEAL_NEXT_YEAR = 11;
our constant SEAL_PREVIOUS_YEAR = 12;
our constant SEAL_CUTLET_COUNT = 20;
our constant SEAL_CUTLET_PARTITION = 21;
our constant SEAL_CUTLET_NAMES = 22;
our constant SEAL_MONTH_COUNT = 30;
our constant SEAL_MONTH_LENGTHS = 31;
our constant SEAL_MONTH_WEAVING = 32;
our constant SEAL_MONTH_NAMES = 33;

sub floor-div(Int:D $a, Int:D $b --> Int:D) is export {
    die 'Jagaja peab olema positiivne' unless $b >= 1;
    $a div $b
}

sub regular-mod(Int:D $x, Int:D $d --> Int:D) is export {
    die 'Mooduli jagaja peab olema positiivne' unless $d >= 1;
    $x - floor-div($x, $d) * $d
}

sub save(Int:D $x --> Int:D) is export {
    1 + regular-mod($x - 1, M)
}

sub ceil-div(Int:D $a, Int:D $b --> Int:D) is export {
    die 'Jagatav ei tohi siin olla negatiivne' unless $a >= 0;
    floor-div($a + $b - 1, $b)
}

sub wrap1(Int:D $position, Int:D $size --> Int:D) is export {
    die 'Suurus peab olema positiivne' unless $size >= 1;
    regular-mod($position - 1, $size) + 1
}

sub day-count(Int:D $day --> Int:D) is export {
    return 1 if $day == FOUNDATION_DAY;
    return 2 * ($day - FOUNDATION_DAY) + 1 if $day > FOUNDATION_DAY;
    2 * (FOUNDATION_DAY - $day)
}

class WorkCounts is export {
    has Int $.action;
    has Int $.target;
    has Int $.distance;
    has Int $.connection;
    has Int $.direction;
}

sub work-counts(Int:D $calculation-day, Int:D $target-day --> WorkCounts:D) is export {
    my $c = day-count($calculation-day);
    my $t = day-count($target-day);
    my $direction = $target-day < $calculation-day ?? 1
        !! $target-day == $calculation-day ?? 2
        !! 3;
    WorkCounts.new(
        action => $c,
        target => $t,
        distance => abs($target-day - $calculation-day) + 1,
        connection => $c + $t,
        direction => $direction,
    )
}

my constant @HIDDEN_COEFF = (
    Nil,
    [3,4,6,8], [5,7,10,12], [7,10,14,16], [9,13,18,20],
    [11,16,22,24], [13,19,26,28], [15,22,30,32],
);
my constant @HIDDEN_GRIND_STONE = (Nil, WHEAT, BARLEY, SALT, BITTER, RED, WHEAT, BARLEY);
my constant @VISIBLE_GRINDS = (
    Nil,
    [3,5,7,11,WHEAT], [5,7,11,13,BARLEY], [7,11,13,17,SALT],
    [11,13,17,19,BITTER], [13,17,19,23,RED], [17,19,23,29,WHEAT],
    [19,23,29,31,BARLEY], [23,29,31,37,SALT], [29,31,37,41,BITTER],
    [31,37,41,43,RED], [37,41,43,47,WHEAT],
);
my constant @BOWL_PRIME = (Nil,17,19,23,29,31,37);
my constant @BOWL_STIR_STONE_BY_POSITION = (Nil,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT);

sub build-stones(--> Array:D) is export {
    my @stone = Nil xx 47;
    @stone[1] = [Nil,17,29,43,71,101];
    for 2..46 -> $i {
        my @old = @stone[$i - 1].list;
        @stone[$i] = [
            Nil,
            save(@old[WHEAT]  * @old[WHEAT]  + 3  * @old[BARLEY] + $i),
            save(@old[BARLEY] * @old[BARLEY] + 5  * @old[SALT]   + @old[WHEAT]),
            save(@old[SALT]   * @old[SALT]   + 7  * @old[BITTER] + @old[BARLEY]),
            save(@old[BITTER] * @old[BITTER] + 11 * @old[RED]    + @old[SALT]),
            save(@old[RED]    * @old[RED]    + 13 * @old[WHEAT]  + @old[BITTER]),
        ];
    }
    @stone
}

sub build-hidden-drops(WorkCounts:D $counts, @stones --> Array:D) is export {
    my @hidden = Nil xx 8;
    for 1..7 -> $k {
        my @coef = @HIDDEN_COEFF[$k].list;
        my $x = $counts.action
            + @coef[0] * $counts.target
            + @coef[1] * $counts.distance
            + @coef[2] * $counts.connection
            + @coef[3] * $counts.direction
            + @stones[$k][WHEAT]
            + @stones[$k][BARLEY]
            + @stones[$k][SALT]
            + @stones[$k][BITTER]
            + @stones[$k][RED];
        $x = save($x);
        for 1..7 -> $grind {
            my $old = $x;
            $x = save(
                $old * $old + 3 * $old
                + @stones[$k][@HIDDEN_GRIND_STONE[$grind]] + $grind
            );
        }
        @hidden[$k] = $x;
    }
    @hidden
}

sub build-visible-drops(WorkCounts:D $counts, @stones, @hidden --> Array:D) is export {
    my %timeline;
    for 1..7 -> $k { %timeline{1 - $k} = @hidden[$k] }
    my @visible = Nil xx 47;
    for 1..46 -> $i {
        my $p1 = %timeline{$i - 1};
        my $p3 = %timeline{$i - 3};
        my $p7 = %timeline{$i - 7};
        my $x = save(
            @stones[$i][WHEAT] * $counts.action
            + @stones[$i][BARLEY] * $counts.target
            + @stones[$i][SALT] * $counts.distance
            + @stones[$i][BITTER] * $counts.connection
            + @stones[$i][RED] * $counts.direction
            + $p1 + 3 * $p3 + 5 * $p7 + $i
        );
        for 1..11 -> $grind {
            my @row = @VISIBLE_GRINDS[$grind].list;
            my $old = $x;
            $x = save(
                $old * $old + @row[0] * $old + @row[1] * $p1
                + @row[2] * $p3 + @row[3] * $p7 + @stones[$i][@row[4]]
            );
        }
        %timeline{$i} = $x;
        @visible[$i] = $x;
    }
    @visible
}

sub factorial(Int:D $n --> Int:D) is export {
    die 'Faktoriaali argument ei tohi olla negatiivne' if $n < 0;
    my Int $r = 1;
    if $n >= 2 {
        for 2..$n -> $v { $r *= $v }
    }
    $r
}

sub permutation-unrank1(Int:D $rank1, @items --> Array:D) is export {
    my @remaining = @items.list;
    my @result;
    my Int $rank0 = $rank1 - 1;
    die 'Permutatsiooni aste on vahemikust väljas'
        unless 0 <= $rank0 < factorial(@remaining.elems);
    while @remaining.elems > 0 {
        my $block = factorial(@remaining.elems - 1);
        my $q = floor-div($rank0, $block);
        $rank0 = regular-mod($rank0, $block);
        @result.push(@remaining[$q]);
        @remaining.splice($q, 1);
    }
    @result
}

sub bowl-order-from-number(Int:D $order-number --> Array:D) is export {
    die 'Kausijärjekorra number peab olema 1..720' unless 1 <= $order-number <= 720;
    permutation-unrank1($order-number, [1,2,3,4,5,6])
}

sub bowl-order-from-drop(Int:D $drop --> Array:D) is export {
    bowl-order-from-number(regular-mod($drop - 1, 720) + 1)
}

sub initial-bowls(WorkCounts:D $counts --> Array:D) is export {
    my @bowls = Nil xx 7;
    for 1..6 -> $id {
        my $s = $counts.action + $counts.target * $id + $counts.distance
            + $counts.connection + $counts.direction + @BOWL_PRIME[$id] ** 2;
        @bowls[$id] = save($s * $s + $id);
    }
    @bowls
}

sub apply-visible-drops-to-bowls(@bowls-in, @visible, @stones --> List:D) is export {
    my @bowls = @bowls-in.list;
    my @order46;
    for 1..46 -> $i {
        my $drop = @visible[$i];
        my @order = bowl-order-from-drop($drop);
        my @old = @bowls.list;
        my @pour = 0 xx 7;
        my $first = @order[0];
        my $second = @order[1];
        my $third = @order[2];
        @pour[1] = save($drop*$drop + @stones[$i][WHEAT] * @old[$first] + 3*$i);
        @pour[2] = save($drop*$drop + @stones[$i][BARLEY] * @old[$second] + 5*$i);
        @pour[3] = save($drop*$drop + @stones[$i][SALT] * @old[$third] + 7*$i);
        my @next = @old.list;
        for 1..6 -> $position {
            my $id = @order[$position - 1];
            my $prev = @order[wrap1($position - 1, 6) - 1];
            my $next-id = @order[wrap1($position + 1, 6) - 1];
            my $kind = @BOWL_STIR_STONE_BY_POSITION[$position];
            my $s = @old[$id] + 2*@old[$prev] + 3*@old[$next-id]
                + @pour[$position] + $drop + @stones[$i][$kind];
            @next[$id] = save($s*$s + 5*@old[$prev]*@old[$next-id] + $i*$position);
        }
        @bowls = @next;
        @order46 = @order.list if $i == 46;
    }
    (@bowls, @order46)
}

sub post-stir12(@bowls-in --> Array:D) is export {
    my @bowls = @bowls-in.list;
    for 1..12 -> $stir {
        my @old = @bowls.list;
        my $saved = save([+] @old[1..6] + 149*$stir);
        my @order = bowl-order-from-number(regular-mod($saved - 1, 720) + 1);
        my @next = @old.list;
        for 1..6 -> $position {
            my $id = @order[$position - 1];
            my $prev = @order[wrap1($position - 1, 6) - 1];
            my $next-id = @order[wrap1($position + 1, 6) - 1];
            my $s = @old[$id] + 3*@old[$prev] + 5*@old[$next-id]
                + $saved + $stir + $position*$position;
            @next[$id] = save($s*$s + 7*@old[$prev]*@old[$next-id]);
        }
        @bowls = @next;
    }
    @bowls
}

class SauceResult is export {
    has @.bowls;
    has @.orderAt46;
}

sub sauce(Int:D $calculation-day, Int:D $target-day --> SauceResult:D) is export {
    state @stones = build-stones();
    my $counts = work-counts($calculation-day, $target-day);
    my @hidden = build-hidden-drops($counts, @stones);
    my @visible = build-visible-drops($counts, @stones, @hidden);
    my @bowls = initial-bowls($counts);
    my (@after, @order46) = apply-visible-drops-to-bowls(@bowls, @visible, @stones);
    my @final = post-stir12(@after);
    SauceResult.new(bowls => @final, orderAt46 => @order46)
}

sub next-bowl-in-drop46-order(SauceResult:D $result, Int:D $queried --> Int:D) is export {
    my $pos = $result.orderAt46.first(* == $queried, :k);
    die 'Kausi ID puudub 46. tilga järjekorrast' unless $pos.defined;
    $result.orderAt46[($pos + 1) % 6]
}

class AnswerStream is export {
    has Int $.first;
    has Int $.step;
}

sub ask-bowl(SauceResult:D $result, Int:D $queried, Int:D $seal --> AnswerStream:D) is export {
    my $next = next-bowl-in-drop46-order($result, $queried);
    my $first = save(
        ($result.bowls[$queried] + $seal + 181) ** 2
        + 179 * $result.bowls[$next] + $seal
    );
    my $direction = save(
        ($first + $seal + 1 + 193) ** 2
        + 193 * $first + 197 * $result.bowls[6]
    );
    AnswerStream.new(first => $first, step => regular-mod($direction, 2) == 1 ?? 1 !! -1)
}

sub answer-at(AnswerStream:D $stream, Int:D $k --> Int:D) is export {
    1 + regular-mod($stream.first - 1 + $stream.step * $k, M)
}

sub choose-rank-short(AnswerStream:D $stream, Int:D $n --> Int:D) is export {
    die 'Lühivaliku N peab olema vahemikus 1..M' unless 1 <= $n <= M;
    my $limit = floor-div(M, $n) * $n;
    my Int $k = 0;
    loop {
        my $x = answer-at($stream, $k);
        return regular-mod($x - 1, $n) + 1 if $x <= $limit;
        $k++;
    }
}

sub smallest-power-count(Int:D $base, Int:D $n --> List:D) is export {
    my Int $k = 1;
    my Int $space = $base;
    while $space < $n { $k++; $space *= $base }
    ($k, $space)
}

sub choose-rank-wide(AnswerStream:D $stream, Int:D $n --> Int:D) is export {
    die 'Laia valiku N peab olema suurem kui M' unless $n > M;
    my ($k, $space) = smallest-power-count(M, $n);
    my Int $wide = 1;
    my Int $weight = 1;
    for 0..^$k -> $j {
        $wide += (answer-at($stream, $j) - 1) * $weight;
        $weight *= M;
    }
    my $limit = floor-div($space, $n) * $n;
    while $wide > $limit {
        $wide = 1 + regular-mod($wide - 1 + $stream.step, $space);
    }
    regular-mod($wide - 1, $n) + 1
}

sub choose-rank(AnswerStream:D $stream, Int:D $n --> Int:D) is export {
    die 'Valikuruum peab olema positiivne' unless $n >= 1;
    $n <= M ?? choose-rank-short($stream, $n) !! choose-rank-wide($stream, $n)
}

sub falling-factorial(Int:D $n, Int:D $k --> Int:D) is export {
    die 'Osalise permutatsiooni mõõtmed on vigased' unless 0 <= $k <= $n;
    my Int $r = 1;
    for 0..^$k -> $j { $r *= ($n - $j) }
    $r
}

sub unrank-distinct-indices(Int:D $master-count, Int:D $k, Int:D $rank1 --> Array:D) is export {
    my @remaining = 1..$master-count;
    my @out;
    my Int $r = $rank1;
    die 'Nimeastme väärtus on vahemikust väljas'
        unless 1 <= $r <= falling-factorial($master-count, $k);
    for 1..$k -> $position {
        my $suffix = $k - $position;
        my $block = falling-factorial(@remaining.elems - 1, $suffix);
        for 0..^@remaining.elems -> $candidate {
            if $r > $block { $r -= $block }
            else {
                @out.push(@remaining[$candidate]);
                @remaining.splice($candidate, 1);
                last;
            }
        }
    }
    @out
}

class BoundedCompositionFamily is export {
    has Int $.total;
    has Int $.slots;
    has Int $.lo;
    has Int $.hi;
    has %!memo;

    method !count(Int:D $rem, Int:D $slots --> Int:D) {
        return $rem == 0 ?? 1 !! 0 if $slots == 0;
        return 0 if $rem < $slots * $!lo || $rem > $slots * $!hi;
        my $key = "$rem|$slots";
        return %!memo{$key} if %!memo{$key}:exists;
        my Int $sum = 0;
        for $!lo..$!hi -> $x { $sum += self!count($rem - $x, $slots - 1) }
        %!memo{$key} = $sum;
        $sum
    }

    method count(--> Int:D) { self!count($!total, $!slots) }

    method unrank1(Int:D $rank1 --> Array:D) {
        die 'Kompositsiooni aste on vahemikust väljas' unless 1 <= $rank1 <= self.count;
        my Int $r = $rank1;
        my Int $rem = $!total;
        my Int $slots = $!slots;
        my @out;
        while $slots > 0 {
            for $!lo..$!hi -> $x {
                my $block = self!count($rem - $x, $slots - 1);
                if $r > $block { $r -= $block }
                else { @out.push($x); $rem -= $x; $slots--; last }
            }
        }
        @out
    }
}

class CutletPartitionFamily is export {
    has Int $.gaps;
    has Int $.parts;
    has Int $.required = -1;
    has %!memo;

    method !count(Int:D $rem, Int:D $slots, Int:D $cumulative, Bool:D $hit --> Int:D) {
        if $slots == 0 {
            return 0 if $rem != 0;
            return 1 if $!required < 0;
            return $hit ?? 1 !! 0;
        }
        return 0 if $rem < $slots;
        my $key = "$rem|$slots|$cumulative|{$hit ?? 1 !! 0}";
        return %!memo{$key} if %!memo{$key}:exists;
        my Int $total = 0;
        my $max-x = $rem - ($slots - 1);
        for 1..$max-x -> $x {
            my $next-c = $cumulative + $x;
            my $next-hit = $hit;
            if $!required >= 0 && !$hit {
                if $next-c == $!required { $next-hit = True }
                elsif $next-c > $!required { next }
            }
            $total += self!count($rem - $x, $slots - 1, $next-c, $next-hit);
        }
        %!memo{$key} = $total;
        $total
    }

    method count(--> Int:D) { self!count($!gaps, $!parts, 0, False) }

    method unrank1(Int:D $rank1 --> Array:D) {
        die 'Kotletijaotuse aste on vahemikust väljas' unless 1 <= $rank1 <= self.count;
        my Int $r = $rank1;
        my Int $rem = $!gaps;
        my Int $slots = $!parts;
        my Int $cumulative = 0;
        my Bool $hit = False;
        my @out;
        while $slots > 0 {
            my $max-x = $rem - ($slots - 1);
            for 1..$max-x -> $x {
                my $next-c = $cumulative + $x;
                my $next-hit = $hit;
                if $!required >= 0 && !$hit {
                    if $next-c == $!required { $next-hit = True }
                    elsif $next-c > $!required { next }
                }
                my $block = self!count($rem - $x, $slots - 1, $next-c, $next-hit);
                if $r > $block { $r -= $block }
                else {
                    @out.push($x);
                    $rem -= $x;
                    $slots--;
                    $cumulative = $next-c;
                    $hit = $next-hit;
                    last;
                }
            }
        }
        @out
    }
}

class WeavingFamily is export {
    has @.lengths;
    has %!memo;

    method !key(@remaining, Int:D $opened, Int:D $closed --> Str:D) {
        @remaining.join(',') ~ "|$opened|$closed"
    }

    method !legal(@remaining, Int:D $opened, Int:D $closed, Int:D $j --> Bool:D) {
        return False if @remaining[$j - 1] == 0;
        my $already = @remaining[$j - 1] < @!lengths[$j - 1];
        return False if !$already && $j != $opened + 1;
        my $will-close = @remaining[$j - 1] == 1;
        return False if $will-close && $j != $closed + 1;
        True
    }

    method !apply(@remaining, Int:D $opened, Int:D $closed, Int:D $j --> List:D) {
        my @next = @remaining.list;
        my Int $next-opened = $opened;
        my Int $next-closed = $closed;
        $next-opened = $j if @next[$j - 1] == @!lengths[$j - 1];
        @next[$j - 1]--;
        $next-closed = $j if @next[$j - 1] == 0;
        (@next, $next-opened, $next-closed)
    }

    method !count(@remaining, Int:D $opened, Int:D $closed --> Int:D) {
        return 1 if [+] @remaining == 0;
        my $key = self!key(@remaining, $opened, $closed);
        return %!memo{$key} if %!memo{$key}:exists;
        my Int $total = 0;
        for 1..@!lengths.elems -> $j {
            next unless self!legal(@remaining, $opened, $closed, $j);
            my (@next, $no, $nc) = self!apply(@remaining, $opened, $closed, $j);
            $total += self!count(@next, $no, $nc);
        }
        %!memo{$key} = $total;
        $total
    }

    method count(--> Int:D) { self!count(@!lengths.list, 0, 0) }

    method unrank1(Int:D $rank1 --> Array:D) {
        die 'Kuuarhiku aste on vahemikust väljas' unless 1 <= $rank1 <= self.count;
        my Int $r = $rank1;
        my @remaining = @!lengths.list;
        my Int $opened = 0;
        my Int $closed = 0;
        my @out;
        while [+] @remaining > 0 {
            for 1..@!lengths.elems -> $j {
                next unless self!legal(@remaining, $opened, $closed, $j);
                my (@next, $no, $nc) = self!apply(@remaining, $opened, $closed, $j);
                my $block = self!count(@next, $no, $nc);
                if $r > $block { $r -= $block }
                else {
                    @out.push($j);
                    @remaining = @next;
                    $opened = $no;
                    $closed = $nc;
                    last;
                }
            }
        }
        @out
    }
}

class Year is export {
    has Int $.number;
    has Int $.openGateIndex;
    has Int $.closeGateIndex;
    has Int $.openGateDay;
    has Int $.closeGateDay;
}

class YearStructure is export {
    has Int $.cutletCount;
    has @.cutletPartition;
    has @.cutletNameIndices;
    has @.cutlets;
    has Int $.monthCount;
    has @.monthLengths;
    has @.monthWeaving;
    has @.monthNameIndices;
}

class NormativeOracle is export {
    has %!gate;
    has Int $!minKnown = 0;
    has Int $!maxKnown = 0;

    submethod BUILD() { %!gate{0} = FOUNDATION_DAY }

    method gate-day(Int:D $index --> Int:D) { self.ensure-gate-index($index); %!gate{$index} }

    method positive-gate-gap(Int:D $n --> Int:D) {
        die 'Positiivse väravasammu indeks peab olema vähemalt üks' unless $n >= 1;
        my $r = sauce(FOUNDATION_DAY, FOUNDATION_DAY + $n);
        41 + choose-rank(ask-bowl($r, 1, SEAL_GATE_GAP), 922)
    }

    method negative-gate-gap(Int:D $n --> Int:D) {
        die 'Negatiivse väravasammu suurus peab olema vähemalt üks' unless $n >= 1;
        my $r = sauce(FOUNDATION_DAY, FOUNDATION_DAY - $n);
        41 + choose-rank(ask-bowl($r, 1, SEAL_GATE_GAP), 922)
    }

    method ensure-gate-index(Int:D $k --> Int:D) {
        while $!maxKnown < $k {
            my $n = $!maxKnown + 1;
            %!gate{$n} = %!gate{$n - 1} + self.positive-gate-gap($n);
            $!maxKnown = $n;
        }
        while $!minKnown > $k {
            my $n = $!minKnown - 1;
            %!gate{$n} = %!gate{$n + 1} - self.negative-gate-gap(abs($n));
            $!minKnown = $n;
        }
        %!gate{$k}
    }

    method ensure-gates-cover(Int:D $low, Int:D $high --> Nil) {
        die 'Väravate katmisvahemik on tagurpidi' if $low > $high;
        while %!gate{$!minKnown} > $low { self.ensure-gate-index($!minKnown - 1) }
        while %!gate{$!maxKnown} < $high { self.ensure-gate-index($!maxKnown + 1) }
    }

    method gate-index-at-or-before(Int:D $day --> Int:D) {
        self.ensure-gates-cover($day, $day);
        my Int $lo = $!minKnown;
        my Int $hi = $!maxKnown;
        while $lo < $hi {
            my $mid = $lo + floor-div($hi - $lo + 1, 2);
            if %!gate{$mid} <= $day { $lo = $mid } else { $hi = $mid - 1 }
        }
        $lo
    }

    method exact-gate-index(Int:D $day) {
        my $i = self.gate-index-at-or-before($day);
        %!gate{$i} == $day ?? $i !! Nil
    }

    method valid-year-pair(Int:D $open, Int:D $close --> Bool:D) {
        return False if $close - $open < 6;
        self.ensure-gate-index($open);
        self.ensure-gate-index($close);
        my $length = %!gate{$close} - %!gate{$open};
        YEAR_MIN_DAYS <= $length <= YEAR_MAX_DAYS
    }

    method year5000(Int:D $calculation-day --> Year:D) {
        self.ensure-gates-cover($calculation-day - YEAR_MAX_DAYS, $calculation-day + YEAR_MAX_DAYS);
        my @candidates;
        for $!minKnown..^$!maxKnown -> $i {
            for ($i + 6)..$!maxKnown -> $j {
                my $length = %!gate{$j} - %!gate{$i};
                last if $length > YEAR_MAX_DAYS;
                next if $length < YEAR_MIN_DAYS;
                next unless %!gate{$i} < $calculation-day <= %!gate{$j};
                @candidates.push([$i, $j, $length, %!gate{$i}]);
            }
        }
        die 'Aasta 5000 kandidaatide hulk on tühi' unless @candidates.elems;
        @candidates = @candidates.sort(-> $a, $b {
            ($a[2] <=> $b[2]) || ($a[3] <=> $b[3])
        });
        my $rank = choose-rank(ask-bowl(sauce($calculation-day, $calculation-day), 1, SEAL_YEAR_5000), @candidates.elems);
        my @c = @candidates[$rank - 1].list;
        Year.new(number => 5000, openGateIndex => @c[0], closeGateIndex => @c[1],
            openGateDay => %!gate{@c[0]}, closeGateDay => %!gate{@c[1]})
    }

    method next-year(Int:D $calculation-day, Year:D $known --> Year:D) {
        my $open = $known.closeGateIndex;
        self.ensure-gate-index($open);
        self.ensure-gates-cover(%!gate{$open}, %!gate{$open} + YEAR_MAX_DAYS);
        my @candidates;
        my $j = $open + 1;
        loop {
            self.ensure-gate-index($j);
            my $length = %!gate{$j} - %!gate{$open};
            last if $length > YEAR_MAX_DAYS;
            @candidates.push([$j, $length]) if self.valid-year-pair($open, $j);
            $j++;
        }
        @candidates = @candidates.sort(-> $a,$b { $a[1] <=> $b[1] });
        my $rank = choose-rank(ask-bowl(sauce($calculation-day, %!gate{$open}), 1, SEAL_NEXT_YEAR), @candidates.elems);
        my $close = @candidates[$rank - 1][0];
        Year.new(number => $known.number + 1, openGateIndex => $open, closeGateIndex => $close,
            openGateDay => %!gate{$open}, closeGateDay => %!gate{$close})
    }

    method previous-year(Int:D $calculation-day, Year:D $known --> Year:D) {
        my $close = $known.openGateIndex;
        self.ensure-gate-index($close);
        self.ensure-gates-cover(%!gate{$close} - YEAR_MAX_DAYS, %!gate{$close});
        my @candidates;
        my $i = $close - 1;
        loop {
            self.ensure-gate-index($i);
            my $length = %!gate{$close} - %!gate{$i};
            last if $length > YEAR_MAX_DAYS;
            @candidates.push([$i, $length]) if self.valid-year-pair($i, $close);
            $i--;
        }
        @candidates = @candidates.sort(-> $a,$b { $a[1] <=> $b[1] });
        my $rank = choose-rank(ask-bowl(sauce($calculation-day, %!gate{$close}), 1, SEAL_PREVIOUS_YEAR), @candidates.elems);
        my $open = @candidates[$rank - 1][0];
        Year.new(number => $known.number - 1, openGateIndex => $open, closeGateIndex => $close,
            openGateDay => %!gate{$open}, closeGateDay => %!gate{$close})
    }

    method find-target-year(Int:D $calculation-day, Int:D $target-day --> Year:D) {
        my $year = self.year5000($calculation-day);
        while $target-day > $year.closeGateDay { $year = self.next-year($calculation-day, $year) }
        while $target-day <= $year.openGateDay { $year = self.previous-year($calculation-day, $year) }
        die 'Päringupäev ei langenud avatud-suletud aastavahemikku'
            unless $year.openGateDay < $target-day <= $year.closeGateDay;
        $year
    }

    method choose-cutlet-count(SauceResult:D $r, Year:D $year --> Int:D) {
        my $gaps = $year.closeGateIndex - $year.openGateIndex;
        my @candidates = (6..17).grep(* <= $gaps);
        my $rank = choose-rank(ask-bowl($r, 2, SEAL_CUTLET_COUNT), @candidates.elems);
        @candidates[$rank - 1]
    }

    method choose-cutlet-partition(Int:D $calculation-day, SauceResult:D $r, Year:D $year, Int:D $count --> Array:D) {
        my $gaps = $year.closeGateIndex - $year.openGateIndex;
        my $g = self.exact-gate-index($calculation-day);
        my Int $required = -1;
        if $g.defined && $year.openGateIndex < $g < $year.closeGateIndex {
            $required = $g - $year.openGateIndex;
        }
        my $family = CutletPartitionFamily.new(gaps => $gaps, parts => $count, required => $required);
        my $rank = choose-rank(ask-bowl($r, 2, SEAL_CUTLET_PARTITION), $family.count);
        $family.unrank1($rank)
    }

    method choose-cutlet-name-indices(SauceResult:D $r, Int:D $count --> Array:D) {
        my $n = falling-factorial(17, $count);
        my $rank = choose-rank(ask-bowl($r, 5, SEAL_CUTLET_NAMES), $n);
        unrank-distinct-indices(17, $count, $rank)
    }

    method materialize-cutlets(Year:D $year, @partition, @name-indices --> Array:D) {
        my @out;
        my $cursor = $year.openGateIndex;
        for 0..^@partition.elems -> $idx {
            my $open = $cursor;
            my $close = $cursor + @partition[$idx];
            self.ensure-gate-index($close);
            @out.push({
                nameIndex => @name-indices[$idx],
                openGateIndex => $open,
                closeGateIndex => $close,
                firstDay => %!gate{$open} + 1,
                lastDay => %!gate{$close},
            });
            $cursor = $close;
        }
        @out
    }

    method choose-month-count(SauceResult:D $r, Year:D $year --> Int:D) {
        my $length = $year.closeGateDay - $year.openGateDay;
        my $min = ceil-div($length, 123);
        my $max = min(47, floor-div($length, 4));
        die 'Kuuarvu piirid on vastuolulised' unless 3 <= $min <= $max <= 47;
        my $rank = choose-rank(ask-bowl($r, 3, SEAL_MONTH_COUNT), $max - $min + 1);
        $min + $rank - 1
    }

    method choose-month-lengths(SauceResult:D $r, Year:D $year, Int:D $count --> Array:D) {
        my $length = $year.closeGateDay - $year.openGateDay;
        my $family = BoundedCompositionFamily.new(total => $length, slots => $count, lo => 4, hi => 123);
        my $rank = choose-rank(ask-bowl($r, 3, SEAL_MONTH_LENGTHS), $family.count);
        $family.unrank1($rank)
    }

    method choose-month-weaving(SauceResult:D $r, @lengths --> Array:D) {
        my $family = WeavingFamily.new(lengths => @lengths.list);
        my $rank = choose-rank(ask-bowl($r, 4, SEAL_MONTH_WEAVING), $family.count);
        $family.unrank1($rank)
    }

    method choose-month-name-indices(SauceResult:D $r, Int:D $count --> Array:D) {
        my $n = falling-factorial(47, $count);
        my $rank = choose-rank(ask-bowl($r, 5, SEAL_MONTH_NAMES), $n);
        unrank-distinct-indices(47, $count, $rank)
    }

    method build-year-structure(Int:D $calculation-day, Year:D $year --> YearStructure:D) {
        my $first-day = $year.openGateDay + 1;
        my $r = sauce($calculation-day, $first-day);
        my $cutlet-count = self.choose-cutlet-count($r, $year);
        my @partition = self.choose-cutlet-partition($calculation-day, $r, $year, $cutlet-count);
        my @cutlet-names = self.choose-cutlet-name-indices($r, $cutlet-count);
        my @cutlets = self.materialize-cutlets($year, @partition, @cutlet-names);
        my $month-count = self.choose-month-count($r, $year);
        my @month-lengths = self.choose-month-lengths($r, $year, $month-count);
        my @weaving = self.choose-month-weaving($r, @month-lengths);
        my @month-names = self.choose-month-name-indices($r, $month-count);
        YearStructure.new(
            cutletCount => $cutlet-count,
            cutletPartition => @partition,
            cutletNameIndices => @cutlet-names,
            cutlets => @cutlets,
            monthCount => $month-count,
            monthLengths => @month-lengths,
            monthWeaving => @weaving,
            monthNameIndices => @month-names,
        )
    }

    method calendar-date-indices(Int:D $calculation-day, Int:D $target-day --> Array:D) {
        my $year = self.find-target-year($calculation-day, $target-day);
        my $s = self.build-year-structure($calculation-day, $year);
        my $cutlet-id = Nil;
        for 0..^$s.cutlets.elems -> $idx {
            my %c = $s.cutlets[$idx];
            if %c<firstDay> <= $target-day <= %c<lastDay> { $cutlet-id = $idx; last }
        }
        die 'Päeva kotletti ei leitud' unless $cutlet-id.defined;
        my %cutlet = $s.cutlets[$cutlet-id];
        my $day-in-cutlet = $target-day - %cutlet<firstDay> + 1;
        my $offset = $target-day - ($year.openGateDay + 1);
        my $month-id = $s.monthWeaving[$offset];
        my Int $day-in-month = 0;
        for 0..$offset -> $p { $day-in-month++ if $s.monthWeaving[$p] == $month-id }
        [
            $year.number,
            %cutlet<nameIndex>,
            $day-in-cutlet,
            $s.monthNameIndices[$month-id - 1],
            $day-in-month,
        ]
    }

    method calendar-date(Int:D $calculation-day, Int:D $target-day --> Array:D) {
        my @idx = self.calendar-date-indices($calculation-day, $target-day);
        [@idx[0], cutlet-name(@idx[1]), @idx[2], month-name(@idx[3]), @idx[4]]
    }
}
