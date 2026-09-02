(load "src/monster-skeleton.scm")
(load "test/normative-oracle.scm")
(load "test/fixtures.scm")

(define passed 0)
(define failed 0)

(define (report-ok name)
  (set! passed (+ passed 1))
  (display "BESTÅET: ")
  (display name)
  (newline))

(define (report-fail name expected actual)
  (set! failed (+ failed 1))
  (display "FEJL: ")
  (display name)
  (display " | forventet=")
  (write expected)
  (display " | faktisk=")
  (write actual)
  (newline))

(define (assert-equal name expected actual)
  (if (equal? expected actual)
      (report-ok name)
      (report-fail name expected actual)))

(define (assert-true name actual)
  (if actual
      (report-ok name)
      (report-fail name #t actual)))

(define (all-distinct? xs)
  (cond
   ((null? xs) #t)
   ((member (car xs) (cdr xs)) #f)
   (else (all-distinct? (cdr xs)))))

(assert-equal "M er 2^127-1" FIXTURE-M M)
(assert-equal "Tavledagens afstand fra grundlæggelsen"
              14777149
              (- TABLETS-DAY FOUNDATION-DAY))

(assert-equal "Koteletkataloget har 17 poster" 17 (vector-length CUTLET-SOURCE-NAMES))
(assert-equal "Månedskataloget har 47 poster" 47 (vector-length MONTH-SOURCE-NAMES))
(assert-equal "Koteletindeks er 1..17" (range-inclusive 1 17) (cutlet-canonical-indices))
(assert-equal "Månedsindeks er 1..47" (range-inclusive 1 47) (month-canonical-indices))
(assert-true "Koteletnavnene er forskellige" (all-distinct? (vector->plain-list CUTLET-SOURCE-NAMES)))
(assert-true "Månedsnavnene er forskellige" (all-distinct? (vector->plain-list MONTH-SOURCE-NAMES)))
(assert-equal "Hvede er katalogpost 12" "hvede" (cutlet-name-by-index 12))
(assert-equal "Virak er månedspost 12" "virak" (month-name-by-index 12))
(assert-equal "Ten er månedspost 13" "ten" (month-name-by-index 13))

(assert-equal "SAVE(1)" 1 (save 1))
(assert-equal "SAVE(M-1)" (- M 1) (save (- M 1)))
(assert-equal "SAVE(M)" M (save M))
(assert-equal "SAVE(M+1)" 1 (save (+ M 1)))
(assert-equal "SAVE(2M)" M (save (* 2 M)))
(assert-equal "SAVE(-1)" (- M 1) (save -1))

(assert-equal "Dagstal på grundlæggelsesdagen" 1 (day-count FOUNDATION-DAY))
(assert-equal "Dagstal dagen efter" 3 (day-count (+ FOUNDATION-DAY 1)))
(assert-equal "Dagstal dagen før" 2 (day-count (- FOUNDATION-DAY 1)))
(assert-equal "Arbejdsmængder ved samme dag"
              FIXTURE-WORK-FOUNDATION
              (vector->plain-list (work-counts FOUNDATION-DAY FOUNDATION-DAY)))
(assert-equal "Arbejdsmængder over grundlæggelsen fremad"
              FIXTURE-WORK-CROSS-FORWARD
              (vector->plain-list (work-counts (- FOUNDATION-DAY 1)
                                               (+ FOUNDATION-DAY 1))))
(assert-equal "Arbejdsmængder over grundlæggelsen bagud"
              FIXTURE-WORK-CROSS-BACKWARD
              (vector->plain-list (work-counts (+ FOUNDATION-DAY 1)
                                               (- FOUNDATION-DAY 1))))

(assert-equal "Første stenrække"
              FIXTURE-STONE-1
              (vector->plain-list (vref1 STONES 1)))
(assert-equal "Anden stenrække"
              FIXTURE-STONE-2
              (vector->plain-list (vref1 STONES 2)))
(assert-equal "Stentabellen har 46 rækker" 46 (vector-length STONES))

(assert-equal "Første permutation"
              FIXTURE-PERMUTATION-FIRST
              (bowl-order-from-number 1))
(assert-equal "Sidste permutation"
              FIXTURE-PERMUTATION-LAST
              (bowl-order-from-number 720))
(assert-equal "Dråbe 720 vælger permutation 720"
              FIXTURE-PERMUTATION-LAST
              (bowl-order-from-drop 720))

(assert-equal "Faldende fakultet 5P3" 60 (falling-factorial 5 3))
(assert-equal "Forskellige navne, første rang" '(1 2)
              (unrank-distinct-indices 3 2 1))
(assert-equal "Forskellige navne, sidste rang" '(3 2)
              (unrank-distinct-indices 3 2 6))

(let ((family (make-bounded-composition-family 6 2 1 5)))
  (assert-equal "Begrænsede kompositioner tælles præcist" 5 (family-count family))
  (assert-equal "Begrænset komposition rang 3" '(3 3) (family-unrank1 family 3)))

(let ((family (make-cutlet-partition-family 6 3 #f)))
  (assert-equal "Positive tredelinger af 6" 10 (family-count family)))

(let ((family (make-cutlet-partition-family 6 3 2)))
  (assert-equal "Portfilteret bevarer fire tredelinger" 4 (family-count family))
  (assert-equal "Første filtrerede tredeling" '(1 1 4) (family-unrank1 family 1))
  (assert-equal "Sidste filtrerede tredeling" '(2 3 1) (family-unrank1 family 4)))

(let ((family (make-weaving-family '(2 1))))
  (assert-equal "Vævning 2,1 har én lovlig række" 1 (family-count family))
  (assert-equal "Vævning 2,1" '(1 1 2) (family-unrank1 family 1)))

(let ((family (make-weaving-family '(2 2))))
  (assert-equal "Vævning 2,2 har to lovlige rækker" 2 (family-count family))
  (assert-equal "Vævning 2,2 rang 1" '(1 1 2 2) (family-unrank1 family 1))
  (assert-equal "Vævning 2,2 rang 2" '(1 2 1 2) (family-unrank1 family 2)))

(let* ((ctx (make-base-monster-context FOUNDATION-DAY FOUNDATION-DAY))
       (validated (base-validate-discrete-day (context-calculation-day ctx))))
  (assert-equal "Grundkonteksten ejer inputtet" FOUNDATION-DAY (context-target-day ctx))
  (assert-equal "Grundvalidator accepterer heltalsdag" 'ok (vector-ref validated 0)))

(let* ((r1 (sauce FOUNDATION-DAY FOUNDATION-DAY))
       (r2 (sauce FOUNDATION-DAY FOUNDATION-DAY)))
  (assert-equal "Routinen er deterministisk for grundlæggelsesdagen"
                (vector->plain-list (sauce-bowls r1))
                (vector->plain-list (sauce-bowls r2)))
  (assert-equal "Rækkefølgen ved dråbe 46 er deterministisk"
                (sauce-order-at-46 r1)
                (sauce-order-at-46 r2))
  (assert-equal "Rækkefølgen ved dråbe 46 er en permutation"
                '(1 2 3 4 5 6)
                (stable-sort (sauce-order-at-46 r1) <)))

(reset-gates!)
(let ((g1 (positive-gate-gap 1))
      (gm1 (negative-gate-gap 1)))
  (assert-true "Positivt portgab ligger i 42..963"
               (and (>= g1 GATE-GAP-MIN) (<= g1 GATE-GAP-MAX)))
  (assert-true "Negativt portgab ligger i 42..963"
               (and (>= gm1 GATE-GAP-MIN) (<= gm1 GATE-GAP-MAX))))

(display "RESULTAT: ")
(display passed)
(display " bestået, ")
(display failed)
(display " fejl")
(newline)

(if (= failed 0)
    (begin (display "SAMLET: GRØN") (newline) (exit 0))
    (begin (display "SAMLET: RØD") (newline) (exit 1)))
