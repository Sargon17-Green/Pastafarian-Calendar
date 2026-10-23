<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyBigEndianDigits14;

/**
 * PATCH14: dua digit daripada strim yang sama, dalam susunan little-endian.
 * Terima hanya ruang M < n <= M*M. Cacat big-endian asal tidak diubah.
 */
final class BigEndianDigitsPatch14
{
    private readonly BigInt $modulus;

    public function __construct(
        private readonly LegacyBigEndianDigits14 $legacy,
        private readonly SavePatch01 $save
    ) {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    /**
     * @param array{first:BigInt,step:int} $stream
     * @return BigInt Pangkat 1..n dalam domain dua digit.
     */
    public function choosePatched(array $stream, BigInt $n): BigInt
    {
        // Kekalkan pemanggilan sebenar kod legacy dan semakan domain asal.
        $historicalRank = $this->legacy->chooseWrong($stream, $n);
        $first = $stream['first'];
        $step = $stream['step'];

        // Digit awal ialah digit paling RENDAH (berat 1), bukan berat M.
        $low = $first->sub(BigInt::one());
        $second = $this->save->savePatch(
            $first->add(BigInt::fromInt($step))
        );
        $high = $second->sub(BigInt::one());
        $wide = BigInt::one()->add($low)->add($high->mul($this->modulus));

        $space = $this->modulus->square();
        $cutoff = $space->floorDiv($n)->mul($n);
        $increment = BigInt::fromInt($step);
        while ($wide->compare($cutoff) > 0) {
            // Sama dengan strim lebar normatif; lilitan kekal dalam 1..M*M.
            $wide = $wide->sub(BigInt::one())
                ->add($increment)->mod($space)->add(BigInt::one());
        }
        // Keputusan legacy tidak mempengaruhi jawapan sah, tetapi dilaksanakan.
        if ($historicalRank->compare(BigInt::one()) < 0
            || $historicalRank->compare($n) > 0) {
            throw new \LogicException('BIG_ENDIAN_LEGACY_TRACE_RANGE');
        }
        return $wide->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
