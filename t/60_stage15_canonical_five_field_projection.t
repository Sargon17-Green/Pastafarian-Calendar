use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib';
use Pastafari::SourceLanguageCatalog qw(source_language catalog_version);
use Pastafari::Monster::CanonicalFiveFieldProjection qw(project_with_canonical_names);

# Immutable Stage01 snapshot: deliberately NOT sourced from a production accessor.
my @cutlets = qw(青銅 狐狸 腎臟 拉加什 思想 九份中的四份 帕爾古拉什 莎草 簇 蠍子 灰燼 小麥 河流 笑聲 阿卡德 角 空陶罐);
my @months = qw(黏土 石榴 手肘 嫉妒 埃里都 牙膏 五份中的三份 卡爾舒馬夫 花豹 錫 霧 乳香 紡錘 肋骨 角豆 烏魯克 羞恥 駱駝 銅 井 蛋黃 星星 蜂蜜 脾臟 石灰岩 喜悅 無花果 尼尼微 青蛙 瀝青 燈 關上的門 芝麻 後頸 銀 蘇薩 暴風雨 驢子 麵粉 後悔 巴比倫 舌頭 亞麻 鹽 梨 弓 沙);
my @frozen_cutlets = @cutlets;
my @frozen_months = @months;
my $M = Math::BigInt->new(2)->bpow(127)->bdec;

sub partial_permutations ($n, $k) {
    my $p = Math::BigInt->bone;
    $p->bmul($n - $_) for 0 .. $k - 1;
    return $p;
}

# Independent zero-based mixed-radix interpretation, then rejection-bound rank.
sub oracle_stream_rank ($first, $step, $limit) {
    my $position = Math::BigInt->new("$first")->bdec;
    my $place = Math::BigInt->bone;
    my $space = Math::BigInt->bone;
    my $word = Math::BigInt->bzero;
    for (my $j = 0; $space < $limit; ++$j) {
        my $digit = $position->copy->badd($step * $j)->bmod($M);
        $word->badd($digit->bmul($place));
        $place->bmul($M);
        $space->bmul($M);
    }
    my $accepted = $space->copy->bdiv($limit)->bmul($limit);
    $word = $step == 1 ? Math::BigInt->bzero : $accepted->copy->bdec
        if $word >= $accepted;
    return $word->bmod($limit);
}

# Lehmer / partial-factoradic unranking independent of the production selector.
sub oracle_texts ($catalog, $first, $step, $count) {
    my @pool = @$catalog;
    my $rank = oracle_stream_rank($first, $step,
                                  partial_permutations(scalar(@pool), $count));
    my @result;
    for my $slot (0 .. $count - 1) {
        my $width = partial_permutations(@pool - 1, $count - $slot - 1);
        my $digit = $rank->copy->bdiv($width)->numify;
        $rank->bmod($width);
        die "獨立字典序索引越界\n" if $digit < 0 || $digit >= @pool;
        push @result, splice(@pool, $digit, 1);
    }
    return \@result;
}

sub fixture ($length) {
    my ($cutlet_lengths, $month_lengths, $open, $number);
    if ($length == 252) {
        $cutlet_lengths = [(42) x 6];
        $month_lengths  = [84,84,84];
        ($open,$number) = (-1000,-7);
    } elsif ($length == 963) {
        $cutlet_lengths = [(160) x 5, 163];
        $month_lengths  = [(123) x 7, 102];
        ($open,$number) = (0,0);
    } else {
        die "錯誤測試年份\n" unless $length == 5778;
        $cutlet_lengths = [(340) x 16, 338];
        $month_lengths  = [(123) x 46, 120];
        ($open,$number) = (10000,5000);
    }
    my @weaving;
    push @weaving, 1 .. scalar(@$month_lengths);
    for my $i (0 .. $#$month_lengths) {
        push @weaving, ($i + 1) x ($month_lengths->[$i] - 1);
    }
    die "測試交織長度錯誤\n" if @weaving != $length;
    return {
        len => $length, open => $open, number => $number,
        year => {
            number => Math::BigInt->new($number),
            openGateDay => Math::BigInt->new($open),
            closeGateDay => Math::BigInt->new($open + $length),
        },
        structure => {
            cutletPartition => $cutlet_lengths,
            monthLengths => $month_lengths,
            monthWeaving => \@weaving,
        },
    };
}

