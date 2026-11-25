<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/src/BigInt.php';
use Pastafari\Stage01\BigInt;

function stage56DecimalMultiply(string $left, string $right): string
{
    $left = ltrim($left, '0') ?: '0';
    $right = ltrim($right, '0') ?: '0';
    if ($left === '0' || $right === '0') return '0';
    $a = array_map('intval', str_split($left));
    $b = array_map('intval', str_split($right));
    $out = array_fill(0, count($a) + count($b), 0);
    for ($i = count($a) - 1; $i >= 0; --$i) {
        $carry = 0;
        for ($j = count($b) - 1; $j >= 0; --$j) {
            $index = $i + $j + 1;
            $value = $out[$index] + $a[$i] * $b[$j] + $carry;
            $out[$index] = $value % 10;
            $carry = intdiv($value, 10);
        }
        $out[$i] += $carry;
    }
    for ($i = count($out) - 1; $i > 0; --$i) {
        if ($out[$i] >= 10) {
            $carry = intdiv($out[$i], 10);
            $out[$i] %= 10;
            $out[$i - 1] += $carry;
        }
    }
    $result = ltrim(implode('', $out), '0');
    return $result === '' ? '0' : $result;
}
function stage56DecimalDivideSmall(string $value, int $divisor): array
{
    if ($divisor <= 0) throw new InvalidArgumentException('TEST_DIVISOR');
    $value = ltrim($value, '0') ?: '0';
    $quotient = '';
    $remainder = 0;
    foreach (str_split($value) as $digit) {
        $current = $remainder * 10 + (int)$digit;
        $quotientDigit = intdiv($current, $divisor);
        $remainder = $current % $divisor;
        if ($quotient !== '' || $quotientDigit !== 0) $quotient .= (string)$quotientDigit;
    }
    return [$quotient === '' ? '0' : $quotient, $remainder];
}

function stage56DeterministicDigits(int $length, int $seed): string
{
    $state = $seed;
    $out = '';
    for ($i = 0; $i < $length; ++$i) {
        $state = ($state * 1103515245 + 12345) & 0x7fffffff;
        $digit = $state % 10;
        if ($i === 0 && $digit === 0) $digit = 7;
        $out .= (string) $digit;
    }
    return $out;
}
$cases = [[1, 1], [90, 73], [650, 640], [1800, 1700], [3000, 2800]];
$checked = 0;
foreach ($cases as [$leftLength, $rightLength]) {
    $left = stage56DeterministicDigits($leftLength, 56 + $leftLength);
    $right = stage56DeterministicDigits($rightLength, 57 + $rightLength);
    $expected = stage56DecimalMultiply($left, $right);
    $actual = BigInt::fromString($left)->mul(BigInt::fromString($right))->toString();
    if ($actual !== $expected) throw new RuntimeException('STAGE56_KARATSUBA_PRODUCT_MISMATCH');
    $negative = BigInt::fromString('-' . $left)->mul(BigInt::fromString($right))->toString();
    if ($negative !== '-' . $expected) throw new RuntimeException('STAGE56_KARATSUBA_SIGN_MISMATCH');
    ++$checked;
}
$divisionCases = [[1, 2], [90, 97], [650, 999999999], [1800, 65521], [3000, 999999999]];
$divisionChecked = 0;
$nonExactRejected = 0;
foreach ($divisionCases as [$digits, $divisor]) {
    $quotient = stage56DeterministicDigits($digits, 5600 + $digits + ($divisor % 997));
    $product = stage56DecimalMultiply($quotient, (string)$divisor);
    [$oracleQuotient, $oracleRemainder] = stage56DecimalDivideSmall($product, $divisor);
    if ($oracleRemainder !== 0 || $oracleQuotient !== $quotient) {
        throw new RuntimeException('STAGE56_SMALL_DIVISION_ORACLE');
    }
    $positive = BigInt::fromString($product)->divSmallExact($divisor)->toString();
    $negative = BigInt::fromString('-' . $product)->divSmallExact($divisor)->toString();
    if ($positive !== $quotient || $negative !== '-' . $quotient) {
        throw new RuntimeException('STAGE56_SMALL_DIVISION_RESULT');
    }
    try {
        BigInt::fromString($product)->add(BigInt::one())->divSmallExact($divisor);
    } catch (RuntimeException $error) {
        if ($error->getMessage() !== 'DIV_SMALL_EXACT_NONEXACT') throw $error;
        ++$nonExactRejected;
    }
    ++$divisionChecked;
}
$invalidDivisorsRejected = 0;
foreach ([0, -1, 1000000000] as $divisor) {
    try {
        BigInt::one()->divSmallExact($divisor);
    } catch (InvalidArgumentException $error) {
        if ($error->getMessage() !== 'DIV_SMALL_EXACT_DIVISOR') throw $error;
        ++$invalidDivisorsRejected;
    }
}
if ($divisionChecked !== 5 || $nonExactRejected !== 5 || $invalidDivisorsRejected !== 3 ||
    !BigInt::zero()->divSmallExact(7)->isZero() ||
    !BigInt::fromInt(123)->divSmallExact(1)->equals(BigInt::fromInt(123))) {
    throw new RuntimeException('STAGE56_SMALL_DIVISION_TOTALS');
}

echo 'STAGE56_BIGINT_KARATSUBA_PASS cases=' . $checked . ' max_digits=3000' . PHP_EOL;
echo 'STAGE56_BIGINT_SMALL_DIVISION_PASS cases=' . $divisionChecked .
    ' nonexact=' . $nonExactRejected . ' invalid=' . $invalidDivisorsRejected . ' status=PASS' . PHP_EOL;
