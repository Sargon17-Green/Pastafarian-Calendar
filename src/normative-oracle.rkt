#lang racket/base

(require racket/list
         racket/match
         "constants.rkt"
         "source-language-catalog.rkt")

(provide
 regular-mod save-value ceil-div wrap1
 day-count (struct-out work-counts) work-counts-for
 build-stones build-hidden-drops build-visible-drops
 permutation-unrank1 bowl-order-from-number bowl-order-from-drop
 initial-bowls apply-visible-drops-to-bowls post-stir12
 (struct-out sauce-result) oracle-sauce
 (struct-out answer-stream) ask-bowl answer-at choose-rank-short choose-rank-wide choose-rank
 falling-factorial unrank-distinct-indices
 make-bounded-composition-family
 (struct-out ordered-family)
 (struct-out gate-state) make-gate-state ensure-gate-index! gate-index-at-or-before exact-gate-index
 (struct-out year) oracle-year5000 oracle-next-year oracle-previous-year oracle-find-target-year
 make-cutlet-partition-family
 count-weavings-for-lengths unrank-weaving
 (struct-out year-structure) oracle-build-year-structure
 oracle-calendar-date)

(struct work-counts (action target distance connection direction) #:transparent)
(struct sauce-result (bowls order-at-drop46) #:transparent)
(struct answer-stream (first direction-step) #:transparent)
(struct ordered-family (count unrank1) #:transparent)
(struct gate-state (table min-known max-known) #:mutable #:transparent)
(struct year (number open-gate-index close-gate-index open-gate-day close-gate-day) #:transparent)
(struct cutlet (name-index open-gate-index close-gate-index first-day last-day) #:transparent)
(struct year-structure
  (cutlet-count cutlet-partition cutlet-name-indices cutlets
                month-count month-lengths month-weaving month-name-indices)
  #:transparent)

(define (regular-mod x d)
  (unless (and (exact-integer? d) (positive? d))
    (raise-arguments-error 'regular-mod "daliklis turi būti teigiamas tikslus sveikasis skaičius" "d" d))
  (modulo x d))

(define (save-value x)
  (add1 (regular-mod (sub1 x) M)))

(define (ceil-div a b)
  (unless (and (exact-integer? a) (>= a 0) (exact-integer? b) (positive? b))
    (raise-arguments-error 'ceil-div "netinkami tikslūs sveikieji argumentai" "a" a "b" b))
  (quotient (+ a b -1) b))

(define (wrap1 position size)
  (unless (and (exact-integer? size) (positive? size))
    (raise-arguments-error 'wrap1 "dydis turi būti teigiamas" "size" size))
  (add1 (regular-mod (sub1 position) size)))

(define (day-count day)
  (cond
    [(= day FOUNDATION-DAY) 1]
    [(> day FOUNDATION-DAY) (add1 (* 2 (- day FOUNDATION-DAY)))]
    [else (* 2 (- FOUNDATION-DAY day))]))

(define (work-counts-for calculation-day target-day)
  (define c (day-count calculation-day))
  (define t (day-count target-day))
  (define distance (add1 (abs (- target-day calculation-day))))
  (define direction
    (cond [(< target-day calculation-day) 1]
          [(= target-day calculation-day) 2]
          [else 3]))
  (work-counts c t distance (+ c t) direction))

(define (build-stones)
  (define out (make-vector 46 #f))
  (vector-set! out 0 (vector 17 29 43 71 101))
  (for ([i (in-range 2 47)])
    (define old (vector-ref out (- i 2)))
    (define w (vector-ref old WHEAT))
    (define b (vector-ref old BARLEY))
    (define s (vector-ref old SALT))
    (define m (vector-ref old BITTER))
    (define r (vector-ref old RED))
    (vector-set!
     out
     (sub1 i)
     (vector
      (save-value (+ (* w w) (* 3 b) i))
      (save-value (+ (* b b) (* 5 s) w))
      (save-value (+ (* s s) (* 7 m) b))
      (save-value (+ (* m m) (* 11 r) s))
      (save-value (+ (* r r) (* 13 w) m)))))
  out)

(define STONES (build-stones))

(define (stone-row stones k)
  (vector-ref stones (sub1 k)))

(define (build-hidden-drops counts [stones STONES])
  (define hidden (make-vector 7 #f))
  (for ([k (in-range 1 8)])
    (define coeff (vector-ref HIDDEN-COEFF (sub1 k)))
    (define row (stone-row stones k))
    (define x0
      (+ (work-counts-action counts)
         (* (vector-ref coeff 0) (work-counts-target counts))
         (* (vector-ref coeff 1) (work-counts-distance counts))
         (* (vector-ref coeff 2) (work-counts-connection counts))
         (* (vector-ref coeff 3) (work-counts-direction counts))
         (for/sum ([v (in-vector row)]) v)))
    (define x (save-value x0))
    (for ([grind (in-range 1 8)])
      (define old-x x)
      (define kind (vector-ref HIDDEN-GRIND-STONE (sub1 grind)))
      (set! x
            (save-value
             (+ (* old-x old-x)
                (* 3 old-x)
                (vector-ref row kind)
                grind))))
    (vector-set! hidden (sub1 k) x))
  hidden)

(define (build-visible-drops counts [stones STONES] [hidden (build-hidden-drops counts stones)])
  (define timeline (make-hash))
  (for ([k (in-range 1 8)])
    (hash-set! timeline (- 1 k) (vector-ref hidden (sub1 k))))
  (define visible (make-vector 46 #f))
  (for ([i (in-range 1 47)])
    (define p1 (hash-ref timeline (sub1 i)))
    (define p3 (hash-ref timeline (- i 3)))
    (define p7 (hash-ref timeline (- i 7)))
    (define row (stone-row stones i))
    (define x
      (save-value
       (+ (* (vector-ref row WHEAT) (work-counts-action counts))
          (* (vector-ref row BARLEY) (work-counts-target counts))
          (* (vector-ref row SALT) (work-counts-distance counts))
          (* (vector-ref row BITTER) (work-counts-connection counts))
          (* (vector-ref row RED) (work-counts-direction counts))
          p1 (* 3 p3) (* 5 p7) i)))
    (for ([grind (in-range 1 12)])
      (define old-x x)
      (define g (vector-ref VISIBLE-GRINDS (sub1 grind)))
      (set! x
            (save-value
             (+ (* old-x old-x)
                (* (vector-ref g 0) old-x)
                (* (vector-ref g 1) p1)
                (* (vector-ref g 2) p3)
                (* (vector-ref g 3) p7)
                (vector-ref row (vector-ref g 4))))))
    (hash-set! timeline i x)
    (vector-set! visible (sub1 i) x))
  visible)

(define (factorial-exact n)
  (for/fold ([acc 1]) ([i (in-range 2 (add1 n))]) (* acc i)))

(define (list-remove-at xs zero-index)
  (append (take xs zero-index) (drop xs (add1 zero-index))))

(define (permutation-unrank1 rank1 items-ascending)
  (define n (length items-ascending))
  (define total (factorial-exact n))
  (unless (and (exact-integer? rank1) (<= 1 rank1 total))
    (raise-arguments-error 'permutation-unrank1 "rango reikšmė nepatenka į leistiną intervalą" "rank1" rank1))
  (let loop ([rank0 (sub1 rank1)] [remaining items-ascending] [result '()])
    (if (null? remaining)
        (list->vector (reverse result))
        (let* ([slots-left (length remaining)]
               [block (factorial-exact (sub1 slots-left))]
               [q (quotient rank0 block)]
               [next-rank (regular-mod rank0 block)]
               [chosen (list-ref remaining q)])
          (loop next-rank
                (list-remove-at remaining q)
                (cons chosen result))))))

(define (bowl-order-from-number order-number)
  (permutation-unrank1 order-number '(1 2 3 4 5 6)))

(define (bowl-order-from-drop drop-value)
  (bowl-order-from-number (add1 (regular-mod (sub1 drop-value) 720))))

(define (initial-bowls counts)
  (define bowls (make-vector 6 #f))
  (for ([id (in-range 1 7)])
    (define s
      (+ (work-counts-action counts)
         (* (work-counts-target counts) id)
         (work-counts-distance counts)
         (work-counts-connection counts)
         (work-counts-direction counts)
         (let ([p (vector-ref BOWL-PRIME (sub1 id))]) (* p p))))
    (vector-set! bowls (sub1 id) (save-value (+ (* s s) id))))
  bowls)

(define (bowl-ref bowls id)
  (vector-ref bowls (sub1 id)))

(define (bowl-set! bowls id value)
  (vector-set! bowls (sub1 id) value))

(define (apply-visible-drops-to-bowls bowls visible [stones STONES])
  (define current (vector-copy bowls))
  (define order-at-46 #f)
  (for ([i (in-range 1 47)])
    (define drop-value (vector-ref visible (sub1 i)))
    (define order (bowl-order-from-drop drop-value))
    (define old (vector-copy current))
    (define pour (make-vector 6 0))
    (define first-id (vector-ref order 0))
    (define second-id (vector-ref order 1))
    (define third-id (vector-ref order 2))
    (define row (stone-row stones i))
    (vector-set! pour 0 (save-value (+ (* drop-value drop-value)
                                      (* (vector-ref row WHEAT) (bowl-ref old first-id))
                                      (* 3 i))))
    (vector-set! pour 1 (save-value (+ (* drop-value drop-value)
                                      (* (vector-ref row BARLEY) (bowl-ref old second-id))
                                      (* 5 i))))
    (vector-set! pour 2 (save-value (+ (* drop-value drop-value)
                                      (* (vector-ref row SALT) (bowl-ref old third-id))
                                      (* 7 i))))
    (define next-bowls (make-vector 6 #f))
    (for ([position (in-range 1 7)])
      (define id (vector-ref order (sub1 position)))
      (define prev-id (vector-ref order (sub1 (wrap1 (sub1 position) 6))))
      (define next-id (vector-ref order (sub1 (wrap1 (add1 position) 6))))
      (define kind (vector-ref BOWL-STIR-STONE-BY-POSITION (sub1 position)))
      (define s
        (+ (bowl-ref old id)
           (* 2 (bowl-ref old prev-id))
           (* 3 (bowl-ref old next-id))
           (vector-ref pour (sub1 position))
           drop-value
           (vector-ref row kind)))
      (bowl-set!
       next-bowls
       id
       (save-value
        (+ (* s s)
           (* 5 (bowl-ref old prev-id) (bowl-ref old next-id))
           (* i position)))))
    (set! current next-bowls)
    (when (= i 46)
      (set! order-at-46 (vector-copy order))))
  (values current order-at-46))

(define (vector-sum-exact v)
  (for/sum ([x (in-vector v)]) x))

(define (post-stir12 bowls)
  (define current (vector-copy bowls))
  (for ([stir (in-range 1 13)])
    (define old (vector-copy current))
    (define saved-stir-sum (save-value (+ (vector-sum-exact old) (* 149 stir))))
    (define order-number (add1 (regular-mod (sub1 saved-stir-sum) 720)))
    (define order (bowl-order-from-number order-number))
    (define next-bowls (make-vector 6 #f))
    (for ([position (in-range 1 7)])
      (define id (vector-ref order (sub1 position)))
      (define prev-id (vector-ref order (sub1 (wrap1 (sub1 position) 6))))
      (define next-id (vector-ref order (sub1 (wrap1 (add1 position) 6))))
      (define s
        (+ (bowl-ref old id)
           (* 3 (bowl-ref old prev-id))
           (* 5 (bowl-ref old next-id))
           saved-stir-sum
           stir
           (* position position)))
      (bowl-set!
       next-bowls
       id
       (save-value
        (+ (* s s)
           (* 7 (bowl-ref old prev-id) (bowl-ref old next-id))))))
    (set! current next-bowls))
  current)

(define (oracle-sauce calculation-day target-day)
  (define counts (work-counts-for calculation-day target-day))
  (define hidden (build-hidden-drops counts STONES))
  (define visible (build-visible-drops counts STONES hidden))
  (define bowls (initial-bowls counts))
  (define-values (after-drops order46)
    (apply-visible-drops-to-bowls bowls visible STONES))
  (sauce-result (post-stir12 after-drops) order46))

(define (index-of-vector v value)
  (for/first ([x (in-vector v)] [i (in-naturals)] #:when (= x value)) i))

(define (next-bowl-in-drop46-order sauce queried-id)
  (define order (sauce-result-order-at-drop46 sauce))
  (define p (index-of-vector order queried-id))
  (unless p
    (raise-arguments-error 'next-bowl-in-drop46-order "dubens identifikatoriaus nėra tvarkoje" "queried-id" queried-id))
  (vector-ref order (regular-mod (add1 p) 6)))

(define (ask-bowl sauce queried-id seal)
  (define next-id (next-bowl-in-drop46-order sauce queried-id))
  (define bowls (sauce-result-bowls sauce))
  (define first
    (save-value
     (+ (let ([x (+ (bowl-ref bowls queried-id) seal 181)]) (* x x))
        (* 179 (bowl-ref bowls next-id))
        seal)))
  (define direction-number
    (save-value
     (+ (let ([x (+ first seal 1 193)]) (* x x))
        (* 193 first)
        (* 197 (bowl-ref bowls 6)))))
  (answer-stream first (if (= (regular-mod direction-number 2) 1) +1 -1)))

(define (answer-at stream k)
  (add1 (regular-mod (+ (sub1 (answer-stream-first stream))
                         (* (answer-stream-direction-step stream) k))
                     M)))

(define (choose-rank-short stream N)
  (unless (and (exact-integer? N) (<= 1 N M))
    (raise-arguments-error 'choose-rank-short "N turi būti intervale 1..M" "N" N))
  (define acceptance-limit (* (quotient M N) N))
  (let loop ([k 0])
    (define x (answer-at stream k))
    (if (<= x acceptance-limit)
        (add1 (regular-mod (sub1 x) N))
        (loop (add1 k)))))

(define (smallest-power-count base N)
  (let loop ([k 1] [space base])
    (if (>= space N)
        (values k space)
        (loop (add1 k) (* space base)))))

(define (choose-rank-wide stream N)
  (unless (and (exact-integer? N) (> N M))
    (raise-arguments-error 'choose-rank-wide "N turi būti didesnis už M" "N" N))
  (define-values (k space) (smallest-power-count M N))
  (define wide0
    (let loop ([j 0] [weight 1] [wide 1])
      (if (= j k)
          wide
          (loop (add1 j)
                (* weight M)
                (+ wide (* (sub1 (answer-at stream j)) weight))))))
  (define acceptance-limit (* (quotient space N) N))
  (let loop ([w wide0])
    (if (<= w acceptance-limit)
        (add1 (regular-mod (sub1 w) N))
        (loop (add1 (regular-mod (+ (sub1 w) (answer-stream-direction-step stream)) space))))))

(define (choose-rank stream N)
  (unless (and (exact-integer? N) (positive? N))
    (raise-arguments-error 'choose-rank "N turi būti teigiamas tikslus sveikasis skaičius" "N" N))
  (if (<= N M)
      (choose-rank-short stream N)
      (choose-rank-wide stream N)))

(define (falling-factorial n k)
  (unless (and (exact-integer? n) (exact-integer? k) (<= 0 k n))
    (raise-arguments-error 'falling-factorial "netinkami argumentai" "n" n "k" k))
  (for/fold ([acc 1]) ([j (in-range 0 k)]) (* acc (- n j))))

(define (unrank-distinct-indices master-count k rank1)
  (define total (falling-factorial master-count k))
  (unless (and (exact-integer? rank1) (<= 1 rank1 total))
    (raise-arguments-error 'unrank-distinct-indices "rangas nepatenka į šeimą" "rank1" rank1))
  (let loop ([position 1]
             [remaining (range 1 (add1 master-count))]
             [r rank1]
             [out '()])
    (if (> position k)
        (reverse out)
        (let* ([suffix-length (- k position)]
               [block (falling-factorial (sub1 (length remaining)) suffix-length)])
          (let choose ([candidate-position 0] [rr r])
            (if (> rr block)
                (choose (add1 candidate-position) (- rr block))
                (let ([chosen (list-ref remaining candidate-position)])
                  (loop (add1 position)
                        (list-remove-at remaining candidate-position)
                        rr
                        (cons chosen out)))))))))

(define (make-bounded-composition-family total slots lo hi)
  (define memo (make-hash))
  (define (count-suffix rem k)
    (cond
      [(= k 0) (if (= rem 0) 1 0)]
      [(or (< rem (* k lo)) (> rem (* k hi))) 0]
      [else
       (hash-ref!
        memo
        (cons rem k)
        (lambda ()
          (for/sum ([x (in-range lo (add1 hi))])
            (count-suffix (- rem x) (sub1 k)))))]))
  (define (count-all) (count-suffix total slots))
  (define (unrank1 rank1)
    (unless (and (exact-integer? rank1) (<= 1 rank1 (count-all)))
      (raise-arguments-error 'bounded-composition-unrank1 "rangas nepatenka į šeimą" "rank1" rank1))
    (let loop ([position 1] [rem total] [r rank1] [out '()])
      (if (> position slots)
          (reverse out)
          (let choose ([x lo] [rr r])
            (cond
              [(> x hi) (error 'bounded-composition-unrank1 "nepavyko atverti leistino rango")]
              [else
               (define block (count-suffix (- rem x) (- slots position)))
               (if (> rr block)
                   (choose (add1 x) (- rr block))
                   (loop (add1 position) (- rem x) rr (cons x out)))])))))
  (ordered-family count-all unrank1))

(define (make-gate-state)
  (gate-state (make-hash (list (cons 0 FOUNDATION-DAY))) 0 0))

(define (gate-ref gs idx)
  (hash-ref (gate-state-table gs) idx))

(define (positive-gate-gap n)
  (define r (oracle-sauce FOUNDATION-DAY (+ FOUNDATION-DAY n)))
  (+ 41 (choose-rank (ask-bowl r 1 SEAL-GATE-GAP) 922)))

(define (negative-gate-gap n)
  (define r (oracle-sauce FOUNDATION-DAY (- FOUNDATION-DAY n)))
  (+ 41 (choose-rank (ask-bowl r 1 SEAL-GATE-GAP) 922)))

(define (ensure-gate-index! gs k)
  (when (> k (gate-state-max-known gs))
    (for ([n (in-range (add1 (gate-state-max-known gs)) (add1 k))])
      (hash-set! (gate-state-table gs)
                 n
                 (+ (gate-ref gs (sub1 n)) (positive-gate-gap n)))
      (set-gate-state-max-known! gs n)))
  (when (< k (gate-state-min-known gs))
    (let loop ([n (sub1 (gate-state-min-known gs))])
      (when (>= n k)
        (hash-set! (gate-state-table gs)
                   n
                   (- (gate-ref gs (add1 n)) (negative-gate-gap (abs n))))
        (set-gate-state-min-known! gs n)
        (loop (sub1 n)))))
  (gate-ref gs k))

(define (ensure-gates-cover! gs low-day high-day)
  (unless (<= low-day high-day)
    (raise-arguments-error 'ensure-gates-cover! "apatinė diena negali būti vėlesnė už viršutinę" "low-day" low-day "high-day" high-day))
  (let loop ()
    (when (> (gate-ref gs (gate-state-min-known gs)) low-day)
      (ensure-gate-index! gs (sub1 (gate-state-min-known gs)))
      (loop)))
  (let loop ()
    (when (< (gate-ref gs (gate-state-max-known gs)) high-day)
      (ensure-gate-index! gs (add1 (gate-state-max-known gs)))
      (loop))))

(define (gate-index-at-or-before gs day)
  (ensure-gates-cover! gs day day)
  (let loop ([lo (gate-state-min-known gs)] [hi (gate-state-max-known gs)])
    (if (= lo hi)
        lo
        (let ([mid (+ lo (quotient (+ (- hi lo) 1) 2))])
          (if (<= (gate-ref gs mid) day)
              (loop mid hi)
              (loop lo (sub1 mid)))))))

(define (exact-gate-index gs day)
  (define i (gate-index-at-or-before gs day))
  (and (= (gate-ref gs i) day) i))

(define (year-length gs open-index close-index)
  (- (gate-ref gs close-index) (gate-ref gs open-index)))

(define (valid-year-pair? gs open-index close-index)
  (and (>= (- close-index open-index) MIN-GATE-GAPS-PER-YEAR)
       (<= YEAR-MIN-DAYS
           (year-length gs open-index close-index)
           YEAR-MAX-DAYS)))

(define (make-year-from-indices gs number i j)
  (year number i j (gate-ref gs i) (gate-ref gs j)))

(define (oracle-year5000 calculation-day [gs (make-gate-state)])
  (ensure-gates-cover! gs (- calculation-day YEAR-MAX-DAYS) (+ calculation-day YEAR-MAX-DAYS))
  (define candidates
    (for*/list ([i (in-range (gate-state-min-known gs) (add1 (gate-state-max-known gs)))]
                [j (in-range (add1 i) (add1 (gate-state-max-known gs)))]
                #:when (valid-year-pair? gs i j)
                #:when (< (gate-ref gs i) calculation-day)
                #:when (<= calculation-day (gate-ref gs j)))
      (cons i j)))
  (define sorted
    (sort candidates
          (lambda (a b)
            (define la (year-length gs (car a) (cdr a)))
            (define lb (year-length gs (car b) (cdr b)))
            (or (< la lb)
                (and (= la lb)
                     (< (gate-ref gs (car a)) (gate-ref gs (car b))))))))
  (when (null? sorted)
    (error 'oracle-year5000 "nepavyko rasti 5000 metų kandidato"))
  (define r (oracle-sauce calculation-day calculation-day))
  (define rank (choose-rank (ask-bowl r 1 SEAL-YEAR-5000) (length sorted)))
  (define chosen (list-ref sorted (sub1 rank)))
  (values (make-year-from-indices gs 5000 (car chosen) (cdr chosen)) gs))

(define (oracle-next-year calculation-day known gs)
  (define open-index (year-close-gate-index known))
  (ensure-gates-cover! gs
                       (gate-ref gs (gate-state-min-known gs))
                       (+ (gate-ref gs open-index) YEAR-MAX-DAYS))
  (define candidates
    (let loop ([j (add1 open-index)] [acc '()])
      (ensure-gate-index! gs j)
      (define len (year-length gs open-index j))
      (cond
        [(> len YEAR-MAX-DAYS) (reverse acc)]
        [(valid-year-pair? gs open-index j) (loop (add1 j) (cons j acc))]
        [else (loop (add1 j) acc)])))
  (define sorted
    (sort candidates < #:key (lambda (j) (year-length gs open-index j))))
  (when (null? sorted)
    (error 'oracle-next-year "nepavyko rasti kitų metų kandidato"))
  (define r (oracle-sauce calculation-day (gate-ref gs open-index)))
  (define rank (choose-rank (ask-bowl r 1 SEAL-NEXT-YEAR) (length sorted)))
  (define close-index (list-ref sorted (sub1 rank)))
  (make-year-from-indices gs (add1 (year-number known)) open-index close-index))

(define (oracle-previous-year calculation-day known gs)
  (define close-index (year-open-gate-index known))
  (ensure-gates-cover! gs
                       (- (gate-ref gs close-index) YEAR-MAX-DAYS)
                       (gate-ref gs (gate-state-max-known gs)))
  (define candidates
    (let loop ([i (sub1 close-index)] [acc '()])
      (ensure-gate-index! gs i)
      (define len (year-length gs i close-index))
      (cond
        [(> len YEAR-MAX-DAYS) (reverse acc)]
        [(valid-year-pair? gs i close-index) (loop (sub1 i) (cons i acc))]
        [else (loop (sub1 i) acc)])))
  (define sorted
    (sort candidates < #:key (lambda (i) (year-length gs i close-index))))
  (when (null? sorted)
    (error 'oracle-previous-year "nepavyko rasti ankstesnių metų kandidato"))
  (define r (oracle-sauce calculation-day (gate-ref gs close-index)))
  (define rank (choose-rank (ask-bowl r 1 SEAL-PREVIOUS-YEAR) (length sorted)))
  (define open-index (list-ref sorted (sub1 rank)))
  (make-year-from-indices gs (sub1 (year-number known)) open-index close-index))

(define (oracle-find-target-year calculation-day target-day [gs (make-gate-state)])
  (define-values (anchor actual-gs) (oracle-year5000 calculation-day gs))
  (define y anchor)
  (let loop-forward ()
    (when (> target-day (year-close-gate-day y))
      (set! y (oracle-next-year calculation-day y actual-gs))
      (loop-forward)))
  (let loop-backward ()
    (when (<= target-day (year-open-gate-day y))
      (set! y (oracle-previous-year calculation-day y actual-gs))
      (loop-backward)))
  (unless (< (year-open-gate-day y) target-day (add1 (year-close-gate-day y)))
    (error 'oracle-find-target-year "tikslinė diena nepateko į rastų metų intervalą"))
  (values y actual-gs))

(define (make-cutlet-partition-family G K required-boundary-or-none)
  (define memo (make-hash))
  (define (count-state rem slots cumulative hit-boundary)
    (cond
      [(= slots 0)
       (if (and (= rem 0)
                (or (not required-boundary-or-none) hit-boundary))
           1
           0)]
      [(< rem slots) 0]
      [else
       (hash-ref!
        memo
        (list rem slots cumulative hit-boundary)
        (lambda ()
          (define max-x (- rem (sub1 slots)))
          (for/sum ([x (in-range 1 (add1 max-x))])
            (define next-cumulative (+ cumulative x))
            (cond
              [(and required-boundary-or-none
                    (not hit-boundary)
                    (> next-cumulative required-boundary-or-none))
               0]
              [else
               (define next-hit
                 (or hit-boundary
                     (and required-boundary-or-none
                          (= next-cumulative required-boundary-or-none))))
               (count-state (- rem x) (sub1 slots) next-cumulative next-hit)]))))]))
  (define (count-all) (count-state G K 0 #f))
  (define (unrank1 rank1)
    (unless (and (exact-integer? rank1) (<= 1 rank1 (count-all)))
      (raise-arguments-error 'cutlet-partition-unrank1 "rangas nepatenka į šeimą" "rank1" rank1))
    (let loop ([rem G] [slots K] [cumulative 0] [hit #f] [r rank1] [out '()])
      (if (= slots 0)
          (reverse out)
          (let choose ([x 1] [rr r])
            (define max-x (- rem (sub1 slots)))
            (when (> x max-x)
              (error 'cutlet-partition-unrank1 "nepavyko atverti leistino rango"))
            (define next-cumulative (+ cumulative x))
            (define allowed?
              (not (and required-boundary-or-none
                        (not hit)
                        (> next-cumulative required-boundary-or-none))))
            (define next-hit
              (or hit
                  (and required-boundary-or-none
                       (= next-cumulative required-boundary-or-none))))
            (define block
              (if allowed?
                  (count-state (- rem x) (sub1 slots) next-cumulative next-hit)
                  0))
            (if (> rr block)
                (choose (add1 x) (- rr block))
                (loop (- rem x)
                      (sub1 slots)
                      next-cumulative
                      next-hit
                      rr
                      (cons x out)))))))
  (ordered-family count-all unrank1))

(struct weave-state (remaining opened-up-to closed-up-to) #:transparent)

(define (list-set-at xs idx value)
  (for/list ([x (in-list xs)] [i (in-naturals)])
    (if (= i idx) value x)))

(define (legal-weave-move? state j original-lengths)
  (define idx (sub1 j))
  (define rem (list-ref (weave-state-remaining state) idx))
  (define original (list-ref original-lengths idx))
  (and (> rem 0)
       (let ([already-opened? (< rem original)])
         (or already-opened? (= j (add1 (weave-state-opened-up-to state)))))
       (let ([will-close? (= rem 1)])
         (or (not will-close?) (= j (add1 (weave-state-closed-up-to state)))))))

(define (apply-weave-move state j original-lengths)
  (define idx (sub1 j))
  (define remaining (weave-state-remaining state))
  (define rem (list-ref remaining idx))
  (define original (list-ref original-lengths idx))
  (define new-opened (if (= rem original) j (weave-state-opened-up-to state)))
  (define next-rem (sub1 rem))
  (define new-remaining (list-set-at remaining idx next-rem))
  (define new-closed (if (= next-rem 0) j (weave-state-closed-up-to state)))
  (weave-state new-remaining new-opened new-closed))

(define (make-weaving-counter lengths)
  (define original (if (vector? lengths) (vector->list lengths) lengths))
  (define m (length original))
  (define memo (make-hash))
  (define initial (weave-state original 0 0))
  (define (count state)
    (if (andmap zero? (weave-state-remaining state))
        1
        (hash-ref!
         memo
         state
         (lambda ()
           (for/sum ([j (in-range 1 (add1 m))]
                     #:when (legal-weave-move? state j original))
             (count (apply-weave-move state j original)))))))
  (values initial count original m))

(define (count-weavings-for-lengths lengths)
  (define-values (initial count original m) (make-weaving-counter lengths))
  (count initial))

(define (unrank-weaving lengths rank1)
  (define-values (initial count original m) (make-weaving-counter lengths))
  (define total (count initial))
  (unless (and (exact-integer? rank1) (<= 1 rank1 total))
    (raise-arguments-error 'unrank-weaving "rangas nepatenka į pynimo šeimą" "rank1" rank1))
  (let loop ([state initial] [r rank1] [out '()])
    (if (andmap zero? (weave-state-remaining state))
        (reverse out)
        (let choose ([j 1] [rr r])
          (cond
            [(> j m) (error 'unrank-weaving "nepavyko atverti pynimo rango")]
            [(not (legal-weave-move? state j original)) (choose (add1 j) rr)]
            [else
             (define next (apply-weave-move state j original))
             (define block (count next))
             (if (> rr block)
                 (choose (add1 j) (- rr block))
                 (loop next rr (cons j out)))])))))

(define (choose-cutlet-count structure-sauce y)
  (define gaps (- (year-close-gate-index y) (year-open-gate-index y)))
  (define candidates
    (for/list ([k (in-range MIN-CUTLETS (add1 MAX-CUTLETS))] #:when (<= k gaps)) k))
  (define rank (choose-rank (ask-bowl structure-sauce 2 SEAL-CUTLET-COUNT) (length candidates)))
  (list-ref candidates (sub1 rank)))

(define (choose-cutlet-partition calculation-day structure-sauce y cutlet-count gs)
  (define G (- (year-close-gate-index y) (year-open-gate-index y)))
  (define g (exact-gate-index gs calculation-day))
  (define required
    (and g
         (< (year-open-gate-index y) g (year-close-gate-index y))
         (- g (year-open-gate-index y))))
  (define family (make-cutlet-partition-family G cutlet-count required))
  (define rank (choose-rank (ask-bowl structure-sauce 2 SEAL-CUTLET-PARTITION)
                            ((ordered-family-count family))))
  ((ordered-family-unrank1 family) rank))

(define (choose-name-indices structure-sauce bowl-id seal master-count k)
  (define N (falling-factorial master-count k))
  (define rank (choose-rank (ask-bowl structure-sauce bowl-id seal) N))
  (unrank-distinct-indices master-count k rank))

(define (materialize-cutlets y partition name-indices gs)
  (let loop ([parts partition]
             [names name-indices]
             [cursor (year-open-gate-index y)]
             [out '()])
    (if (null? parts)
        (reverse out)
        (let* ([close (+ cursor (car parts))]
               [c (cutlet (car names)
                          cursor
                          close
                          (add1 (gate-ref gs cursor))
                          (gate-ref gs close))])
          (loop (cdr parts) (cdr names) close (cons c out))))))

(define (choose-month-count structure-sauce y)
  (define L (- (year-close-gate-day y) (year-open-gate-day y)))
  (define lo (ceil-div L MAX-MONTH-DAYS))
  (define hi (min MAX-MONTHS (quotient L MIN-MONTH-DAYS)))
  (unless (<= MIN-MONTHS lo hi MAX-MONTHS)
    (error 'choose-month-count "mėnesių skaičiaus ribos tapo negaliojančios"))
  (define rank (choose-rank (ask-bowl structure-sauce 3 SEAL-MONTH-COUNT) (add1 (- hi lo))))
  (+ lo (sub1 rank)))

(define (choose-month-lengths structure-sauce y month-count)
  (define L (- (year-close-gate-day y) (year-open-gate-day y)))
  (define family (make-bounded-composition-family L month-count MIN-MONTH-DAYS MAX-MONTH-DAYS))
  (define rank (choose-rank (ask-bowl structure-sauce 3 SEAL-MONTH-LENGTHS)
                            ((ordered-family-count family))))
  ((ordered-family-unrank1 family) rank))

(define (choose-month-weaving structure-sauce month-lengths)
  (define N (count-weavings-for-lengths month-lengths))
  (define rank (choose-rank (ask-bowl structure-sauce 4 SEAL-MONTH-WEAVING) N))
  (unrank-weaving month-lengths rank))

(define (oracle-build-year-structure calculation-day y gs)
  (define first-day (add1 (year-open-gate-day y)))
  (define r (oracle-sauce calculation-day first-day))
  (define cutlet-count (choose-cutlet-count r y))
  (define partition (choose-cutlet-partition calculation-day r y cutlet-count gs))
  (define cutlet-name-indices
    (choose-name-indices r 5 SEAL-CUTLET-NAMES 17 cutlet-count))
  (define cutlets (materialize-cutlets y partition cutlet-name-indices gs))
  (define month-count (choose-month-count r y))
  (define month-lengths (choose-month-lengths r y month-count))
  (define month-weaving (choose-month-weaving r month-lengths))
  (define month-name-indices
    (choose-name-indices r 5 SEAL-MONTH-NAMES 47 month-count))
  (year-structure cutlet-count partition cutlet-name-indices cutlets
                  month-count month-lengths month-weaving month-name-indices))

(define (find-cutlet-containing cutlets target-day)
  (for/first ([c (in-list cutlets)]
              #:when (<= (cutlet-first-day c) target-day (cutlet-last-day c)))
    c))

(define (oracle-calendar-date calculation-day target-day)
  (unless (and (exact-integer? calculation-day) (exact-integer? target-day))
    (raise-arguments-error 'oracle-calendar-date "abi dienos turi būti tikslūs sveikieji skaičiai"
                           "calculation-day" calculation-day
                           "target-day" target-day))
  (define-values (y gs) (oracle-find-target-year calculation-day target-day))
  (define structure (oracle-build-year-structure calculation-day y gs))
  (define chosen-cutlet (find-cutlet-containing (year-structure-cutlets structure) target-day))
  (unless chosen-cutlet
    (error 'oracle-calendar-date "tikslinė diena nepateko į jokį kotletą"))
  (define day-in-cutlet (add1 (- target-day (cutlet-first-day chosen-cutlet))))
  (define year-offset0 (- target-day (add1 (year-open-gate-day y))))
  (define month-id (list-ref (year-structure-month-weaving structure) year-offset0))
  (define day-in-month
    (for/sum ([id (in-list (take (year-structure-month-weaving structure) (add1 year-offset0)))]
              #:when (= id month-id))
      1))
  (vector (year-number y)
          (cutlet-name-by-index (cutlet-name-index chosen-cutlet))
          day-in-cutlet
          (month-name-by-index (list-ref (year-structure-month-name-indices structure) (sub1 month-id)))
          day-in-month))
