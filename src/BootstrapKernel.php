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
}
