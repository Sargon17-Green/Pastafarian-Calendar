(in-package #:pastafari.lv.tests)

(defvar *stage-01-test-count* 0)
(defvar *stage-01-failure-count* 0)

(defun fail-test (name expected actual)
  (incf *stage-01-failure-count*)
  (format t "NEIZDEVĀS ~A~%  gaidīts: ~S~%  iegūts:  ~S~%" name expected actual))

(defun pass-test (name)
  (format t "IZDEVĀS ~A~%" name))

(defmacro check-equal (name expected form &key (test ''equal))
  `(progn
     (incf *stage-01-test-count*)
     (let ((actual ,form)
           (wanted ,expected))
       (if (funcall ,test wanted actual)
           (pass-test ,name)
           (fail-test ,name wanted actual)))))

(defmacro check-true (name form)
  `(check-equal ,name t (not (null ,form))))

(defun vector-list (vector)
  (coerce vector 'list))

(defun read-fixtures ()
  (with-open-file (stream "fixtures/stage01-primitives.sexp" :direction :input)
    (read stream)))

(defun fixture (fixtures key)
  (getf fixtures key))

(defun unique-list-p (items &key (test #'equal))
  (= (length items) (length (remove-duplicates items :test test))))

(defun catalog-indexes (entries)
  (loop for entry across entries collect (catalog-entry-canonical-index entry)))

(defun catalog-texts (entries)
  (loop for entry across entries collect (catalog-entry-text entry)))

(defun test-catalog ()
  (let ((cutlets (all-cutlet-entries))
        (months (all-month-entries)))
    (check-equal "kataloga versija" "lv-1.0.0" *source-language-catalog-version* :test #'string=)
    (check-equal "17 kotlešu ieraksti" 17 (length cutlets) :test #'=)
    (check-equal "47 mēnešu ieraksti" 47 (length months) :test #'=)
    (check-equal "kotlešu kanoniskie indeksi"
                 (loop for i from 1 to 17 collect i)
                 (catalog-indexes cutlets))
    (check-equal "mēnešu kanoniskie indeksi"
                 (loop for i from 1 to 47 collect i)
                 (catalog-indexes months))
    (check-true "kotlešu teksti ir unikāli" (unique-list-p (catalog-texts cutlets) :test #'string=))
    (check-true "mēnešu teksti ir unikāli" (unique-list-p (catalog-texts months) :test #'string=))
    (check-equal "kviešu tulkojums" "kvieši" (cutlet-name-by-index 12) :test #'string=)
    (check-equal "četru devītdaļu tulkojums" "četras devītdaļas" (cutlet-name-by-index 6) :test #'string=)
    (check-equal "trīs piektdaļu tulkojums" "trīs piektdaļas" (month-name-by-index 7) :test #'string=)
    (check-equal "Urukas vietvārds" "Uruka" (month-name-by-index 16) :test #'string=)
    (check-equal "Nīnives vietvārds" "Nīnive" (month-name-by-index 28) :test #'string=)
    (check-equal "Babilonas vietvārds" "Babilona" (month-name-by-index 41) :test #'string=)))

(defun test-base-infrastructure ()
  (let* ((ctx (make-monster-context 11 13))
         (dispatcher (make-base-dispatcher))
         (validator (make-validation-manager))
         (metrics (make-metrics-shell))
         (logs (make-log-shell)))
    (check-equal "konteksta aprēķina diena" 11 (monster-context-calculation-day ctx) :test #'=)
    (check-equal "konteksta mērķa diena" 13 (monster-context-target-day ctx) :test #'=)
    (check-true "semantiskais un novērojamības stāvoklis nav viens objekts"
                (not (eq (monster-context-semantic-state ctx)
                         (monster-context-observability-state ctx))))
    (dispatcher-register dispatcher :probe
                         (lambda (context)
                           (+ (monster-context-calculation-day context)
                              (monster-context-target-day context))))
    (check-equal "bāzes dispečers" 24 (dispatcher-dispatch dispatcher :probe ctx) :test #'=)
    (check-true "validācijas pārvaldnieks" (validation-require validator (= 2 (+ 1 1)) "Nederīgs invariants."))
    (metrics-bump metrics :calls)
    (metrics-bump metrics :calls 2)
    (check-equal "metriku karkass" 3 (metrics-read metrics :calls) :test #'=)
    (log-record logs :probe 11 13)
    (check-equal "žurnāla karkass" '((:probe 11 13)) (log-entries logs))))

(defun test-primitives (fixtures)
  (check-equal "M vērtība" (fixture fixtures :m) m :test #'=)
  (dolist (pair (fixture fixtures :save))
    (check-equal (format nil "SAVE ~A" (first pair))
                 (second pair)
                 (save (first pair))
                 :test #'=))
  (dolist (pair (fixture fixtures :day-count))
    (check-equal (format nil "dienas skaitlis ~A" (first pair))
                 (second pair)
                 (day-count (first pair))
                 :test #'=))
  (check-equal "parastais atlikums negatīvam skaitlim" 4 (regular-mod -1 5) :test #'=)
  (let ((same (work-counts foundation-day foundation-day)))
    (check-equal "vienādas dienas attālums" 1 (work-counts-distance same) :test #'=)
    (check-equal "vienādas dienas virziens" 2 (work-counts-direction same) :test #'=))
  (let ((cross (work-counts (1- foundation-day) (1+ foundation-day))))
    (check-equal "šķērsojuma darbības skaitlis" 2 (work-counts-action cross) :test #'=)
    (check-equal "šķērsojuma mērķa skaitlis" 3 (work-counts-target cross) :test #'=)
    (check-equal "šķērsojuma attālums" 3 (work-counts-distance cross) :test #'=)
    (check-equal "šķērsojuma savienojums" 5 (work-counts-connection cross) :test #'=)
    (check-equal "šķērsojuma virziens" 3 (work-counts-direction cross) :test #'=)))

(defun test-stones-and-permutations (fixtures)
  (let ((stones (build-stones)))
    (check-equal "akmeņu tabulas izmērs" 47 (length stones) :test #'=)
    (check-equal "otrais akmens"
                 (fixture fixtures :stone-2)
                 (vector-list (aref stones 2))))
  (check-equal "permutācijas rangs 1"
               (fixture fixtures :permutation-1)
               (vector-list (permutation-unrank-1 1 #(1 2 3 4 5 6))))
  (check-equal "permutācijas rangs 720"
               (fixture fixtures :permutation-720)
               (vector-list (permutation-unrank-1 720 #(1 2 3 4 5 6))))
  (check-equal "720. piliena bļodu secība"
               (fixture fixtures :permutation-720)
               (vector-list (bowl-order-from-drop 720))))

(defun test-combinatorics (fixtures)
  (check-equal "krītošais faktoriāls" 120 (falling-factorial 5 3) :test #'=)
  (check-equal "atšķirīgo indeksu pirmais rangs"
               '(1 2 3)
               (vector-list (unrank-distinct-indices 5 3 1)))
  (check-equal "atšķirīgo indeksu pēdējais rangs"
               '(5 4 3)
               (vector-list (unrank-distinct-indices 5 3 60)))
  (let ((counter (make-bounded-composition-counter 6 2 1 5)))
    (check-equal "ierobežoto kompozīciju skaits"
                 (fixture fixtures :bounded-count)
                 (bounded-composition-count counter)
                 :test #'=)
    (check-equal "ierobežotās kompozīcijas trešais rangs"
                 (fixture fixtures :bounded-rank-3)
                 (vector-list (bounded-composition-unrank1 counter 3))))
  (let ((counter (make-cutlet-partition-counter 6 3 2)))
    (check-equal "iekšējo vārtu filtrētās saimes skaits"
                 (fixture fixtures :cutlet-boundary-count)
                 (cutlet-partition-count counter)
                 :test #'=)
    (check-equal "iekšējo vārtu filtrētās saimes pirmais rangs"
                 (fixture fixtures :cutlet-boundary-rank-1)
                 (vector-list (cutlet-partition-unrank1 counter 1))))
  (let ((counter (make-weaving-counter #(2 2))))
    (check-equal "pinumu skaits"
                 (fixture fixtures :weaving-count)
                 (weaving-count counter)
                 :test #'=)
    (check-equal "pinuma pirmais rangs"
                 (fixture fixtures :weaving-rank-1)
                 (vector-list (weaving-unrank1 counter 1)))
    (check-equal "pinuma otrais rangs"
                 (fixture fixtures :weaving-rank-2)
                 (vector-list (weaving-unrank1 counter 2)))))

(defun test-selection ()
  (let ((short-stream (make-answer-stream :first m :direction-step -1)))
    (check-equal "īsās izvēles noraidījums paliek tajā pašā gredzenā"
                 1 (choose-rank-short short-stream 2) :test #'=))
  (let* ((stream (make-answer-stream :first 1 :direction-step 1))
         (n (1+ m)))
    (check-equal "plašā izvēle M+1" n (choose-rank-wide stream n) :test #'=))
  (let* ((stream (make-answer-stream :first 1 :direction-step 1))
         (n (* m m)))
    (check-equal "plašā izvēle M^2" (1+ m) (choose-rank-wide stream n) :test #'=))
  (let* ((stream (make-answer-stream :first 1 :direction-step 1))
         (n (1+ (* m m))))
    (check-equal "plašā izvēle M^2+1" (1- m) (choose-rank-wide stream n) :test #'=)))

(defun source-contains-forbidden-future-token-p ()
  (let ((tokens '("oldRemainder" "oldDayTag" "oldDistance" "mutateStonesWrong"
                  "orderAt46Latch" "biasedLegacyPick" "LEGACY_YEAR_MAX"
                  "VirtualLegacyList" "oldContiguousMonthDayGuess")))
    (dolist (path '("src/package.lisp" "src/source-language-catalog.lisp" "src/monster-base.lisp") nil)
      (with-open-file (stream path :direction :input)
        (let ((text (make-string (file-length stream))))
          (read-sequence text stream)
          (when (some (lambda (token) (search token text :test #'char=)) tokens)
            (return-from source-contains-forbidden-future-token-p t)))))))

(defun test-stage-boundary ()
  (check-equal "ražošanas kodā nav nākamo ielāpu marķieru"
               nil (source-contains-forbidden-future-token-p)))

(defun run-stage-01-tests ()
  (setf *stage-01-test-count* 0
        *stage-01-failure-count* 0)
  (let ((fixtures (read-fixtures)))
    (test-catalog)
    (test-base-infrastructure)
    (test-primitives fixtures)
    (test-stones-and-permutations fixtures)
    (test-combinatorics fixtures)
    (test-selection)
    (test-stage-boundary))
  (format t "~%KOPĀ: ~D pārbaudes; neveiksmīgas: ~D.~%"
          *stage-01-test-count* *stage-01-failure-count*)
  (when (plusp *stage-01-failure-count*)
    (error "1. posma pārbaudes neizdevās."))
  t)
