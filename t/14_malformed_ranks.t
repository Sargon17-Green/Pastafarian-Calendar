use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    unrankDistinctIndices makeBoundedCompositionFamily
    makeCutletPartitionFamily unrankWeaving
);

my $bounded = makeBoundedCompositionFamily(8, 2, 3, 5);
my $partition = makeCutletPartitionFamily(6, 3);

my @targets = (
    ['名稱索引', qr/名稱排列排名超出範圍/,
        sub ($r) { unrankDistinctIndices(4, 2, $r) }, [1,3]],
    ['有界組成', qr/有界組成排名超出範圍/,
        sub ($r) { $bounded->{unrank1}->($r) }, [4,4]],
    ['肉排分割', qr/肉排分割排名超出範圍/,
        sub ($r) { $partition->{unrank1}->($r) }, [1,2,3]],
    ['月份交織', qr/月份交織排名超出範圍/,
        sub ($r) { unrankWeaving([2,2], $r) }, [1,2,1,2]],
);

for my $t (@targets) {
    my ($label,$error,$invoke,$second) = @$t;
    my @invalid = (
        undef, '', ' ', '1.5', '1e0', 'NaN', 'Infinity',
        0, '-1', '+1', ' 1', "1\n", '１',
        [], {},
        Math::BigInt->new('NaN'),
        Math::BigInt->new(-1),
        '9' x 260,
    );
    for my $input (@invalid) {
        my $warnings = '';
        my ($ok, $reason);
        {
            local $SIG{__WARN__} = sub { $warnings .= shift };
            $ok = eval { $invoke->($input); 1 };
            $reason = $@;
        }
        ok(!$ok, "$label 拒絕格式不正確或超出範圍的排名");
        like($reason, $error, "$label 使用預期的拒絕理由");
        is($warnings, '', "$label 的拒絕途徑沒有非預期的數值警告");
    }
    my $valid = Math::BigInt->new(2);
    is_deeply($invoke->($valid), $second, "$label 保留合法的大整數排名");
    is("$valid", '2', "$label 不改變傳入的排名大整數");
    is_deeply($invoke->('0002'), $second, "$label 正規化合法的前導零");
}

done_testing;
