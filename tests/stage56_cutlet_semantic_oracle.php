<?php
declare(strict_types=1);

/**
 * Source-free Stage56 cutlet semantic oracle.
 *
 * This file deliberately imports no production class, fixture, external source,
 * calendar implementation, or test helper. It checks the mathematical
 * partition semantics and the resulting day intervals from first principles.
 */
final class Stage56CutletSemanticOracle
{
    /**
     * Enumerate positive compositions in lexicographic order using bounded DFS.
     * This is intentionally limited to small proof domains; real-year vectors
     * are checked structurally by validateStructure(), never exhaustively.
     *
     * @return list<list<int>>
     */
    public static function enumeratePartitions(
        int $gaps,
        int $parts,
        ?int $requiredCut = null,
        int $maxNodes = 250000
    ): array {
        if ($gaps < 1 || $gaps > 5778 || $parts < 1 || $parts > 17 ||
            $parts > $gaps || $maxNodes < 1 ||
            ($requiredCut !== null && ($requiredCut < 1 || $requiredCut >= $gaps))) {
            throw new InvalidArgumentException('STAGE56_CUTLET_ORACLE_DFS_INPUT');
        }

        $result = [];
        $prefix = [];
        $nodes = 0;
        $walk = function (int $remaining, int $left, int $sum, bool $hit) use (
            &$walk, &$result, &$prefix, &$nodes, $gaps, $requiredCut, $maxNodes
        ): void {
            ++$nodes;
            if ($nodes > $maxNodes) {
                throw new RuntimeException('STAGE56_CUTLET_ORACLE_DFS_BOUND');
            }
            if ($left === 0) {
                if ($remaining === 0 && ($requiredCut === null || $hit)) {
                    $result[] = $prefix;
                }
                return;
            }
            if ($remaining < $left) {
                return;
            }

            $maximum = $remaining - ($left - 1);
            for ($part = 1; $part <= $maximum; ++$part) {
                $nextSum = $sum + $part;
                if ($requiredCut !== null && !$hit &&
                    $sum < $requiredCut && $nextSum > $requiredCut) {
                    continue;
                }
                $nextHit = $hit || ($requiredCut !== null && $nextSum === $requiredCut);
                if ($requiredCut !== null && !$nextHit && $left === 1) {
                    continue;
                }
                $prefix[] = $part;
                $walk($remaining - $part, $left - 1, $nextSum, $nextHit);
                array_pop($prefix);
            }
        };

        $walk($gaps, $parts, 0, false);
        return $result;
    }

