<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;

/**
 * DISCOVERY 13 — kesilapan sejarah dalam ruang pilihan kecil.
 * Ambil sampel pertama terus modulo n tanpa menolak nilai melebihi
 * floor(M/n)*n. Pembetul rejection sampling hanya boleh hadir Stage 27.
 */
final class LegacyNoRejection13
{
    private readonly BigInt $modulus;

    public function __construct()
    {
        $this->modulus = BigInt::fromString('170141183460469231731687303715884105727');
    }

    /**
     * @param array{first:BigInt,step:int} $stream
     * @return BigInt Hasil 1..n, walaupun pengedaran hasil ini berat sebelah.
     */
    public function chooseWrong(array $stream, BigInt $n): BigInt
    {
        $first = $stream['first'] ?? null;
        $step = $stream['step'] ?? null;
        if (!$first instanceof BigInt || !is_int($step) || ($step !== 1 && $step !== -1)) {
            throw new InvalidArgumentException('NO_REJECTION_STREAM');
        }
        if ($n->compare(BigInt::one()) < 0 || $n->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('NO_REJECTION_SPACE');
        }
        if ($first->compare(BigInt::one()) < 0 || $first->compare($this->modulus) > 0) {
            throw new InvalidArgumentException('NO_REJECTION_FIRST');
        }

        // Parut salah yang sengaja dikekalkan: tiada ujian cutoff,
        // tiada pengulangan terhadap strim yang dihasilkan PATCH12.
        return $first->sub(BigInt::one())->mod($n)->add(BigInt::one());
    }
}
