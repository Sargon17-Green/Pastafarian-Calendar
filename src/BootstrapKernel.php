<?php
declare(strict_types=1);

namespace Pastafari\Stage01;

final class BootstrapKernel
{
    private BootstrapDispatcher $dispatcher;
    private BootstrapValidator $validator;
    private BootstrapErrorBoundary $boundary;
    private MetricsShell $metrics;

    public function __construct()
    {
        $this->dispatcher = new BootstrapDispatcher();
        $this->validator = new BootstrapValidator();
        $this->boundary = new BootstrapErrorBoundary();
        $this->metrics = new MetricsShell();

        $this->dispatcher->register('BOOTSTRAP_VALIDATE', function(BootstrapContext $context): array {
            $this->metrics->bump($context, 'bootstrap.validation.calls');
            $this->validator->requireCatalogFrozen();
            $context->status = 'READY';
            return [
                'status' => $context->status,
                'catalogVersion' => SourceLanguageCatalog::VERSION,
                'cutletCount' => count(SourceLanguageCatalog::cutlets()),
                'monthCount' => count(SourceLanguageCatalog::months()),
            ];
        });
        $this->dispatcher->register('SAVE_LEGACY', function(BootstrapContext $context): BigInt {
            $operand = $context->semanticState['operand'] ?? null;
            if (!$operand instanceof BigInt) {
                throw new \RuntimeException('LEGACY_SAVE_OPERAND');
            }
            $legacy = new \Pastafari\Stage01\Legacy\LegacyRemainder();
            $result = $legacy->calculateWithoutPatch($operand);
            $context->semanticState['legacyResult'] = $result;
            $context->status = 'LEGACY_RETURNED';
            $this->metrics->bump($context, 'legacy.save.calls');
            return $result;
        });
    }

    public function probe(int $calculationDay, int $targetDay): array
    {
        $context = new BootstrapContext($calculationDay, $targetDay);
        $context->phase = 'BOOTSTRAP_VALIDATE';
        return $this->boundary->run(
            $context,
            fn(): array => $this->dispatcher->dispatch('BOOTSTRAP_VALIDATE', $context)
        );
    }
    /**
     * Laluan pengeluaran sementara yang sengaja mendedahkan baki lama.
     * Medan hari sifar dalam konteks tidak dibaca oleh operasi aritmetik ini.
     */
    public function save(BigInt $value): BigInt
    {
        $context = new BootstrapContext(0, 0);
        $context->phase = 'SAVE_LEGACY';
        $context->semanticState['operand'] = $value;
        return $this->boundary->run(
            $context,
            fn(): BigInt => $this->dispatcher->dispatch('SAVE_LEGACY', $context)
        );
    }
}
