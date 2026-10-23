<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use Pastafari\Stage01\BigInt;
use Pastafari\Stage01\Legacy\LegacyNoRejection13;

/**
 * PATCH13 — pilih pangkat tanpa bias bagi 1 <= n <= M.
 * Tiada oracle produksi; parut chooseWrong dipanggil dengan benar.
 */
final class RejectionSamplingPatch13
{
    private readonly BigInt $modulus;

    public function __construct(
        private readonly LegacyNoRejection13 $legacy,
        private readonly SavePatch01 $save
    ) {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    /**
     * @param array{first:BigInt,step:int} $stream
     * @return BigInt Pangkat sah 1..n selepas semua sampel > cutoff ditolak.
     */
    public function choosePatched(array $stream, BigInt $n): BigInt
    {
        // Laluan sejarah sebenar mengekalkan pengesahan domain dan parut.
        $wrong = $this->legacy->chooseWrong($stream, $n);
        $first = $stream['first'];
        $step = $stream['step'];

        // Had ialah gandaan terbesar n yang tidak melebihi M.
        $cutoff = $this->modulus->floorDiv($n)->mul($n);
        if ($first->compare($cutoff) <= 0) {
            return $wrong; // Laluan sejarah benar jika sampel sudah sah.
        }

        // Setiap sampel ialah SAVE(first + k*step); SAVE merangkum M ke 1.
        $candidate = $first;
        $delta = BigInt::fromInt($step);
        do {
            $candidate = $this->save->savePatch($candidate->add($delta));
        } while ($candidate->compare($cutoff) > 0);

        return $candidate->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