# Full independent day-expansion of both partition and interleaving.
sub expanded_expected ($f, $cutlet_text, $month_text) {
    my @cutlet_days;
    for my $j (0 .. $#{$f->{structure}{cutletPartition}}) {
        for my $day (1 .. $f->{structure}{cutletPartition}[$j]) {
            push @cutlet_days, [$cutlet_text->[$j], $day];
        }
    }
    my @month_days;
    my @counts = (0) x scalar(@$month_text);
    for my $month (@{$f->{structure}{monthWeaving}}) {
        $counts[$month - 1]++;
        push @month_days, [$month_text->[$month - 1], $counts[$month - 1]];
    }
    die "獨立逐日展開長度錯誤\n"
        if @cutlet_days != $f->{len} || @month_days != $f->{len};
    return (\@cutlet_days, \@month_days);
}

sub sample_days ($f, $exhaustive) {
    # Each of eight stream boundaries is checked on eight separated positions;
    # the primary stream receives all segment/month transition coverage.
    if (!$exhaustive) {
        my %small = map { (1 + int($_ * ($f->{len}-1) / 7)) => 1 } 0..7;
        return sort { $a <=> $b } keys %small;
    }
    my %days = (1 => 1, $f->{len} => 1);
    $days{$_} = 1 for ($exhaustive && $f->{len} <= 963)
        ? (1 .. $f->{len})
        : (map { 1 + int($_ * ($f->{len}-1) / 31) } 0..31);
    my $acc = 0;
    for my $segment (@{$f->{structure}{cutletPartition}}) {
        $days{$acc+1} = 1;
        $acc += $segment;
        $days{$acc} = 1;
    }
    my (@first, @last);
    my $word = $f->{structure}{monthWeaving};
    for my $i (0 .. $#$word) {
        my $m = $word->[$i] - 1;
        $first[$m] //= $i+1;
        $last[$m] = $i+1;
        if ($i && $word->[$i] != $word->[$i-1]) {
            $days{$i} = 1;
            $days{$i+1} = 1;
        }
    }
    $days{$_} = 1 for @first, @last;
    return sort { $a <=> $b } keys %days;
}

is(source_language(), '繁體中文（國語）', '正式語言固定');
is(catalog_version(), '1.0.0-stage1-frozen', '正式版本固定');

my $comparisons = 0;
my $streams = 0;
my $expanded = 0;
for my $length (252,963,5778) {
    my $f = fixture($length);
    $expanded += $length;
    my @boundaries = (1,2,$M->copy->bdec,$M->copy);
    for my $first (@boundaries) {
        for my $direction (-1,1) {
            my $cutlet_text = oracle_texts(\@cutlets,$first,$direction,
                                           scalar(@{$f->{structure}{cutletPartition}}));
            my $month_text = oracle_texts(\@months,$first,-$direction,
                                          scalar(@{$f->{structure}{monthLengths}}));
            my ($expected_cutlet,$expected_month) =
                expanded_expected($f,$cutlet_text,$month_text);
            my $main = "$first" eq '1' && $direction == 1;
            my @probes = sample_days($f,$main);
            for my $day (@probes) {
                my $result = project_with_canonical_names(
                    $f->{year},$f->{structure},Math::BigInt->new($f->{open}+$day),
                    $first,$direction,$first,-$direction);
                is(scalar(@$result),5,'固定五欄');
                isa_ok($result->[0],'Math::BigInt','年份為 BigInt');
                isa_ok($result->[2],'Math::BigInt','肉排日為 BigInt');
                isa_ok($result->[4],'Math::BigInt','月份日為 BigInt');
                is("$result->[0]", "$f->{number}", '年份獨立比對');
                is($result->[1], $expected_cutlet->[$day-1][0], '肉排正式名稱獨立比對');
                is("$result->[2]", "$expected_cutlet->[$day-1][1]", '肉排日獨立比對');
                is($result->[3], $expected_month->[$day-1][0], '月份正式名稱獨立比對');
                is("$result->[4]", "$expected_month->[$day-1][1]", '交織月份日獨立比對');
                ++$comparisons;
            }
            ++$streams;
        }
    }
    for my $day ($f->{open},$f->{open}+$length+1) {
        ok(!eval { project_with_canonical_names(
            $f->{year},$f->{structure},$day,1,1,1,1); 1 },
            '開閘或閉閘次日不可用');
    }
    my $out = project_with_canonical_names(
        $f->{year},$f->{structure},$f->{open}+1,1,1,2,-1);
    $out->[0]->badd(5);
    $out->[2]->badd(5);
    $out->[4]->badd(5);
    is("$f->{year}{number}","$f->{number}",'年份物件無別名');
    is("$f->{year}{openGateDay}","$f->{open}",'開閘 BigInt 未變');
    is("$f->{year}{closeGateDay}",'' . ($f->{open}+$length),'閉閘 BigInt 未變');
    is(scalar @{$f->{structure}{monthWeaving}},$length,'交織陣列未變');
    is(scalar @{$f->{structure}{cutletPartition}},
       $length == 5778 ? 17 : 6,'肉排輸入未變');
}

