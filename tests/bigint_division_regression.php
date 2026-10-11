<?php
declare(strict_types=1);

// Ujian regresi bebas untuk pembahagian lantai dan baki integer tepat.
require_once dirname(__DIR__) . '/src/BigInt.php';

use Pastafari\Stage01\BigInt;

function semak(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException($message);
    }
}

function periksaPembahagian(BigInt $a, BigInt $b, ?int $expectedQ = null, ?int $expectedR = null): void
{
    [$q, $r] = $a->divMod($b);
    $prefix = 'a=' . $a->toString() . ' b=' . $b->toString();
    semak($b->mul($q)->add($r)->equals($a), 'IDENTITI ' . $prefix);
    semak($r->abs()->compare($b->abs()) < 0, 'JULAT_BAKI ' . $prefix);
    semak($r->isZero() || $r->sign() === $b->sign(), 'TANDA_BAKI ' . $prefix);
    semak($a->floorDiv($b)->equals($q), 'FLOOR_DIV ' . $prefix);
    semak($a->mod($b)->equals($r), 'MOD ' . $prefix);
    if ($expectedQ !== null && $expectedR !== null) {
        semak($q->toString() === (string)$expectedQ, 'MANA_DIKETAHUI ' . $prefix);
        semak($r->toString() === (string)$expectedR, 'BAKI_DIKETAHUI ' . $prefix);
    }
}

$tested = 0;
foreach (range(-40, 40) as $a) {
    foreach ([-19, -13, -7, -3, -2, -1, 1, 2, 3, 7, 13, 19] as $b) {
        $q = (int)floor($a / $b); // Nombor kecil sahaja: tepat sepenuhnya.
        $r = $a - $q * $b;
        periksaPembahagian(BigInt::fromInt($a), BigInt::fromInt($b), $q, $r);
        $tested++;
    }
}

$besar = BigInt::fromString(str_repeat('9876543210', 12) . '123456789');
$besarLain = BigInt::fromString(str_repeat('314159265358979323846264338327', 4));
$kecil = BigInt::fromInt(321);
foreach ([$besar, $besar->neg(), $besarLain, $besarLain->neg(), $kecil, $kecil->neg(), BigInt::zero()] as $a) {
    foreach ([$besar, $besar->neg(), $besarLain, $besarLain->neg(), BigInt::fromInt(7), BigInt::fromInt(-7)] as $b) {
        periksaPembahagian($a, $b);
        $tested++;
    }
}

$max = PHP_INT_MAX;
semak(BigInt::fromInt(-123)->modSmall($max) === $max - 123, 'MOD_SMALL_BESAR_NEGATIF');
semak(BigInt::fromInt(123)->modSmall($max) === 123, 'MOD_SMALL_BESAR_POSITIF');
semak($besar->modSmall($max) === $besar->mod(BigInt::fromInt($max))->toIntExact(), 'MOD_SMALL_BESAR_LIMB');
semak(BigInt::fromInt(PHP_INT_MIN)->toIntExact() === PHP_INT_MIN, 'INT_MIN_TEPAT');
semak(BigInt::fromInt(PHP_INT_MIN)->modSmall($max) === $max - 1, 'MOD_SMALL_INT_MIN');
semak(BigInt::fromInt(-$max)->modSmall($max) === 0, 'MOD_SMALL_NEGATIF_TEPAT');
semak($besar->modSmall(999999999) === $besar->mod(BigInt::fromInt(999999999))->toIntExact(), 'MOD_SMALL_SEMPADAN');

try {
    BigInt::one()->divMod(BigInt::zero());
    throw new RuntimeException('BAHAGI_SIFAR_DITERIMA');
} catch (InvalidArgumentException $e) {
    semak($e->getMessage() === 'DIVISION_BY_ZERO', 'KOD_BAHAGI_SIFAR');
}

echo "LULUS bigint_division_regression kes={$tested} tambahan=8\n";
