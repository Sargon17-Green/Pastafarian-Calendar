#lang racket/base

(require racket/list)

(provide
 (struct-out monster-context)
 make-base-monster-context
 (struct-out monster-event)
 (struct-out monster-registry)
 make-monster-registry
 monster-log!
 monster-metric-bump!
 validate-base-context
 with-validation-boundary
 snapshot-semantic-state
 commit-semantic-state!)

(struct monster-event (code payload) #:transparent)

(struct monster-context
  (calculation-day
   target-day
   phase
   sub-phase
   mode
   status
   retry-budget
   recovery-depth
   current-handler
   previous-handler
   branch-trace
   semantic-state
   pending-state
   rollback-state
   logs
   metrics
   diagnostics
   warnings
   last-error
   validation-failures)
  #:mutable
  #:transparent)

(struct monster-registry (logs metrics) #:mutable #:transparent)

(define (make-monster-registry)
  (monster-registry '() (make-hash)))

(define (make-base-monster-context calculation-day target-day)
  (monster-context calculation-day
                   target-day
                   'bootstrap
                   0
                   'authoritative
                   'new
                   0
                   0
                   'base-dispatcher
                   #f
                   '()
                   (hash)
                   #f
                   #f
                   '()
                   (make-hash)
                   '()
                   '()
                   #f
                   '()))

(define (monster-log! ctx code payload)
  (set-monster-context-logs!
   ctx
   (cons (monster-event code payload) (monster-context-logs ctx))))

(define (monster-metric-bump! ctx key [amount 1])
  (hash-update! (monster-context-metrics ctx) key (lambda (old) (+ old amount)) 0))

(define (validate-base-context ctx)
  (unless (monster-context? ctx)
    (raise-argument-error 'validate-base-context "monster-context?" ctx))
  (unless (exact-integer? (monster-context-calculation-day ctx))
    (error 'validate-base-context "skaičiavimo diena turi būti tikslus sveikasis skaičius"))
  (unless (exact-integer? (monster-context-target-day ctx))
    (error 'validate-base-context "tikslinė diena turi būti tikslus sveikasis skaičius"))
  #t)

(define (with-validation-boundary ctx thunk)
  (with-handlers ([exn:fail?
                   (lambda (e)
                     (set-monster-context-last-error! ctx e)
                     (set-monster-context-validation-failures!
                      ctx
                      (cons (exn-message e)
                            (monster-context-validation-failures ctx)))
                     (set-monster-context-status! ctx 'failed-validation)
                     (raise e))])
    (validate-base-context ctx)
    (thunk)))

(define (snapshot-semantic-state ctx)
  (define snap (hash-copy (monster-context-semantic-state ctx)))
  (set-monster-context-rollback-state! ctx snap)
  snap)

(define (commit-semantic-state! ctx pending validator)
  (snapshot-semantic-state ctx)
  (set-monster-context-pending-state! ctx pending)
  (unless (validator pending)
    (set-monster-context-pending-state! ctx #f)
    (error 'commit-semantic-state! "laukianti semantinė būsena neatitiko validavimo"))
  (set-monster-context-semantic-state! ctx pending)
  (set-monster-context-pending-state! ctx #f)
  #t)
