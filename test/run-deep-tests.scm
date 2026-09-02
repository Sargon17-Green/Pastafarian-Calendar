(load "src/monster-skeleton.scm")
(load "test/normative-oracle.scm")

(define failed 0)

(define (check name condition)
  (display (if condition "BESTÅET: " "FEJL: "))
  (display name)
  (newline)
  (if (not condition) (set! failed (+ failed 1))))

(reset-gates!)
(let ((y (year5000 FOUNDATION-DAY)))
  (check "År 5000 indeholder beregningsdagen i intervallet (åben,lukket]"
         (and (< (year-open-day y) FOUNDATION-DAY)
              (<= FOUNDATION-DAY (year-close-day y))))
  (check "År 5000 har mindst seks portgab"
         (>= (- (year-close-index y) (year-open-index y)) 6))
  (check "År 5000 har normativ længde"
         (let ((len (- (year-close-day y) (year-open-day y))))
           (and (>= len YEAR-MIN-DAYS) (<= len YEAR-MAX-DAYS)))))

(if (= failed 0)
    (begin (display "SAMLET DYB TEST: GRØN") (newline) (exit 0))
    (begin (display "SAMLET DYB TEST: RØD") (newline) (exit 1)))
