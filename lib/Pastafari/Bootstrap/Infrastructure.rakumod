unit module Pastafari::Bootstrap::Infrastructure;

use Pastafari::Bootstrap::Context;

class BootstrapValidationError is Exception is export {
    has Str $.message;
    method message() { $!message }
}

class ValidationManager is export {
    method require-integer-day($value, Str:D $label --> Nil) {
        unless $value ~~ Int {
            die BootstrapValidationError.new(message => "$label peab olema täisarv");
        }
    }

    method require-clean-context(MonsterContext:D $ctx --> Nil) {
        if $ctx.pendingSnapshot.defined {
            die BootstrapValidationError.new(
                message => 'Kinnitamiseta semantiline olek jäi konteksti'
            );
        }
    }
}

class MetricsManager is export {
    method bump(MonsterContext:D $ctx, Str:D $key --> Nil) {
        $ctx.metrics{$key} = ($ctx.metrics{$key} // 0) + 1;
    }
}

class MonsterDispatcher is export {
    has ValidationManager $.validation = ValidationManager.new;
    has MetricsManager $.metrics = MetricsManager.new;

    method bootstrap(MonsterContext:D $ctx --> MonsterContext:D) {
        $ctx.previousHandler = $ctx.currentHandler;
        $ctx.currentHandler = 'BootstrapHandler';
        $ctx.branchTrace.push('BOOTSTRAP_ENTER');
        self.validation.require-integer-day($ctx.calculationDay, 'calculationDay');
        self.validation.require-integer-day($ctx.targetDay, 'targetDay');
        self.metrics.bump($ctx, 'bootstrap.calls');
        self.validation.require-clean-context($ctx);
        $ctx.status = 'READY';
        $ctx.branchTrace.push('BOOTSTRAP_READY');
        $ctx
    }
}

class MonsterManager is export {
    has MonsterDispatcher $.dispatcher = MonsterDispatcher.new;

    method prepare(Int:D $calculation-day, Int:D $target-day --> MonsterContext:D) {
        my $ctx = MonsterContext.new(
            calculationDay => $calculation-day,
            targetDay => $target-day,
        );
        $!dispatcher.bootstrap($ctx)
    }
}
