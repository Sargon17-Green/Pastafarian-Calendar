use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use lib 'lib', 't/lib';
use Pastafari::NormativeScroll qw(
    fallingFactorial unrankDistinctIndices makeBoundedCompositionFamily
    makeCutletPartitionFamily countWeavings unrankWeaving
);
use Pastafari::Monster::BaseContext;

sub rejects_rank ($title, $expected, $callback) {
    my $ok = eval { $callback->(); 1 };
    my $error = $@;
    ok(!$ok, "$title：不接受無效排名");
    like($error, $expected, "$title：提供明確的錯誤原因");
}

my $big = Math::BigInt->new('9' x 250);

for my $rank (0, -1, 7, $big) {
    rejects_rank("名稱索引 n3 k2 rank $rank", qr/名稱排列排名超出範圍/,
        sub { unrankDistinctIndices(3, 2, $rank) });
}
rejects_rank('名稱數不足', qr/名稱排列參數超出範圍/,
    sub { unrankDistinctIndices(3, 4, 1) });
is_deeply(unrankDistinctIndices(3, 2, 6), [3,2],
    '名稱最後一個合法排名仍可使用');
is_deeply(unrankDistinctIndices(3, 0, 1), [],
    '零個名稱有唯一合法空排列');

my $bounded = makeBoundedCompositionFamily(8, 2, 3, 5);
is('' . $bounded->{count}->(), '3', '有界組成示例仍有三列');
for my $rank (0, -1, 4, $big) {
    rejects_rank("有界組成 rank $rank", qr/有界組成排名超出範圍/,
        sub { $bounded->{unrank1}->($rank) });
}
is_deeply($bounded->{unrank1}->(3), [5,3],
    '有界組成最後一個合法排名仍正確');
my $empty_bounded = makeBoundedCompositionFamily(1, 2, 3, 5);
is('' . $empty_bounded->{count}->(), '0', '無解的有界組成計數為零');
rejects_rank('無解的有界組成', qr/有界組成排名超出範圍/,
    sub { $empty_bounded->{unrank1}->(1) });

my $partition = makeCutletPartitionFamily(6, 3);
is('' . $partition->{count}->(), '10', '六分成三個正整數共有十列');
for my $rank (0, -1, 11, $big) {
    rejects_rank("肉排分割 rank $rank", qr/肉排分割排名超出範圍/,
        sub { $partition->{unrank1}->($rank) });
}
is_deeply($partition->{unrank1}->(10), [4,1,1],
    '肉排分割最後一個合法排名仍正確');
my $empty_partition = makeCutletPartitionFamily(3, 4);
is('' . $empty_partition->{count}->(), '0', '無解的肉排分割計數為零');
rejects_rank('無解的肉排分割', qr/肉排分割排名超出範圍/,
    sub { $empty_partition->{unrank1}->(1) });

is('' . countWeavings([2,2]), '2', '兩個二日月份合法交織有兩列');
for my $rank (0, -1, 3, $big) {
    rejects_rank("月份交織 rank $rank", qr/月份交織排名超出範圍/,
        sub { unrankWeaving([2,2], $rank) });
}
is_deeply(unrankWeaving([2,2],2), [1,2,1,2],
    '月份交織最後一個合法排名仍正確');

my $ctx = Pastafari::Monster::BaseContext->new();
$ctx->{semanticState}{nested} = {
    days => [Math::BigInt->new('123456789012345678901234567890')],
    mark => { valid => 1 },
};
my $snap = $ctx->semantic_snapshot();
$snap->{nested}{days}[0]->badd(99);
$snap->{nested}{mark}{valid} = 0;
is('' . $ctx->{semanticState}{nested}{days}[0],
    '123456789012345678901234567890',
    '修改快照中深層的 Math::BigInt 不會回寫語意狀態');
is($ctx->{semanticState}{nested}{mark}{valid},1,
    '修改快照中深層的雜湊不會回寫語意狀態');
isnt($snap->{nested}{days}[0], $ctx->{semanticState}{nested}{days}[0],
    '大型整數本體在快照與語意狀態之間並不共用');

done_testing;
