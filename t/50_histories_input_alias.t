use v5.40;
use utf8;
use open qw(:std :encoding(UTF-8));
use strict;
use warnings;
use Test::More;
use Math::BigInt;
use Scalar::Util qw(refaddr);
use lib 'lib','t/lib';
use Pastafari::WeavingPolynomial qw(countWeavingsPolynomial);
use Pastafari::WeavingPolynomialStream qw(countWeavingsPolynomialStream);

# 首次位置直方圖是「輸出」參照。若和來源長度陣列
# 相同，它既不能被清空，也不能在成功後仍是來源輸入。
# 兩種引擎必須在任何輸入修改之前明確拒絕，不可靜默回傳 1。
for my $case (
    ['empty',[]],
    ['single',[5]],
    ['months',[3,2,4]],
    ['BigInt',[Math::BigInt->new(3),Math::BigInt->new(2)]],
) {
    my ($label,$original) = @$case;
    for my $engine (
        ['resident',sub ($v) { countWeavingsPolynomial($v,undef,$v) }],
        ['stream',sub ($v) { countWeavingsPolynomialStream($v,undef,$v) }],
    ) {
        my ($name,$work) = @$engine;
        my @input = @$original;
        my @values = map { defined($_) ? "$_" : undef } @input;
        my @objects = map { ref($_) ? refaddr($_) : undef } @input;
        my $addr=refaddr(\@input);
        my $ok=eval {$work->(\@input);1};
        ok(!$ok,"$name/$label: 相同輸入輸出參照被拒絕");
        like($@,qr/不可共用同一陣列參照/,
            "$name/$label: 明確區分不安全別名而非意外例外");
        is(refaddr(\@input),$addr,"$name/$label: 陣列參照保持原始位址");
        is_deeply([map {defined($_) ? "$_" : undef} @input],\@values,
            "$name/$label: 所有來源長度在拒絕後不變");
        is_deeply([map {ref($_) ? refaddr($_) : undef} @input],\@objects,
            "$name/$label: 來源 BigInt 身分保持未變");
    }
}

# 不同輸入輸出參照仍可照常使用，正常輸入不受影響。
my @a=(2,3,2);
my @resident_hist;
my @stream_hist;
my $expected=countWeavingsPolynomial(\@a,undef,\@resident_hist);
my $actual=countWeavingsPolynomialStream(\@a,undef,\@stream_hist);
is("$actual","$expected",'兩個模型在正常不同輸入輸出時精確一致');
is_deeply(\@a,[2,3,2],'正常成功也沒有修改來源月份長度');
for my $i (1..3) {
    my $as_strings=sub ($hist) {
        return [map {defined($_) ? "$_" : undef} @$hist];
    };
    is_deeply($as_strings->($stream_hist[$i]),
              $as_strings->($resident_hist[$i]),
              "成功時第 $i 階段直方圖仍精確一致");
}
done_testing;