    /**
     * Validate a production-shaped cutlet structure without invoking production
     * code. $gateDays maps every gate index in the year to its integer day.
     *
     * @return array{gap_count:int,year_days:int,cutlet_count:int,required_cut:?int,name_indices:list<int>}
     */
    public static function validateStructure(
        array $structure,
        array $year,
        array $gateDays,
        int $calculationJdn
    ): array {
        $fail = static function (string $reason): never {
            throw new RuntimeException('STAGE56_CUTLET_ORACLE_' . $reason);
        };

        foreach (['openGateIndex', 'closeGateIndex', 'openGateDay', 'closeGateDay'] as $field) {
            if (!isset($year[$field]) || !is_int($year[$field])) {
                $fail('YEAR_FIELD_' . $field);
            }
        }
        $openIndex = $year['openGateIndex'];
        $closeIndex = $year['closeGateIndex'];
        $openDay = $year['openGateDay'];
        $closeDay = $year['closeGateDay'];
        $gaps = $closeIndex - $openIndex;
        $yearDays = $closeDay - $openDay;
        if ($gaps < 6 || $gaps > 137 || $yearDays < 252 || $yearDays > 5778) {
            $fail('YEAR_INTERVAL');
        }

        $previousGateDay = null;
        for ($index = $openIndex; $index <= $closeIndex; ++$index) {
            $day = self::readGateDay($gateDays, $index, $fail);
            if ($previousGateDay !== null) {
                $distance = $day - $previousGateDay;
                if ($distance < 42 || $distance > 963) {
                    $fail('GATE_DISTANCE_' . $index);
                }
            }
            $previousGateDay = $day;
        }
        if (self::readGateDay($gateDays, $openIndex, $fail) !== $openDay ||
            self::readGateDay($gateDays, $closeIndex, $fail) !== $closeDay) {
            $fail('GATE_ENDPOINTS');
        }

        $count = $structure['cutletCount'] ?? null;
        $partition = $structure['cutletPartition'] ?? null;
        $names = $structure['cutletNameIndices'] ?? null;
        $cutlets = $structure['cutlets'] ?? null;
        if (!is_int($count) || $count < 6 || $count > min(17, $gaps) ||
            !is_array($partition) || !array_is_list($partition) ||
            !is_array($names) || !array_is_list($names) ||
            !is_array($cutlets) || !array_is_list($cutlets) ||
            count($partition) !== $count || count($names) !== $count ||
            count($cutlets) !== $count) {
            $fail('CUTLET_SHAPE');
        }

        $seenNames = [];
        foreach ($names as $name) {
            if (!is_int($name) || $name < 1 || $name > 17 || isset($seenNames[$name])) {
                $fail('NAME_SELECTION');
            }
            $seenNames[$name] = true;
        }

        $prefixes = [];
        $prefix = 0;
        foreach ($partition as $part) {
            if (!is_int($part) || $part < 1) {
                $fail('PARTITION_POSITIVITY');
            }
            $prefix += $part;
            $prefixes[] = $prefix;
        }
        if ($prefix !== $gaps) {
            $fail('PARTITION_SUM');
        }

        $requiredCut = null;
        if ($calculationJdn > $openDay && $calculationJdn < $closeDay) {
            for ($index = $openIndex + 1; $index < $closeIndex; ++$index) {
                if (self::readGateDay($gateDays, $index, $fail) === $calculationJdn) {
                    $requiredCut = $index - $openIndex;
                    break;
                }
            }
        }
        if ($requiredCut !== null && !in_array($requiredCut, $prefixes, true)) {
            $fail('MANDATORY_CALCULATION_GATE');
        }

        $prefix = 0;
        $previousLastDay = $openDay;
        foreach ($cutlets as $slot => $cutlet) {
            if (!is_array($cutlet)) {
                $fail('CUTLET_RECORD_' . $slot);
            }
            foreach (['canonicalIndex', 'openGateIndex', 'closeGateIndex', 'firstDay', 'lastDay'] as $field) {
                if (!isset($cutlet[$field]) || !is_int($cutlet[$field])) {
                    $fail('CUTLET_FIELD_' . $slot . '_' . $field);
                }
            }
            $startIndex = $openIndex + $prefix;
            $prefix += $partition[$slot];
            $endIndex = $openIndex + $prefix;
            $firstDay = self::readGateDay($gateDays, $startIndex, $fail) + 1;
            $lastDay = self::readGateDay($gateDays, $endIndex, $fail);

            if ($cutlet['canonicalIndex'] !== $names[$slot] ||
                $cutlet['openGateIndex'] !== $startIndex ||
                $cutlet['closeGateIndex'] !== $endIndex ||
                $cutlet['firstDay'] !== $firstDay ||
                $cutlet['lastDay'] !== $lastDay) {
                $fail('CUTLET_BOUNDARY_' . $slot);
            }
            if ($firstDay !== $previousLastDay + 1 || $lastDay < $firstDay) {
                $fail('DAY_COVERAGE_' . $slot);
            }
            $previousLastDay = $lastDay;
        }
        if ($prefix !== $gaps || $previousLastDay !== $closeDay) {
            $fail('FINAL_COVERAGE');
        }

        return [
            'gap_count' => $gaps,
            'year_days' => $yearDays,
            'cutlet_count' => $count,
            'required_cut' => $requiredCut,
            'name_indices' => array_values($names),
        ];
    }

    private static function readGateDay(array $gateDays, int $index, callable $fail): int
    {
        if (!array_key_exists($index, $gateDays) && !array_key_exists((string) $index, $gateDays)) {
            $fail('MISSING_GATE_' . $index);
        }
        $day = $gateDays[$index] ?? $gateDays[(string) $index] ?? null;
        if (!is_int($day)) {
            $fail('GATE_TYPE_' . $index);
        }
        return $day;
    }
}
