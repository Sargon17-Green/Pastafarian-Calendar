<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Patches;

use LogicException;
use Pastafari\Stage01\BigInt;

/** Private per-engine immutable bounded exact row store; no persistent cache. */
final class SuffixScratchRows56
{
    private const CAP = 268435456;
    private const MAGIC = "PC56ROW\x01";
    private $file;
    private string $header;
    private int $size = 0;
    private array $directory = [];
    private array $widths = [];

    public function __construct(array $lengths, private int $budget = self::CAP)
    {
        if (!array_is_list($lengths) || count($lengths) < 2 || count($lengths) > 47 ||
            $budget < 40 || $budget > self::CAP) throw new LogicException('STAGE56_SCRATCH_CONFIG');
        $q = 1;
        foreach ($lengths as $i => $length) {
            if (!is_int($length) || $length < 1 || $length > 123) throw new LogicException('STAGE56_SCRATCH_CONFIG');
            $q += $length - 1;
            if ($q > 5778) throw new LogicException('STAGE56_SCRATCH_CONFIG');
            if ($i < count($lengths) - 1) $this->widths[$i] = $q + 1;
        }
        if (array_sum($lengths) > 5778) throw new LogicException('STAGE56_SCRATCH_CONFIG');
        $this->header = self::MAGIC . hash('sha256', pack('V*', ...$lengths), true);
        $this->file = tmpfile();
        if (!is_resource($this->file)) throw new LogicException('STAGE56_SCRATCH_OPEN');
        try {
            $this->write($this->header);
        } catch (\Throwable $e) {
            fclose($this->file);
            throw $e;
        }
    }

    public function __destruct()
    {
        if (is_resource($this->file)) fclose($this->file);
    }

    public function bytes(): int { return $this->size; }
    public function rows(): int { return count($this->directory); }

    private function write(string $bytes): void
    {
        $n = strlen($bytes);
        if ($n > $this->budget - $this->size) throw new LogicException('STAGE56_SCRATCH_BUDGET');
        if (fwrite($this->file, $bytes) !== $n) throw new LogicException('STAGE56_SCRATCH_WRITE');
        $this->size += $n;
    }

    private function read(int $n): string
    {
        if ($n < 1 || $n > 8192) throw new LogicException('STAGE56_SCRATCH_READ_SIZE');
        $out = '';
        while (strlen($out) < $n) {
            $part = fread($this->file, $n - strlen($out));
            if ($part === false || $part === '') throw new LogicException('STAGE56_SCRATCH_TRUNCATED');
            $out .= $part;
        }
        return $out;
    }

    /** @param list<BigInt> $row */
    public function append(int $index, array $row): void
    {
        if (isset($this->directory[$index]) || !isset($this->widths[$index]) ||
            !array_is_list($row) || count($row) !== $this->widths[$index]) {
            throw new LogicException('STAGE56_SCRATCH_ROW');
        }
        if (fseek($this->file, $this->size) !== 0) throw new LogicException('STAGE56_SCRATCH_SEEK');
        $offset = $this->size;
        $head = pack('V2', $index, count($row));
        $hash = hash_init('sha256');
        hash_update($hash, $head);
        $this->write($head);
        foreach ($row as $cell) {
            $limbs = $cell->scratchUnsignedLimbs56();
            $n = strlen($limbs);
            if ($n < 4 || $n > 8192 || $n % 4 !== 0) throw new LogicException('STAGE56_SCRATCH_CELL');
            $record = pack('V', $n) . $limbs;
            hash_update($hash, $record);
            $this->write($record);
        }
        if (!fflush($this->file)) throw new LogicException('STAGE56_SCRATCH_FLUSH');
        $this->directory[$index] = [$offset, $this->size, hash_final($hash, true)];
    }

    /** @return list<BigInt> */
    public function load(int $index): array
    {
        if (!isset($this->directory[$index])) throw new LogicException('STAGE56_SCRATCH_MISSING');
        [$offset, $end, $digest] = $this->directory[$index];
        $stat = fstat($this->file);
        if ($stat === false || $stat['size'] !== $this->size || $end > $this->size ||
            $offset < strlen($this->header) || $end <= $offset ||
            fseek($this->file, 0) !== 0 || $this->read(strlen($this->header)) !== $this->header ||
            fseek($this->file, $offset) !== 0) throw new LogicException('STAGE56_SCRATCH_IDENTITY');
        $head = $this->read(8);
        if ($head !== pack('V2', $index, $this->widths[$index])) throw new LogicException('STAGE56_SCRATCH_ROW_HEADER');
        $hash = hash_init('sha256');
        hash_update($hash, $head);
        $row = [];
        for ($i = 0; $i < $this->widths[$index]; ++$i) {
            if (ftell($this->file) > $end - 4) throw new LogicException('STAGE56_SCRATCH_BOUND');
            $prefix = $this->read(4);
            $n = unpack('V', $prefix)[1];
            if ($n < 4 || $n > 8192 || $n % 4 !== 0 || ftell($this->file) > $end - $n) {
                throw new LogicException('STAGE56_SCRATCH_CELL');
            }
            $limbs = $this->read($n);
            hash_update($hash, $prefix . $limbs);
            $row[] = BigInt::fromScratchUnsignedLimbs56($limbs);
        }
        if (ftell($this->file) !== $end || !hash_equals($digest, hash_final($hash, true))) {
            throw new LogicException('STAGE56_SCRATCH_DIGEST');
        }
        return $row;
    }
}
