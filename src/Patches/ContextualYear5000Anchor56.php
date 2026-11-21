<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use InvalidArgumentException;
use RuntimeException;

/**
 * Stage56 opt-in provenance boundary for a calculation-day-bound Year5000.
 * The independent trusted callback is an explicit dependency, not a fixture.
 * This class cannot attest to the callback's origin or generate year records.
 */
final class ContextualYear5000Anchor56
{
    private const FIELDS = [
        'number', 'openGateIndex', 'closeGateIndex', 'openGateDay', 'closeGateDay',
    ];

    /**
     * @param array<string,mixed> $candidate Context metadata and the five-field year.
     * @param callable(int):array<string,mixed> $trusted Independent canonical witness.
     * @return array<string,int> Validated year record, not an attestation of source bytes.
     */
    public function bind(int $calculationJdn, array $candidate, callable $trusted): array
    {
        $this->validateEnvelope($candidate, $calculationJdn, 'CANDIDATE');
        $canonical = $trusted($calculationJdn);
        if (!is_array($canonical)) {
            throw new RuntimeException('STAGE56_ANCHOR_TRUSTED_TYPE');
        }
        $this->validateEnvelope($canonical, $calculationJdn, 'TRUSTED');
        if ($candidate['source_commit'] !== $canonical['source_commit']) {
            throw new RuntimeException('STAGE56_ANCHOR_SOURCE_MISMATCH');
        }
        foreach (self::FIELDS as $field) {
            if ($candidate['year'][$field] !== $canonical['year'][$field]) {
                throw new RuntimeException('STAGE56_ANCHOR_IDENTITY_MISMATCH_' . $field);
            }
        }
        return $candidate['year'];
    }

    /** @param array<string,mixed> $witness */
    private function validateEnvelope(array $witness, int $calculationJdn, string $role): void
    {
        if (!isset($witness['calculation_jdn']) ||
            !is_int($witness['calculation_jdn']) ||
            $witness['calculation_jdn'] !== $calculationJdn) {
            throw new InvalidArgumentException('STAGE56_ANCHOR_' . $role . '_CONTEXT');
        }
        $source = $witness['source_commit'] ?? null;
        if (!is_string($source) || preg_match('/\A[a-f0-9]{40}\z/D', $source) !== 1) {
            throw new InvalidArgumentException('STAGE56_ANCHOR_' . $role . '_SOURCE');
        }
        $year = $witness['year'] ?? null;
        if (!is_array($year)) {
            throw new InvalidArgumentException('STAGE56_ANCHOR_' . $role . '_YEAR_TYPE');
        }
        foreach (self::FIELDS as $field) {
            if (!array_key_exists($field, $year) || !is_int($year[$field])) {
                throw new InvalidArgumentException('STAGE56_ANCHOR_' . $role . '_YEAR_' . $field);
            }
        }
        if ($year['number'] !== 5000 ||
            $year['closeGateIndex'] <= $year['openGateIndex'] ||
            $year['closeGateIndex'] - $year['openGateIndex'] < 6 ||
            $year['closeGateIndex'] - $year['openGateIndex'] > 5778 ||
            $year['closeGateDay'] <= $year['openGateDay'] ||
            $year['closeGateDay'] - $year['openGateDay'] < 252 ||
            $year['closeGateDay'] - $year['openGateDay'] > 5778 ||
            $calculationJdn <= $year['openGateDay'] ||
            $calculationJdn > $year['closeGateDay']) {
            throw new InvalidArgumentException('STAGE56_ANCHOR_' . $role . '_INTERVAL');
        }
    }
}
