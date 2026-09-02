#lang racket/base

(provide
 FOUNDATION-DAY-COUNT-FIXTURES
 WORK-COUNT-FIXTURES
 SAVE-FIXTURES
 STONE-ROW-2-EXPECTED
 PERMUTATION-FIXTURES
 BOUNDED-COMPOSITION-FIXTURES
 WEAVING-FIXTURES)

(define FOUNDATION-DAY-COUNT-FIXTURES
  (list
   (cons -15055672 2)
   (cons -15055671 1)
   (cons -15055670 3)
   (cons -15055669 5)))

(define WORK-COUNT-FIXTURES
  (list
   (vector -15055671 -15055671 1 1 1 2 2)
   (vector -15055672 -15055670 2 3 3 5 3)
   (vector -15055670 -15055672 3 2 3 5 1)))

(define SAVE-FIXTURES
  (list
   (cons 1 1)
   (cons (sub1 (sub1 (expt 2 127))) (sub1 (sub1 (expt 2 127))))
   (cons (sub1 (expt 2 127)) (sub1 (expt 2 127)))
   (cons (expt 2 127) 1)
   (cons (* 2 (sub1 (expt 2 127))) (sub1 (expt 2 127)))))

(define STONE-ROW-2-EXPECTED (vector 378 1073 2375 6195 10493))

(define PERMUTATION-FIXTURES
  (list
   (cons 1 (vector 1 2 3 4 5 6))
   (cons 720 (vector 6 5 4 3 2 1))))

(define BOUNDED-COMPOSITION-FIXTURES
  (list
   (cons 1 '(3 4))
   (cons 2 '(4 3))))

(define WEAVING-FIXTURES
  (list
   (cons 1 '(1 1 2 2))
   (cons 2 '(1 2 1 2))))
