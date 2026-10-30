<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Legacy;

use InvalidArgumentException;
use Pastafari\Stage01\BigInt;

/**
 * DISCOVERY18: pembaca tahun lama meneka panjang tetap 365 hari.
 * Hasil ini ialah parut sejarah, BUKAN nombor tahun sah.
 *
 * Rekod Year5000 diberi oleh pemanggil; modul ini tidak membaca Oracle.
 */
final class LegacyYearJumpGuess18
{
    /**
     * @param array{number:int,openGateDay:int,closeGateDay:int} $anchor
     * @return array{anchorNumber:int,anchorOpenGateDay:int,anchorCloseGateDay:int,targetDay:int,deltaDays:string,offset365:string,guessedYearNumber:int,usedLegacyOutput:bool}
     */
    public function guess(array $anchor, int $targetDay): array
    {
        foreach (['number', 'openGateDay', 'closeGateDay'] as $field) {
            if (!array_key_exists($field, $anchor) || !is_int($anchor[$field])) {
                throw new InvalidArgumentException('YEAR_JUMP_ANCHOR_FIELD_' . $field);
            }
        }
        if ($anchor['number'] !== 5000) {
            throw new InvalidArgumentException('YEAR_JUMP_ANCHOR_NUMBER');
        }

        $open = BigInt::fromInt($anchor['openGateDay']);
        $close = BigInt::fromInt($anchor['closeGateDay']);
        $length = $close->sub($open);
        if ($length->compare(BigInt::fromInt(252)) < 0 ||
            $length->compare(BigInt::fromInt(5778)) > 0) {
            throw new InvalidArgumentException('YEAR_JUMP_ANCHOR_INTERVAL');
        }

        // Penting: pembahagian lantai yang ditandatangani, bukan truncation.
        // Jangan menolak dua integer native sebelum BigInt: boleh overflow.
        $delta = BigInt::fromInt($targetDay)->sub($open);
        $offset = $delta->floorDiv(BigInt::fromInt(365));
        $yearNumber = BigInt::fromInt(5000)->add($offset)->toIntExact();

        return [
            'anchorNumber' => 5000,
            'anchorOpenGateDay' => $anchor['openGateDay'],
            'anchorCloseGateDay' => $anchor['closeGateDay'],
            'targetDay' => $targetDay,
            'deltaDays' => (string)$delta,
            'offset365' => (string)$offset,
            'guessedYearNumber' => $yearNumber,
            'usedLegacyOutput' => true,
        ];
    }
}
