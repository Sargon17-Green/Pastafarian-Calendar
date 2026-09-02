<?php
declare(strict_types=1);

namespace Pastafari\Stage01\Tests;

use Throwable;

final class TestHarness
{
    private int $passed = 0;
    private int $failed = 0;
    /** @var list<string> */
    private array $failures = [];

    public function test(string $name, callable $test): void
    {
        try {
            $test();
            $this->passed++;
            echo "LULUS {$name}\n";
        } catch (Throwable $error) {
            $this->failed++;
            $this->failures[] = $name . ': ' . $error->getMessage();
            echo "GAGAL {$name}: {$error->getMessage()}\n";
        }
    }

    public function same(mixed $expected, mixed $actual, string $code = 'ASSERT_SAME'): void
    {
        if ($expected !== $actual) {
            throw new \RuntimeException($code . ' expected=' . json_encode($expected) . ' actual=' . json_encode($actual));
        }
    }

    public function true(bool $condition, string $code = 'ASSERT_TRUE'): void
    {
        if (!$condition) {
            throw new \RuntimeException($code);
        }
    }

    public function finish(): int
    {
        echo "RINGKASAN lulus={$this->passed} gagal={$this->failed}\n";
        if ($this->failed > 0) {
            echo "KEPUTUSAN GAGAL\n";
            foreach ($this->failures as $failure) {
                echo "- {$failure}\n";
            }
            return 1;
        }
        echo "KEPUTUSAN LULUS\n";
        return 0;
    }
}
