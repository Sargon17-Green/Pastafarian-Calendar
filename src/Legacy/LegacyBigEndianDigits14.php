<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Patches\SavePatch01;

/**
 * DISCOVERY14: dua sampel SAVE sebagai digit pangkat yang TERBALIK.
 * Julat ujian tahap ini: M < n <= M*M; pembetul berat digit hanya Stage29.
 */
final class LegacyBigEndianDigits14
{
    private readonly BigInt $modulus;

    public function __construct(private readonly SavePatch01 $save)
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    /**
     * @param array{first:BigInt,step:int} $stream
     * @return BigInt Pangkat 1..n (susunan digit salah).
     */
    public function chooseWrong(array $stream, BigInt $n): BigInt
    {
        $first = $stream['first'] ?? null;
        $step = $stream['step'] ?? null;
        if (!$first instanceof BigInt || !is_int($step) || !in_array($step, [-1,1], true)) {
            throw new InvalidArgumentException('BIG_ENDIAN_STREAM');
        }
        $space = $this->modulus->square();
        if ($n->compare($this->modulus) <= 0 || $n->compare($space) > 0) {
            throw new InvalidArgumentException('BIG_ENDIAN_SPACE');
        }
        if ($first->compare(BigInt::one()) < 0 || $first->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('BIG_ENDIAN_FIRST');
        }

        // Parut lama: sampel pertama dianggap digit PALING penting.
        // Urutan yang sah adalah digit0*1 + digit1*M, bukan sebaliknya.
        $digitWeights = [$this->modulus, BigInt::one()];
        $wide = BigInt::one();
        foreach ($digitWeights as $index => $weight) {
            $digit = $this->save->savePatch(
                $first->add(BigInt::fromInt($index * $step))
            );
            $wide = $wide->add($digit->sub(BigInt::one())->mul($weight));
        }

        // Had penerimaan normatif dikekalkan: kecacatan HANYA berat digit.
        $cutoff = $space->floorDiv($n)->mul($n);
        $increment = BigInt::fromInt($step);
        while ($wide->compare($cutoff) > 0) {
            $wide = $wide->sub(BigInt::one())->add($increment)->mod($space)->add(BigInt::one());
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