my $basic = fixture(252);
my $year = $basic->{year};
my $base = $basic->{structure};
sub rejects ($description, $y, $b, $day, $cf, $cs, $mf, $ms) {
    ok(!eval { project_with_canonical_names($y,$b,$day,$cf,$cs,$mf,$ms); 1 },
       $description);
}
my $invalid = 0;
for my $spec (
    ['cutletNames',[1..6]], ['monthNames',[1,2,3]],
    ['unexpected',[]], ['cutletPartition',undef],
    ['monthLengths',[]], ['monthWeaving',{}],
    ['cutletPartition',[(42)x5]],
    ['cutletPartition',[(41)x6]],
    ['monthLengths',[84,84,83]],
    ['monthLengths',[124,84,44]],
    ['monthWeaving',[(1)x252]],
    ['monthWeaving',[0,@{$base->{monthWeaving}}[1..251]]],
) {
    my %changed = %$base;
    $changed{$spec->[0]} = $spec->[1];
    rejects('不合法結構拒絕', $year,\%changed,-999,1,1,1,1);
    ++$invalid;
}
for my $spec (
    [0,1,1,1], ['01',1,1,1], [$M->copy->binc,1,1,1],
    [1,0,1,1], [1,2,1,1],
    [1,1,0,1], [1,1,'01',1], [1,1,1,0],
    [1,1,1,2], [1,1,undef,1],
) {
    rejects('不合法名稱流拒絕', $year,$base,-999,@$spec);
    ++$invalid;
}
for my $bad_year (undef, [], {number=>1,openGateDay=>0,closeGateDay=>251}) {
    rejects('不合法年份拒絕', $bad_year,$base,-999,1,1,1,1);
    ++$invalid;
}
for my $bad_structure (undef, [], 9) {
    rejects('不合法結構型態拒絕', $year,$bad_structure,-999,1,1,1,1);
    ++$invalid;
}
my $other = project_with_canonical_names($year,$base,-999,1,1,1,1);
is($other->[1],$cutlets[0],'正式肉排名稱固定錨點');
is($other->[3],$months[0],'正式月份名稱固定錨點');
is_deeply(\@cutlets,\@frozen_cutlets,'肉排來源文字錨點未改');
is_deeply(\@months,\@frozen_months,'月份來源文字錨點未改');
note("STAGE15_INDEPENDENT_EXPANDED_DAYS=$expanded");
note("STAGE15_INDEPENDENT_DAY_COMPARISONS=$comparisons");
note("STAGE15_STREAM_BOUNDARY_CONFIGURATIONS=$streams");
note("STAGE15_INVALID_CASES=$invalid");
note('STAGE15_FULL_GENERATOR_NOT_VERIFIED');
done_testing;
