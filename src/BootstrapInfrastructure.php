<?php
declare(strict_types=1);

namespace Pastafari\Stage01;

use RuntimeException;
use Throwable;

final class BootstrapContext
{
    public int $calculationDay;
    public int $targetDay;
    public string $phase = 'BOOT';
    public string $status = 'NEW';
    /** @var array<string,mixed> */
    public array $semanticState = [];
    /** @var array<string,int> */
    public array $metrics = [];
    /** @var list<array<string,mixed>> */
    public array $logs = [];
    /** @var list<array<string,mixed>> */
    public array $diagnostics = [];
    public ?Throwable $lastError = null;

    public function __construct(int $calculationDay, int $targetDay)
    {
        $this->calculationDay = $calculationDay;
        $this->targetDay = $targetDay;
    }
}

final class MetricsShell
{
    public function bump(BootstrapContext $context, string $key): void
    {
        $context->metrics[$key] = ($context->metrics[$key] ?? 0) + 1;
    }
}

final class BootstrapValidator
{
    public function requireFiveFields(array $value): void
    {
        if (count($value) !== 5) {
            throw new RuntimeException('RESULT_FIELD_COUNT');
        }
    }

    public function requireCatalogFrozen(): void
    {
        if (count(SourceLanguageCatalog::cutlets()) !== 17 || count(SourceLanguageCatalog::months()) !== 47) {
            throw new RuntimeException('SOURCE_CATALOG_SIZE');
        }
    }
}

final class BootstrapDispatcher
{
    /** @var array<string,callable> */
    private array $handlers = [];

    public function register(string $phase, callable $handler): void
    {
        $this->handlers[$phase] = $handler;
    }

    public function dispatch(string $phase, BootstrapContext $context): mixed
    {
        if (!isset($this->handlers[$phase])) {
            throw new RuntimeException('DISPATCH_PHASE');
        }
        return ($this->handlers[$phase])($context);
    }
}

final class BootstrapErrorBoundary
{
    public function run(BootstrapContext $context, callable $operation): mixed
    {
        try {
            return $operation();
        } catch (Throwable $error) {
            $context->lastError = $error;
            $context->status = 'FAILED';
            throw $error;
        }
    }
}
