(in-package #:pastafari.lv.oracle)

(defconstant m (1- (expt 2 127)))
(defconstant tablets-day -278522)
(defconstant foundation-day -15055671)
(defconstant gate-gap-min 42)
(defconstant gate-gap-max 963)
(defconstant year-min-days 252)
(defconstant year-max-days 5778)
(defconstant min-cutlets 6)
(defconstant max-cutlets 17)
(defconstant min-month-days 4)
(defconstant max-month-days 123)

(defconstant seal-gate-gap 1)
(defconstant seal-year-5000 10)
(defconstant seal-next-year 11)
(defconstant seal-previous-year 12)
(defconstant seal-cutlet-count 20)
(defconstant seal-cutlet-partition 21)
(defconstant seal-cutlet-names 22)
(defconstant seal-month-count 30)
(defconstant seal-month-lengths 31)
(defconstant seal-month-weaving 32)
(defconstant seal-month-names 33)

(defun regular-mod (x d)
  (unless (and (integerp d) (plusp d))
    (error "Dalītājam jābūt pozitīvam veselam skaitlim."))
  (mod x d))

(defun save (x)
  (1+ (regular-mod (1- x) m)))

(defun ceil-div (a b)
  (unless (and (integerp a) (not (minusp a)) (integerp b) (plusp b))
    (error "Griestu dalījuma argumenti neatbilst līgumam."))
  (floor (+ a b -1) b))

(defun wrap1 (position size)
  (1+ (regular-mod (1- position) size)))

(defun day-count (day)
  (cond
    ((= day foundation-day) 1)
    ((> day foundation-day) (1+ (* 2 (- day foundation-day))))
    (t (* 2 (- foundation-day day)))))

(defstruct work-counts action target distance connection direction)

(defun work-counts (calculation-day target-day)
  (let* ((action (day-count calculation-day))
         (target (day-count target-day))
         (distance (1+ (abs (- target-day calculation-day))))
         (connection (+ action target))
         (direction (cond ((< target-day calculation-day) 1)
                          ((= target-day calculation-day) 2)
                          (t 3))))
    (make-work-counts :action action
                      :target target
                      :distance distance
                      :connection connection
                      :direction direction)))

(defconstant wheat 0)
(defconstant barley 1)
(defconstant salt 2)
(defconstant bitter 3)
(defconstant red 4)

(defun build-stones ()
  (let ((table (make-array 47 :initial-element nil)))
    (setf (aref table 1) (vector 17 29 43 71 101))
    (loop for i from 2 to 46
          for old = (aref table (1- i))
          do (setf (aref table i)
                   (vector
                    (save (+ (* (aref old wheat) (aref old wheat))
                             (* 3 (aref old barley)) i))
                    (save (+ (* (aref old barley) (aref old barley))
                             (* 5 (aref old salt)) (aref old wheat)))
                    (save (+ (* (aref old salt) (aref old salt))
                             (* 7 (aref old bitter)) (aref old barley)))
                    (save (+ (* (aref old bitter) (aref old bitter))
                             (* 11 (aref old red)) (aref old salt)))
                    (save (+ (* (aref old red) (aref old red))
                             (* 13 (aref old wheat)) (aref old bitter))))))
    table))

(defparameter *stones* (build-stones))

(defparameter *hidden-coeff*
  #(#(3 4 6 8)
    #(5 7 10 12)
    #(7 10 14 16)
    #(9 13 18 20)
    #(11 16 22 24)
    #(13 19 26 28)
    #(15 22 30 32)))

(defparameter *hidden-grind-stone*
  (vector wheat barley salt bitter red wheat barley))

(defun build-hidden-drops (counts &optional (stones *stones*))
  (let ((hidden (make-array 7)))
    (loop for k from 1 to 7
          for coeff = (aref *hidden-coeff* (1- k))
          for stone = (aref stones k)
          do (let ((x (+ (work-counts-action counts)
                         (* (aref coeff 0) (work-counts-target counts))
                         (* (aref coeff 1) (work-counts-distance counts))
                         (* (aref coeff 2) (work-counts-connection counts))
                         (* (aref coeff 3) (work-counts-direction counts))
                         (reduce #'+ stone))))
               (setf x (save x))
               (loop for grind from 1 to 7
                     for old-x = x
                     for kind = (aref *hidden-grind-stone* (1- grind))
                     do (setf x
                              (save (+ (* old-x old-x)
                                       (* 3 old-x)
                                       (aref stone kind)
                                       grind))))
               (setf (aref hidden (1- k)) x)))
    hidden))

(defparameter *visible-grinds*
  #(#(3 5 7 11 0)
    #(5 7 11 13 1)
    #(7 11 13 17 2)
    #(11 13 17 19 3)
    #(13 17 19 23 4)
    #(17 19 23 29 0)
    #(19 23 29 31 1)
    #(23 29 31 37 2)
    #(29 31 37 41 3)
    #(31 37 41 43 4)
    #(37 41 43 47 0)))

(defun build-visible-drops (counts &optional (stones *stones*) hidden)
  (let* ((hidden-values (or hidden (build-hidden-drops counts stones)))
         (timeline (make-hash-table :test #'eql))
         (visible (make-array 46)))
    (loop for k from 1 to 7
          do (setf (gethash (- 1 k) timeline) (aref hidden-values (1- k))))
    (loop for i from 1 to 46
          for stone = (aref stones i)
          do (let* ((prev1 (gethash (1- i) timeline))
                    (prev3 (gethash (- i 3) timeline))
                    (prev7 (gethash (- i 7) timeline))
                    (x (save (+ (* (aref stone wheat) (work-counts-action counts))
                                (* (aref stone barley) (work-counts-target counts))
                                (* (aref stone salt) (work-counts-distance counts))
                                (* (aref stone bitter) (work-counts-connection counts))
                                (* (aref stone red) (work-counts-direction counts))
                                prev1 (* 3 prev3) (* 5 prev7) i))))
               (loop for grind across *visible-grinds*
                     for old-x = x
                     do (setf x
                              (save (+ (* old-x old-x)
                                       (* (aref grind 0) old-x)
                                       (* (aref grind 1) prev1)
                                       (* (aref grind 2) prev3)
                                       (* (aref grind 3) prev7)
                                       (aref stone (aref grind 4))))))
               (setf (gethash i timeline) x
                     (aref visible (1- i)) x)))
    visible))

(defun factorial-exact (n)
  (loop with result = 1
        for k from 2 to n
        do (setf result (* result k))
        finally (return result)))

(defun permutation-unrank-1 (rank1 items-ascending)
  (let* ((remaining (coerce items-ascending 'list))
         (n (length remaining))
         (limit (factorial-exact n)))
    (unless (and (integerp rank1) (<= 1 rank1 limit))
      (error "Permutācijas rangs ir ārpus robežām."))
    (let ((rank0 (1- rank1))
          (result '()))
      (loop for slots-left from n downto 1
            for block = (factorial-exact (1- slots-left))
            do (multiple-value-bind (q rem) (floor rank0 block)
                 (setf rank0 rem)
                 (let ((chosen (nth q remaining)))
                   (push chosen result)
                   (setf remaining
                         (append (subseq remaining 0 q)
                                 (nthcdr (1+ q) remaining))))))
      (coerce (nreverse result) 'vector))))

(defun bowl-order-from-number (order-number)
  (permutation-unrank-1 order-number #(1 2 3 4 5 6)))

(defun bowl-order-from-drop (drop-value)
  (bowl-order-from-number (1+ (regular-mod (1- drop-value) 720))))

(defparameter *bowl-prime* #(17 19 23 29 31 37))
(defparameter *bowl-stir-stone-by-position* (vector wheat barley salt bitter red wheat))

(defun initial-bowls (counts)
  (let ((bowls (make-array 6)))
    (loop for bowl-id from 1 to 6
          for p = (aref *bowl-prime* (1- bowl-id))
          for s = (+ (work-counts-action counts)
                     (* (work-counts-target counts) bowl-id)
                     (work-counts-distance counts)
                     (work-counts-connection counts)
                     (work-counts-direction counts)
                     (* p p))
          do (setf (aref bowls (1- bowl-id))
                   (save (+ (* s s) bowl-id))))
    bowls))

(defun apply-visible-drops-to-bowls (bowls visible &optional (stones *stones*))
  (let ((working (copy-seq bowls))
        (order-at-drop-46 nil))
    (loop for i from 1 to 46
          for drop = (aref visible (1- i))
          for order = (bowl-order-from-drop drop)
          do (let* ((old (copy-seq working))
                    (pours (make-array 6 :initial-element 0))
                    (next-bowls (make-array 6)))
               (setf (aref pours 0)
                     (save (+ (* drop drop)
                              (* (aref (aref stones i) wheat)
                                 (aref old (1- (aref order 0))))
                              (* 3 i)))
                     (aref pours 1)
                     (save (+ (* drop drop)
                              (* (aref (aref stones i) barley)
                                 (aref old (1- (aref order 1))))
                              (* 5 i)))
                     (aref pours 2)
                     (save (+ (* drop drop)
                              (* (aref (aref stones i) salt)
                                 (aref old (1- (aref order 2))))
                              (* 7 i))))
               (loop for position from 1 to 6
                     for pos0 = (1- position)
                     for bowl-id = (aref order pos0)
                     for prev-id = (aref order (mod (1- pos0) 6))
                     for next-id = (aref order (mod (1+ pos0) 6))
                     for stone-kind = (aref *bowl-stir-stone-by-position* pos0)
                     for s = (+ (aref old (1- bowl-id))
                                (* 2 (aref old (1- prev-id)))
                                (* 3 (aref old (1- next-id)))
                                (aref pours pos0)
                                drop
                                (aref (aref stones i) stone-kind))
                     do (setf (aref next-bowls (1- bowl-id))
                              (save (+ (* s s)
                                       (* 5
                                          (aref old (1- prev-id))
                                          (aref old (1- next-id)))
                                       (* i position)))))
               (setf working next-bowls)
               (when (= i 46)
                 (setf order-at-drop-46 (copy-seq order)))))
    (values working order-at-drop-46)))

(defun post-stir-12 (bowls)
  (let ((working (copy-seq bowls)))
    (loop for stir from 1 to 12
          do (let* ((old (copy-seq working))
                    (saved-bowl-sum
                      (save (+ (reduce #'+ old) (* 149 stir))))
                    (order-number (1+ (regular-mod (1- saved-bowl-sum) 720)))
                    (order (bowl-order-from-number order-number))
                    (next-bowls (make-array 6)))
               (loop for position from 1 to 6
                     for pos0 = (1- position)
                     for bowl-id = (aref order pos0)
                     for prev-id = (aref order (mod (1- pos0) 6))
                     for next-id = (aref order (mod (1+ pos0) 6))
                     for s = (+ (aref old (1- bowl-id))
                                (* 3 (aref old (1- prev-id)))
                                (* 5 (aref old (1- next-id)))
                                saved-bowl-sum
                                stir
                                (* position position))
                     do (setf (aref next-bowls (1- bowl-id))
                              (save (+ (* s s)
                                       (* 7
                                          (aref old (1- prev-id))
                                          (aref old (1- next-id)))))))
               (setf working next-bowls)))
    working))

(defstruct sauce-result bowls order-at-drop-46)

(defun sauce (calculation-day target-day)
  (let* ((counts (work-counts calculation-day target-day))
         (hidden (build-hidden-drops counts *stones*))
         (visible (build-visible-drops counts *stones* hidden))
         (bowls (initial-bowls counts)))
    (multiple-value-bind (after-drops order-at-drop-46)
        (apply-visible-drops-to-bowls bowls visible *stones*)
      (make-sauce-result
       :bowls (post-stir-12 after-drops)
       :order-at-drop-46 order-at-drop-46))))

(defstruct answer-stream first direction-step)

(defun next-bowl-in-drop-46-order (sauce-result queried-bowl-id)
  (let* ((order (sauce-result-order-at-drop-46 sauce-result))
         (pos (position queried-bowl-id order :test #'=)))
    (unless pos
      (error "Jautātā bļoda nav atrasta 46. piliena secībā."))
    (aref order (mod (1+ pos) 6))))

(defun ask-bowl (sauce-result queried-bowl-id seal)
  (let* ((next-id (next-bowl-in-drop-46-order sauce-result queried-bowl-id))
         (bowls (sauce-result-bowls sauce-result))
         (first (save (+ (* (+ (aref bowls (1- queried-bowl-id)) seal 181)
                              (+ (aref bowls (1- queried-bowl-id)) seal 181))
                         (* 179 (aref bowls (1- next-id)))
                         seal)))
         (direction-number
           (save (+ (* (+ first seal 1 193) (+ first seal 1 193))
                    (* 193 first)
                    (* 197 (aref bowls 5)))))
         (step (if (oddp (regular-mod direction-number 2)) 1 -1)))
    (make-answer-stream :first first :direction-step step)))

(defun answer-at (stream k)
  (1+ (regular-mod (+ (1- (answer-stream-first stream))
                       (* (answer-stream-direction-step stream) k))
                   m)))

(defun choose-rank-short (stream n)
  (unless (and (integerp n) (<= 1 n m))
    (error "Īsās izvēles izmērs ir ārpus robežām."))
  (let ((acceptance-limit (* (floor m n) n)))
    (loop for k from 0
          for x = (answer-at stream k)
          when (<= x acceptance-limit)
            return (1+ (regular-mod (1- x) n)))))

(defun smallest-power-count (base n)
  (let ((k 1)
        (space base))
    (loop while (< space n)
          do (incf k)
             (setf space (* space base)))
    (values k space)))

(defun choose-rank-wide (stream n)
  (unless (and (integerp n) (> n m))
    (error "Plašās izvēles izmēram jābūt lielākam par M."))
  (multiple-value-bind (k space) (smallest-power-count m n)
    (let ((wide0 1)
          (weight 1))
      (loop for j from 0 below k
            do (incf wide0 (* (1- (answer-at stream j)) weight))
               (setf weight (* weight m)))
      (let ((acceptance-limit (* (floor space n) n))
            (w wide0))
        (loop
          (when (<= w acceptance-limit)
            (return (1+ (regular-mod (1- w) n))))
          (setf w (1+ (regular-mod (+ (1- w)
                                      (answer-stream-direction-step stream))
                                   space))))))))

(defun choose-rank (stream n)
  (unless (and (integerp n) (plusp n))
    (error "Izvēles saimes izmēram jābūt pozitīvam."))
  (if (<= n m)
      (choose-rank-short stream n)
      (choose-rank-wide stream n)))

(defun falling-factorial (n k)
  (unless (and (integerp n) (integerp k) (<= 0 k n))
    (error "Krītošā faktoriāla argumenti ir nederīgi."))
  (loop with result = 1
        for j from 0 below k
        do (setf result (* result (- n j)))
        finally (return result)))

(defun unrank-distinct-indices (n k rank1)
  (let ((limit (falling-factorial n k)))
    (unless (and (integerp rank1) (<= 1 rank1 limit))
      (error "Atšķirīgo vārdu rangs ir ārpus robežām."))
    (let ((remaining (loop for i from 1 to n collect i))
          (r rank1)
          (out '()))
      (loop for position from 1 to k
            for suffix-length = (- k position)
            for block = (falling-factorial (1- (length remaining)) suffix-length)
            do (loop for candidate from 0 below (length remaining)
                     do (if (> r block)
                            (decf r block)
                            (let ((chosen (nth candidate remaining)))
                              (push chosen out)
                              (setf remaining
                                    (append (subseq remaining 0 candidate)
                                            (nthcdr (1+ candidate) remaining)))
                              (return)))))
      (coerce (nreverse out) 'vector))))

(defstruct (bounded-composition-counter
            (:constructor %make-bounded-composition-counter
                (total slots lo hi memo)))
  total slots lo hi memo)

(defun make-bounded-composition-counter (total slots lo hi)
  (%make-bounded-composition-counter total slots lo hi (make-hash-table :test #'equal)))

(defun bounded-count-state (counter rem slots)
  (let ((lo (bounded-composition-counter-lo counter))
        (hi (bounded-composition-counter-hi counter))
        (memo (bounded-composition-counter-memo counter)))
    (cond
      ((zerop slots) (if (zerop rem) 1 0))
      ((or (< rem (* slots lo)) (> rem (* slots hi))) 0)
      (t
       (let ((key (list rem slots)))
         (multiple-value-bind (cached presentp) (gethash key memo)
           (if presentp
               cached
               (setf (gethash key memo)
                     (loop for x from lo to hi
                           sum (bounded-count-state counter (- rem x) (1- slots))))))))))))

(defun bounded-composition-count (counter)
  (bounded-count-state counter
                       (bounded-composition-counter-total counter)
                       (bounded-composition-counter-slots counter)))

(defun bounded-composition-unrank1 (counter rank1)
  (let ((count (bounded-composition-count counter)))
    (unless (and (integerp rank1) (<= 1 rank1 count))
      (error "Ierobežotās kompozīcijas rangs ir ārpus robežām."))
    (let ((r rank1)
          (rem (bounded-composition-counter-total counter))
          (slots (bounded-composition-counter-slots counter))
          (lo (bounded-composition-counter-lo counter))
          (hi (bounded-composition-counter-hi counter))
          (out '()))
      (loop while (plusp slots)
            do (loop for x from lo to hi
                     for block = (bounded-count-state counter (- rem x) (1- slots))
                     do (if (> r block)
                            (decf r block)
                            (progn
                              (push x out)
                              (decf rem x)
                              (decf slots)
                              (return)))))
      (coerce (nreverse out) 'vector))))

(defstruct (cutlet-partition-counter
            (:constructor %make-cutlet-partition-counter
                (g k required memo)))
  g k required memo)

(defun make-cutlet-partition-counter (g k required)
  (%make-cutlet-partition-counter g k required (make-hash-table :test #'equal)))

(defun cutlet-count-state (counter rem slots cumulative hit-boundary)
  (let ((required (cutlet-partition-counter-required counter))
        (memo (cutlet-partition-counter-memo counter)))
    (cond
      ((zerop slots)
       (if (and (zerop rem) (or (null required) hit-boundary)) 1 0))
      ((< rem slots) 0)
      (t
       (let ((key (list rem slots cumulative hit-boundary)))
         (multiple-value-bind (cached presentp) (gethash key memo)
           (if presentp
               cached
               (setf (gethash key memo)
                     (loop for x from 1 to (- rem (1- slots))
                           for next-cumulative = (+ cumulative x)
                           sum (cond
                                 ((and required
                                       (not hit-boundary)
                                       (> next-cumulative required))
                                  0)
                                 (t
                                  (cutlet-count-state
                                   counter
                                   (- rem x)
                                   (1- slots)
                                   next-cumulative
                                   (or hit-boundary
                                       (and required
                                            (= next-cumulative required))))))))))))))))

(defun cutlet-partition-count (counter)
  (cutlet-count-state counter
                       (cutlet-partition-counter-g counter)
                       (cutlet-partition-counter-k counter)
                       0 nil))

(defun cutlet-partition-unrank1 (counter rank1)
  (let ((count (cutlet-partition-count counter)))
    (unless (and (integerp rank1) (<= 1 rank1 count))
      (error "Kotletes dalījuma rangs ir ārpus robežām."))
    (let ((r rank1)
          (rem (cutlet-partition-counter-g counter))
          (slots (cutlet-partition-counter-k counter))
          (required (cutlet-partition-counter-required counter))
          (cumulative 0)
          (hit nil)
          (out '()))
      (loop while (plusp slots)
            do (loop for x from 1 to (- rem (1- slots))
                     for next-cumulative = (+ cumulative x)
                     do (unless (and required (not hit) (> next-cumulative required))
                          (let* ((next-hit (or hit
                                               (and required
                                                    (= next-cumulative required))))
                                 (block
                                   (cutlet-count-state counter
                                                        (- rem x)
                                                        (1- slots)
                                                        next-cumulative
                                                        next-hit)))
                            (if (> r block)
                                (decf r block)
                                (progn
                                  (push x out)
                                  (decf rem x)
                                  (decf slots)
                                  (setf cumulative next-cumulative
                                        hit next-hit)
                                  (return)))))))
      (coerce (nreverse out) 'vector))))

(defstruct (weaving-counter
            (:constructor %make-weaving-counter (lengths memo)))
  lengths memo)

(defun make-weaving-counter (lengths)
  (%make-weaving-counter (copy-seq lengths) (make-hash-table :test #'equal)))

(defun weaving-key (remaining opened-up-to closed-up-to)
  (list opened-up-to closed-up-to (coerce remaining 'list)))

(defun legal-weave-move-p (counter remaining opened-up-to closed-up-to j)
  (let* ((lengths (weaving-counter-lengths counter))
         (idx (1- j))
         (left (aref remaining idx))
         (original (aref lengths idx)))
    (and (plusp left)
         (let ((already-opened (< left original)))
           (or already-opened (= j (1+ opened-up-to))))
         (let ((will-close (= left 1)))
           (or (not will-close) (= j (1+ closed-up-to)))))))

(defun apply-weave-move (counter remaining opened-up-to closed-up-to j)
  (let* ((lengths (weaving-counter-lengths counter))
         (next (copy-seq remaining))
         (idx (1- j))
         (next-opened opened-up-to)
         (next-closed closed-up-to))
    (when (= (aref next idx) (aref lengths idx))
      (setf next-opened j))
    (decf (aref next idx))
    (when (zerop (aref next idx))
      (setf next-closed j))
    (values next next-opened next-closed)))

(defun weaving-count-state (counter remaining opened-up-to closed-up-to)
  (if (every #'zerop remaining)
      1
      (let* ((memo (weaving-counter-memo counter))
             (key (weaving-key remaining opened-up-to closed-up-to)))
        (multiple-value-bind (cached presentp) (gethash key memo)
          (if presentp
              cached
              (setf (gethash key memo)
                    (loop for j from 1 to (length remaining)
                          when (legal-weave-move-p counter remaining
                                                  opened-up-to closed-up-to j)
                            sum (multiple-value-bind (next next-opened next-closed)
                                    (apply-weave-move counter remaining
                                                      opened-up-to closed-up-to j)
                                  (weaving-count-state counter next
                                                       next-opened next-closed))))))))))

(defun weaving-count (counter)
  (weaving-count-state counter
                       (copy-seq (weaving-counter-lengths counter))
                       0 0))

(defun weaving-unrank1 (counter rank1)
  (let ((count (weaving-count counter)))
    (unless (and (integerp rank1) (<= 1 rank1 count))
      (error "Mēnešu pinuma rangs ir ārpus robežām."))
    (let* ((remaining (copy-seq (weaving-counter-lengths counter)))
           (opened 0)
           (closed 0)
           (r rank1)
           (out '())
           (total (reduce #'+ remaining)))
      (loop repeat total
            do (loop for j from 1 to (length remaining)
                     when (legal-weave-move-p counter remaining opened closed j)
                       do (multiple-value-bind (next next-opened next-closed)
                              (apply-weave-move counter remaining opened closed j)
                            (let ((block (weaving-count-state counter next
                                                              next-opened next-closed)))
                              (if (> r block)
                                  (decf r block)
                                  (progn
                                    (push j out)
                                    (setf remaining next
                                          opened next-opened
                                          closed next-closed)
                                    (return)))))))
      (coerce (nreverse out) 'vector))))

(defstruct (gate-state (:constructor make-gate-state ()))
  (table (let ((h (make-hash-table :test #'eql)))
           (setf (gethash 0 h) foundation-day)
           h))
  (min-known 0)
  (max-known 0))

(defun gate-at (state index)
  (multiple-value-bind (value presentp) (gethash index (gate-state-table state))
    (unless presentp
      (error "Vārti ar indeksu ~S vēl nav izveidoti." index))
    value))

(defun positive-gate-gap (n)
  (let* ((r (sauce foundation-day (+ foundation-day n)))
         (stream (ask-bowl r 1 seal-gate-gap))
         (chosen (choose-rank stream 922)))
    (+ 41 chosen)))

(defun negative-gate-gap (n)
  (let* ((r (sauce foundation-day (- foundation-day n)))
         (stream (ask-bowl r 1 seal-gate-gap))
         (chosen (choose-rank stream 922)))
    (+ 41 chosen)))

(defun ensure-gate-index (state k)
  (when (> k (gate-state-max-known state))
    (loop for n from (1+ (gate-state-max-known state)) to k
          do (setf (gethash n (gate-state-table state))
                   (+ (gate-at state (1- n)) (positive-gate-gap n)))
             (setf (gate-state-max-known state) n)))
  (when (< k (gate-state-min-known state))
    (loop for n from (1- (gate-state-min-known state)) downto k
          do (setf (gethash n (gate-state-table state))
                   (- (gate-at state (1+ n)) (negative-gate-gap (abs n))))
             (setf (gate-state-min-known state) n)))
  (gate-at state k))

(defun ensure-gates-cover (state low-day high-day)
  (unless (<= low-day high-day)
    (error "Vārtu pārklājuma dienu secība ir nederīga."))
  (loop while (> (gate-at state (gate-state-min-known state)) low-day)
        do (ensure-gate-index state (1- (gate-state-min-known state))))
  (loop while (< (gate-at state (gate-state-max-known state)) high-day)
        do (ensure-gate-index state (1+ (gate-state-max-known state))))
  state)

(defun gate-index-at-or-before (state day)
  (ensure-gates-cover state day day)
  (let ((lo (gate-state-min-known state))
        (hi (gate-state-max-known state)))
    (loop while (< lo hi)
          for mid = (+ lo (floor (+ (- hi lo) 1) 2))
          do (if (<= (gate-at state mid) day)
                 (setf lo mid)
                 (setf hi (1- mid))))
    lo))

(defun exact-gate-index (state day)
  (let ((i (gate-index-at-or-before state day)))
    (and (= (gate-at state i) day) i)))

(defstruct year number open-gate-index close-gate-index open-gate-day close-gate-day)

(defun year-length (state open-index close-index)
  (- (gate-at state close-index) (gate-at state open-index)))

(defun valid-year-pair-p (state open-index close-index)
  (and (>= (- close-index open-index) 6)
       (let ((length (year-length state open-index close-index)))
         (<= year-min-days length year-max-days))))

(defun make-year-from-indices (state number open-index close-index)
  (make-year :number number
             :open-gate-index open-index
             :close-gate-index close-index
             :open-gate-day (gate-at state open-index)
             :close-gate-day (gate-at state close-index)))

(defun year5000 (state calculation-day)
  (ensure-gates-cover state
                      (- calculation-day year-max-days)
                      (+ calculation-day year-max-days))
  (let ((candidates '()))
    (loop for i from (gate-state-min-known state) below (gate-state-max-known state)
          do (loop for j from (1+ i) to (gate-state-max-known state)
                   when (and (valid-year-pair-p state i j)
                             (< (gate-at state i) calculation-day)
                             (<= calculation-day (gate-at state j)))
                     do (push (vector i j) candidates)))
    (setf candidates
          (sort candidates
                (lambda (a b)
                  (let* ((ai (aref a 0)) (aj (aref a 1))
                         (bi (aref b 0)) (bj (aref b 1))
                         (al (year-length state ai aj))
                         (bl (year-length state bi bj)))
                    (or (< al bl)
                        (and (= al bl)
                             (< (gate-at state ai) (gate-at state bi))))))))
    (when (null candidates)
      (error "5000. gada kandidātu saime ir tukša."))
    (let* ((r (sauce calculation-day calculation-day))
           (stream (ask-bowl r 1 seal-year-5000))
           (rank (choose-rank stream (length candidates)))
           (chosen (nth (1- rank) candidates)))
      (make-year-from-indices state 5000 (aref chosen 0) (aref chosen 1)))))

(defun next-year (state calculation-day known-year)
  (let ((open-index (year-close-gate-index known-year))
        (candidates '()))
    (ensure-gates-cover state
                        (gate-at state (gate-state-min-known state))
                        (+ (gate-at state open-index) year-max-days))
    (loop for close-index from (1+ open-index)
          do (ensure-gate-index state close-index)
             (when (> (year-length state open-index close-index) year-max-days)
               (return))
             (when (valid-year-pair-p state open-index close-index)
               (push close-index candidates)))
    (setf candidates (nreverse candidates))
    (setf candidates
          (stable-sort candidates #'<
                       :key (lambda (j) (year-length state open-index j))))
    (when (null candidates)
      (error "Nākamā gada kandidātu saime ir tukša."))
    (let* ((r (sauce calculation-day (gate-at state open-index)))
           (stream (ask-bowl r 1 seal-next-year))
           (rank (choose-rank stream (length candidates)))
           (close-index (nth (1- rank) candidates)))
      (make-year-from-indices state (1+ (year-number known-year))
                              open-index close-index))))

(defun previous-year (state calculation-day known-year)
  (let ((close-index (year-open-gate-index known-year))
        (candidates '()))
    (ensure-gates-cover state
                        (- (gate-at state close-index) year-max-days)
                        (gate-at state (gate-state-max-known state)))
    (loop for open-index from (1- close-index) downto (gate-state-min-known state)
          do (when (> (year-length state open-index close-index) year-max-days)
               (return))
             (when (valid-year-pair-p state open-index close-index)
               (push open-index candidates)))
    (setf candidates (nreverse candidates))
    (setf candidates
          (stable-sort candidates #'<
                       :key (lambda (i) (year-length state i close-index))))
    (when (null candidates)
      (error "Iepriekšējā gada kandidātu saime ir tukša."))
    (let* ((r (sauce calculation-day (gate-at state close-index)))
           (stream (ask-bowl r 1 seal-previous-year))
           (rank (choose-rank stream (length candidates)))
           (open-index (nth (1- rank) candidates)))
      (make-year-from-indices state (1- (year-number known-year))
                              open-index close-index))))

(defun find-target-year (state calculation-day target-day)
  (let ((y (year5000 state calculation-day)))
    (loop while (> target-day (year-close-gate-day y))
          do (setf y (next-year state calculation-day y)))
    (loop while (<= target-day (year-open-gate-day y))
          do (setf y (previous-year state calculation-day y)))
    (unless (< (year-open-gate-day y) target-day (1+ (year-close-gate-day y)))
      (error "Mērķa diena neatrodas atrastā gada intervālā."))
    y))

(defun choose-cutlet-count (structure-sauce year)
  (let* ((gate-gaps (- (year-close-gate-index year) (year-open-gate-index year)))
         (candidates (loop for k from min-cutlets to max-cutlets
                           when (<= k gate-gaps) collect k)))
    (when (null candidates)
      (error "Kotlešu skaita kandidātu saime ir tukša."))
    (let* ((stream (ask-bowl structure-sauce 2 seal-cutlet-count))
           (rank (choose-rank stream (length candidates))))
      (nth (1- rank) candidates))))

(defun choose-cutlet-partition (state calculation-day structure-sauce year cutlet-count)
  (let* ((gaps (- (year-close-gate-index year) (year-open-gate-index year)))
         (gate-index (exact-gate-index state calculation-day))
         (required (and gate-index
                        (< (year-open-gate-index year) gate-index)
                        (< gate-index (year-close-gate-index year))
                        (- gate-index (year-open-gate-index year))))
         (counter (make-cutlet-partition-counter gaps cutlet-count required))
         (count (cutlet-partition-count counter))
         (stream (ask-bowl structure-sauce 2 seal-cutlet-partition))
         (rank (choose-rank stream count)))
    (cutlet-partition-unrank1 counter rank)))

(defun choose-cutlet-name-indices (structure-sauce cutlet-count)
  (let* ((n (falling-factorial 17 cutlet-count))
         (stream (ask-bowl structure-sauce 5 seal-cutlet-names))
         (rank (choose-rank stream n)))
    (unrank-distinct-indices 17 cutlet-count rank)))

(defstruct cutlet name-index open-gate-index close-gate-index first-day last-day)

(defun materialize-cutlets (state year partition name-indices)
  (let ((cursor (year-open-gate-index year))
        (out '()))
    (loop for k from 0 below (length partition)
          for close = (+ cursor (aref partition k))
          do (push (make-cutlet :name-index (aref name-indices k)
                                :open-gate-index cursor
                                :close-gate-index close
                                :first-day (1+ (gate-at state cursor))
                                :last-day (gate-at state close))
                   out)
             (setf cursor close))
    (coerce (nreverse out) 'vector)))

(defun choose-month-count (structure-sauce year)
  (let* ((length (- (year-close-gate-day year) (year-open-gate-day year)))
         (min-months (ceil-div length 123))
         (max-months (min 47 (floor length 4))))
    (unless (<= 3 min-months max-months 47)
      (error "Mēnešu skaita robežu invariants ir pārkāpts."))
    (let* ((count (1+ (- max-months min-months)))
           (stream (ask-bowl structure-sauce 3 seal-month-count))
           (rank (choose-rank stream count)))
      (+ min-months (1- rank)))))

(defun choose-month-lengths (structure-sauce year month-count)
  (let* ((length (- (year-close-gate-day year) (year-open-gate-day year)))
         (counter (make-bounded-composition-counter length month-count 4 123))
         (count (bounded-composition-count counter))
         (stream (ask-bowl structure-sauce 3 seal-month-lengths))
         (rank (choose-rank stream count)))
    (bounded-composition-unrank1 counter rank)))

(defun choose-month-weaving (structure-sauce month-lengths)
  (let* ((counter (make-weaving-counter month-lengths))
         (count (weaving-count counter))
         (stream (ask-bowl structure-sauce 4 seal-month-weaving))
         (rank (choose-rank stream count)))
    (weaving-unrank1 counter rank)))

(defun choose-month-name-indices (structure-sauce month-count)
  (let* ((n (falling-factorial 47 month-count))
         (stream (ask-bowl structure-sauce 5 seal-month-names))
         (rank (choose-rank stream n)))
    (unrank-distinct-indices 47 month-count rank)))

(defstruct year-structure
  cutlet-count cutlet-partition cutlet-name-indices cutlets
  month-count month-lengths month-weaving month-name-indices)

(defun build-year-structure (state calculation-day year)
  (let* ((first-day (1+ (year-open-gate-day year)))
         (r (sauce calculation-day first-day))
         (cutlet-count (choose-cutlet-count r year))
         (partition (choose-cutlet-partition state calculation-day r year cutlet-count))
         (cutlet-names (choose-cutlet-name-indices r cutlet-count))
         (cutlets (materialize-cutlets state year partition cutlet-names))
         (month-count (choose-month-count r year))
         (month-lengths (choose-month-lengths r year month-count))
         (weaving (choose-month-weaving r month-lengths))
         (month-names (choose-month-name-indices r month-count)))
    (make-year-structure
     :cutlet-count cutlet-count
     :cutlet-partition partition
     :cutlet-name-indices cutlet-names
     :cutlets cutlets
     :month-count month-count
     :month-lengths month-lengths
     :month-weaving weaving
     :month-name-indices month-names)))

(defun calendar-date-indices (calculation-day target-day)
  (unless (and (integerp calculation-day) (integerp target-day))
    (error "Abām dienām jābūt veseliem skaitļiem."))
  (let* ((state (make-gate-state))
         (year (find-target-year state calculation-day target-day))
         (structure (build-year-structure state calculation-day year))
         (cutlets (year-structure-cutlets structure))
         (chosen-cutlet nil))
    (loop for c across cutlets
          when (<= (cutlet-first-day c) target-day (cutlet-last-day c))
            do (setf chosen-cutlet c) (return))
    (unless chosen-cutlet
      (error "Mērķa dienai nav atrasta kotlete."))
    (let* ((day-in-cutlet (1+ (- target-day (cutlet-first-day chosen-cutlet))))
           (offset (- target-day (1+ (year-open-gate-day year))))
           (month-id (aref (year-structure-month-weaving structure) offset))
           (month-index (aref (year-structure-month-name-indices structure)
                              (1- month-id)))
           (day-in-month
             (loop for p from 0 to offset
                   count (= (aref (year-structure-month-weaving structure) p)
                            month-id))))
      (list (year-number year)
            (cutlet-name-index chosen-cutlet)
            day-in-cutlet
            month-index
            day-in-month))))

(defun calendar-date (calculation-day target-day)
  (destructuring-bind (year-number cutlet-index day-in-cutlet month-index day-in-month)
      (calendar-date-indices calculation-day target-day)
    (list year-number
          (pastafari.lv:cutlet-name-by-index cutlet-index)
          day-in-cutlet
          (pastafari.lv:month-name-by-index month-index)
          day-in-month)))
