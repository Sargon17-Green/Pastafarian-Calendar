#lang racket/base

(require rackunit
         racket/list
         "../src/constants.rkt"
         "../src/source-language-catalog.rkt"
         "../src/normative-oracle.rkt"
         "../src/monster-base.rkt"
         "../fixtures/stage01-fixtures.rkt")

(define (test-basic-constants)
  (check-equal? (- TABLETS-DAY FOUNDATION-DAY) 14777149)
  (check-equal? YEAR-MAX-DAYS 5778)
  (check-equal? M (sub1 (expt 2 127))))

(define (test-source-language-catalog)
  (check-true (validate-source-language-catalog))
  (check-equal? (vector-length CUTLET-CATALOG) 17)
  (check-equal? (vector-length MONTH-CATALOG) 47)
  (check-equal? (cutlet-name-by-index 12) "kviečiai")
  (check-equal? (month-name-by-index 44) "druska")
  (for ([entry (in-vector CUTLET-CATALOG)] [idx (in-naturals 1)])
    (check-equal? (catalog-entry-canonical-index entry) idx))
  (for ([entry (in-vector MONTH-CATALOG)] [idx (in-naturals 1)])
    (check-equal? (catalog-entry-canonical-index entry) idx)))

(define (test-save)
  (for ([fixture (in-list SAVE-FIXTURES)])
    (check-equal? (save-value (car fixture)) (cdr fixture))))

(define (test-day-counts)
  (for ([fixture (in-list FOUNDATION-DAY-COUNT-FIXTURES)])
    (check-equal? (day-count (car fixture)) (cdr fixture))))

(define (test-work-counts)
  (for ([fixture (in-list WORK-COUNT-FIXTURES)])
    (define c (vector-ref fixture 0))
    (define t (vector-ref fixture 1))
    (define expected-action (vector-ref fixture 2))
    (define expected-target (vector-ref fixture 3))
    (define expected-distance (vector-ref fixture 4))
    (define expected-connection (vector-ref fixture 5))
    (define expected-direction (vector-ref fixture 6))
    (define got (work-counts-for c t))
    (check-equal? (work-counts-action got) expected-action)
    (check-equal? (work-counts-target got) expected-target)
    (check-equal? (work-counts-distance got) expected-distance)
    (check-equal? (work-counts-connection got) expected-connection)
    (check-equal? (work-counts-direction got) expected-direction)))

(define (test-stones)
  (define stones (build-stones))
  (check-equal? (vector-length stones) 46)
  (check-equal? (vector-ref stones 0) (vector 17 29 43 71 101))
  (check-equal? (vector-ref stones 1) STONE-ROW-2-EXPECTED))

(define (test-permutations)
  (for ([fixture (in-list PERMUTATION-FIXTURES)])
    (check-equal? (bowl-order-from-number (car fixture)) (cdr fixture))))

(define (test-bounded-compositions)
  (define family (make-bounded-composition-family 7 2 3 4))
  (check-equal? ((ordered-family-count family)) 2)
  (for ([fixture (in-list BOUNDED-COMPOSITION-FIXTURES)])
    (check-equal? ((ordered-family-unrank1 family) (car fixture)) (cdr fixture))))

(define (test-weavings)
  (check-equal? (count-weavings-for-lengths '(2 2)) 2)
  (for ([fixture (in-list WEAVING-FIXTURES)])
    (check-equal? (unrank-weaving '(2 2) (car fixture)) (cdr fixture))))

(define (test-monster-base)
  (define ctx (make-base-monster-context FOUNDATION-DAY FOUNDATION-DAY))
  (check-true (validate-base-context ctx))
  (check-equal? (monster-context-phase ctx) 'bootstrap)
  (check-equal? (monster-context-mode ctx) 'authoritative)
  (check-false (monster-context-pending-state ctx))
  (monster-log! ctx 'bandymas '(1 2 3))
  (monster-metric-bump! ctx 'bandymas)
  (check-equal? (hash-ref (monster-context-metrics ctx) 'bandymas) 1)
  (check-true
   (commit-semantic-state!
    ctx
    (hash 'pavyzdys 7)
    (lambda (pending) (= (hash-ref pending 'pavyzdys) 7))))
  (check-equal? (hash-ref (monster-context-semantic-state ctx) 'pavyzdys) 7))

(define (test-sauce-determinism)
  (define a (oracle-sauce FOUNDATION-DAY FOUNDATION-DAY))
  (define b (oracle-sauce FOUNDATION-DAY FOUNDATION-DAY))
  (check-equal? a b)
  (check-equal? (vector-length (sauce-result-bowls a)) 6)
  (check-equal? (vector-length (sauce-result-order-at-drop46 a)) 6)
  (check-equal? (sort (vector->list (sauce-result-order-at-drop46 a)) <)
                '(1 2 3 4 5 6)))

(module+ test
  (test-basic-constants)
  (test-source-language-catalog)
  (test-save)
  (test-day-counts)
  (test-work-counts)
  (test-stones)
  (test-permutations)
  (test-bounded-compositions)
  (test-weavings)
  (test-monster-base)
  (test-sauce-determinism)
  (displayln "1 etapo Bootstrap bandymai baigti"))
