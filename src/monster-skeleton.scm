;; Neutral grundstruktur. Ingen historisk fejl eller fremtidig lap findes her.

(define (make-base-monster-context calculation-day target-day)
  (vector
   'monster-context
   calculation-day
   target-day
   'bootstrap
   'new
   '()
   '()
   '()
   '()))

(define (context-calculation-day ctx) (vector-ref ctx 1))
(define (context-target-day ctx) (vector-ref ctx 2))
(define (context-phase ctx) (vector-ref ctx 3))
(define (context-status ctx) (vector-ref ctx 4))
(define (context-metrics ctx) (vector-ref ctx 5))
(define (context-logs ctx) (vector-ref ctx 6))
(define (context-diagnostics ctx) (vector-ref ctx 7))
(define (context-validation-failures ctx) (vector-ref ctx 8))

(define (make-base-dispatcher)
  (vector 'dispatcher '()))

(define (dispatcher-register dispatcher phase handler)
  (vector-set! dispatcher 1
               (cons (cons phase handler) (vector-ref dispatcher 1)))
  dispatcher)

(define (dispatcher-find dispatcher phase)
  (let ((entry (assq phase (vector-ref dispatcher 1))))
    (if entry (cdr entry) #f)))

(define (base-validate-discrete-day value)
  (if (integer? value)
      (vector 'ok value)
      (vector 'error "Dagen skal være et helt tal")))

(define (base-error-wrapper thunk)
  ;; Denne wrapper har endnu ingen recovery- eller kompatibilitetslogik.
  (thunk))

(define (metrics-bump metrics key)
  (let ((entry (assq key metrics)))
    (if entry
        (begin (set-cdr! entry (+ 1 (cdr entry))) metrics)
        (cons (cons key 1) metrics))))
