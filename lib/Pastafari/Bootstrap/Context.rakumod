unit module Pastafari::Bootstrap::Context;

class MonsterContext is export {
    has Int $.calculationDay is rw;
    has Int $.targetDay is rw;
    has Str $.phase is rw = 'BOOTSTRAP';
    has Str $.subPhase is rw = 'NONE';
    has Str $.mode is rw = 'AUTHORITATIVE_BOOTSTRAP';
    has Str $.status is rw = 'NEW';
    has Int $.retryBudget is rw = 0;
    has Int $.recoveryDepth is rw = 0;
    has Str $.currentHandler is rw = 'NONE';
    has Str $.previousHandler is rw = 'NONE';
    has @.branchTrace is rw;
    has %.metrics is rw;
    has @.logs is rw;
    has @.diagnostics is rw;
    has @.warnings is rw;
    has @.validationFailures is rw;
    has $.oldSnapshot is rw;
    has $.pendingSnapshot is rw;
    has $.rollbackSnapshot is rw;
    has Str $.commitToken is rw = 'NONE';
}
