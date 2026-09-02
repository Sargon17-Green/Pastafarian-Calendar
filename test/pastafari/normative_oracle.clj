(ns pastafari.normative-oracle
  (:require [pastafari.source-language-catalog :as catalog]))

(def tablets-day -278522N)
(def foundation-day -15055671N)
(def m (dec (reduce *' 1N (repeat 127 2N))))
(def gate-gap-min 42N)
(def gate-gap-max 963N)
(def year-min-days 252N)
(def year-max-days 5778N)
(def min-cutlets 6)
(def max-cutlets 17)
(def min-months 3)
(def max-months 47)
(def min-month-days 4N)
(def max-month-days 123N)

(def seal-gate-gap 1N)
(def seal-year-5000 10N)
(def seal-next-year 11N)
(def seal-previous-year 12N)
(def seal-cutlet-count 20N)
(def seal-cutlet-partition 21N)
(def seal-cutlet-names 22N)
(def seal-month-count 30N)
(def seal-month-lengths 31N)
(def seal-month-weaving 32N)
(def seal-month-names 33N)

(def wheat 0)
(def barley 1)
(def salt 2)
(def bitter 3)
(def red 4)

(defn abs-int [x]
  (if (neg? x) (- x) x))

(defn regular-mod [x d]
  (when-not (and (integer? d) (pos? d))
    (throw (ex-info "De modulus moet een positief geheel getal zijn." {:code :invalid-modulus :value d})))
  (mod x d))

(defn save [x]
  (inc (regular-mod (dec x) m)))

(defn square [x]
  (*' x x))

(defn ceil-div [a b]
  (when-not (and (integer? a) (not (neg? a)) (integer? b) (pos? b))
    (throw (ex-info "De argumenten voor de plafonddeling zijn ongeldig." {:code :invalid-ceil-div :a a :b b})))
  (quot (+ a (dec b)) b))

(defn wrap1 [position size]
  (when-not (pos? size)
    (throw (ex-info "De ringgrootte moet positief zijn." {:code :invalid-ring-size :size size})))
  (inc (regular-mod (dec position) size)))

(defn day-count [day]
  (cond
    (= day foundation-day) 1N
    (> day foundation-day) (inc (*' 2N (- day foundation-day)))
    :else (*' 2N (- foundation-day day))))

(defn work-counts [calculation-day target-day]
  (let [action (day-count calculation-day)
        target (day-count target-day)
        distance (inc (abs-int (- target-day calculation-day)))
        connection (+ action target)
        direction (cond
                    (< target-day calculation-day) 1N
                    (= target-day calculation-day) 2N
                    :else 3N)]
    {:action action
     :target target
     :distance distance
     :connection connection
     :direction direction}))

(defn stone-get [stone kind]
  (nth stone kind))

(defn build-stones []
  (loop [i 2
         table [[17N 29N 43N 71N 101N]]]
    (if (> i 46)
      table
      (let [old (peek table)
            next-wheat (save (+ (square (stone-get old wheat)) (*' 3N (stone-get old barley)) i))
            next-barley (save (+ (square (stone-get old barley)) (*' 5N (stone-get old salt)) (stone-get old wheat)))
            next-salt (save (+ (square (stone-get old salt)) (*' 7N (stone-get old bitter)) (stone-get old barley)))
            next-bitter (save (+ (square (stone-get old bitter)) (*' 11N (stone-get old red)) (stone-get old salt)))
            next-red (save (+ (square (stone-get old red)) (*' 13N (stone-get old wheat)) (stone-get old bitter)))]
        (recur (inc i) (conj table [next-wheat next-barley next-salt next-bitter next-red]))))))

(def stones (build-stones))

(def hidden-coeff
  [[3N 4N 6N 8N]
   [5N 7N 10N 12N]
   [7N 10N 14N 16N]
   [9N 13N 18N 20N]
   [11N 16N 22N 24N]
   [13N 19N 26N 28N]
   [15N 22N 30N 32N]])

(def hidden-grind-stone [wheat barley salt bitter red wheat barley])

(defn build-hidden-drops [counts]
  (mapv
   (fn [k0]
     (let [k (inc k0)
           [a b c d] (nth hidden-coeff k0)
           stone (nth stones k0)
           seed (+ (:action counts)
                   (*' a (:target counts))
                   (*' b (:distance counts))
                   (*' c (:connection counts))
                   (*' d (:direction counts))
                   (reduce +' 0N stone))]
       (loop [grind 1
              x (save seed)]
         (if (> grind 7)
           x
           (let [old-x x
                 kind (nth hidden-grind-stone (dec grind))]
             (recur (inc grind)
                    (save (+ (square old-x)
                             (*' 3N old-x)
                             (stone-get stone kind)
                             grind))))))))
   (range 7)))

(def visible-grinds
  [[3N 5N 7N 11N wheat]
   [5N 7N 11N 13N barley]
   [7N 11N 13N 17N salt]
   [11N 13N 17N 19N bitter]
   [13N 17N 19N 23N red]
   [17N 19N 23N 29N wheat]
   [19N 23N 29N 31N barley]
   [23N 29N 31N 37N salt]
   [29N 31N 37N 41N bitter]
   [31N 37N 41N 43N red]
   [37N 41N 43N 47N wheat]])

(defn seed-drop-timeline [hidden]
  (reduce (fn [timeline k]
            (assoc timeline (- 1 k) (nth hidden (dec k))))
          {}
          (range 1 8)))

(defn build-visible-drops [counts hidden]
  (loop [i 1
         timeline (seed-drop-timeline hidden)]
    (if (> i 46)
      (mapv timeline (range 1 47))
      (let [prev1 (get timeline (dec i))
            prev3 (get timeline (- i 3))
            prev7 (get timeline (- i 7))
            stone (nth stones (dec i))
            seed (save (+ (*' (stone-get stone wheat) (:action counts))
                          (*' (stone-get stone barley) (:target counts))
                          (*' (stone-get stone salt) (:distance counts))
                          (*' (stone-get stone bitter) (:connection counts))
                          (*' (stone-get stone red) (:direction counts))
                          prev1
                          (*' 3N prev3)
                          (*' 5N prev7)
                          i))
            value (reduce
                   (fn [x [a b c d kind]]
                     (save (+ (square x)
                              (*' a x)
                              (*' b prev1)
                              (*' c prev3)
                              (*' d prev7)
                              (stone-get stone kind))))
                   seed
                   visible-grinds)]
        (recur (inc i) (assoc timeline i value))))))

(defn factorial [n]
  (reduce *' 1N (range 2 (inc n))))

(defn remove-at [v idx]
  (vec (concat (subvec v 0 idx) (subvec v (inc idx)))))

(defn permutation-unrank1 [rank1 items-ascending]
  (let [n (count items-ascending)
        total (factorial n)]
    (when-not (<= 1N rank1 total)
      (throw (ex-info "De permutatierang ligt buiten het geldige bereik." {:code :invalid-permutation-rank :rank rank1 :total total})))
    (loop [rank0 (dec rank1)
           remaining (vec items-ascending)
           result []]
      (if (empty? remaining)
        result
        (let [block (factorial (dec (count remaining)))
              q (quot rank0 block)
              idx (int q)
              chosen (nth remaining idx)]
          (recur (regular-mod rank0 block)
                 (remove-at remaining idx)
                 (conj result chosen)))))))

(defn bowl-order-from-number [order-number]
  (permutation-unrank1 order-number [1 2 3 4 5 6]))

(defn bowl-order-from-drop [drop-value]
  (bowl-order-from-number (inc (regular-mod (dec drop-value) 720N))))

(def bowl-prime [17N 19N 23N 29N 31N 37N])
(def bowl-stir-stone-by-position [wheat barley salt bitter red wheat])

(defn bowl-get [bowls bowl-id]
  (nth bowls (dec bowl-id)))

(defn initial-bowls [counts]
  (mapv
   (fn [idx0]
     (let [bowl-id (inc idx0)
           prime (nth bowl-prime idx0)
           s (+ (:action counts)
                (*' (:target counts) bowl-id)
                (:distance counts)
                (:connection counts)
                (:direction counts)
                (square prime))]
       (save (+ (square s) bowl-id))))
   (range 6)))

(defn apply-visible-drops-to-bowls [bowls visible]
  (loop [i 1
         current bowls
         order-at-drop46 nil]
    (if (> i 46)
      {:bowls current :order-at-drop46 order-at-drop46}
      (let [drop (nth visible (dec i))
            order (bowl-order-from-drop drop)
            old current
            first-bowl (nth order 0)
            second-bowl (nth order 1)
            third-bowl (nth order 2)
            stone (nth stones (dec i))
            pours [(save (+ (square drop) (*' (stone-get stone wheat) (bowl-get old first-bowl)) (*' 3N i)))
                   (save (+ (square drop) (*' (stone-get stone barley) (bowl-get old second-bowl)) (*' 5N i)))
                   (save (+ (square drop) (*' (stone-get stone salt) (bowl-get old third-bowl)) (*' 7N i)))
                   0N 0N 0N]
            next-bowls
            (reduce
             (fn [pending position]
               (let [idx0 (dec position)
                     bowl-id (nth order idx0)
                     prev-id (nth order (dec (wrap1 (dec position) 6)))
                     next-id (nth order (dec (wrap1 (inc position) 6)))
                     kind (nth bowl-stir-stone-by-position idx0)
                     s (+ (bowl-get old bowl-id)
                          (*' 2N (bowl-get old prev-id))
                          (*' 3N (bowl-get old next-id))
                          (nth pours idx0)
                          drop
                          (stone-get stone kind))
                     value (save (+ (square s)
                                    (*' 5N (bowl-get old prev-id) (bowl-get old next-id))
                                    (*' i position)))]
                 (assoc pending (dec bowl-id) value)))
             (vec (repeat 6 0N))
             (range 1 7))]
        (recur (inc i)
               next-bowls
               (if (= i 46) order order-at-drop46))))))

(defn post-stir12 [bowls]
  (loop [stir 1
         current bowls]
    (if (> stir 12)
      current
      (let [old current
            saved-bowl-sum (save (+ (reduce +' 0N old) (*' 149N stir)))
            order-number (inc (regular-mod (dec saved-bowl-sum) 720N))
            order (bowl-order-from-number order-number)
            pending
            (reduce
             (fn [next-bowls position]
               (let [idx0 (dec position)
                     bowl-id (nth order idx0)
                     prev-id (nth order (dec (wrap1 (dec position) 6)))
                     next-id (nth order (dec (wrap1 (inc position) 6)))
                     s (+ (bowl-get old bowl-id)
                          (*' 3N (bowl-get old prev-id))
                          (*' 5N (bowl-get old next-id))
                          saved-bowl-sum
                          stir
                          (square position))
                     value (save (+ (square s)
                                    (*' 7N (bowl-get old prev-id) (bowl-get old next-id))))]
                 (assoc next-bowls (dec bowl-id) value)))
             (vec (repeat 6 0N))
             (range 1 7))]
        (recur (inc stir) pending)))))

(defn sauce [calculation-day target-day]
  (let [counts (work-counts calculation-day target-day)
        hidden (build-hidden-drops counts)
        visible (build-visible-drops counts hidden)
        bowls (initial-bowls counts)
        after-drops (apply-visible-drops-to-bowls bowls visible)]
    {:bowls (post-stir12 (:bowls after-drops))
     :order-at-drop46 (:order-at-drop46 after-drops)}))

(defn next-bowl-in-drop46-order [sauce-result queried-bowl-id]
  (let [order (:order-at-drop46 sauce-result)
        pos (.indexOf order queried-bowl-id)]
    (when (neg? pos)
      (throw (ex-info "De gevraagde kom ontbreekt in de vergrendelde volgorde." {:code :missing-bowl :bowl queried-bowl-id})))
    (nth order (mod (inc pos) 6))))

(defn ask-bowl [sauce-result queried-bowl-id seal]
  (let [next-id (next-bowl-in-drop46-order sauce-result queried-bowl-id)
        first (save (+ (square (+ (bowl-get (:bowls sauce-result) queried-bowl-id) seal 181N))
                       (*' 179N (bowl-get (:bowls sauce-result) next-id))
                       seal))
        direction-number (save (+ (square (+ first seal 1N 193N))
                                  (*' 193N first)
                                  (*' 197N (bowl-get (:bowls sauce-result) 6))))
        direction-step (if (= 1N (regular-mod direction-number 2N)) 1N -1N)]
    {:first first :direction-step direction-step}))

(defn answer-at [stream k]
  (inc (regular-mod (+ (dec (:first stream)) (*' (:direction-step stream) k)) m)))

(defn choose-rank-short [stream n]
  (when-not (<= 1N n m)
    (throw (ex-info "De korte selectie vereist een grootte tussen één en M." {:code :invalid-short-size :size n})))
  (let [acceptance-limit (*' (quot m n) n)]
    (loop [k 0N]
      (let [x (answer-at stream k)]
        (if (<= x acceptance-limit)
          (inc (regular-mod (dec x) n))
          (recur (inc k)))))))

(defn smallest-power-count [base n]
  (loop [k 1
         space base]
    (if (>= space n)
      [k space]
      (recur (inc k) (*' space base)))))

(defn choose-rank-wide [stream n]
  (when-not (> n m)
    (throw (ex-info "De brede selectie vereist een grootte groter dan M." {:code :invalid-wide-size :size n})))
  (let [[k space] (smallest-power-count m n)
        wide0
        (loop [j 0
               wide 1N
               weight 1N]
          (if (= j k)
            wide
            (recur (inc j)
                   (+ wide (*' (dec (answer-at stream j)) weight))
                   (*' weight m))))
        acceptance-limit (*' (quot space n) n)]
    (loop [wide wide0]
      (if (<= wide acceptance-limit)
        (inc (regular-mod (dec wide) n))
        (recur (inc (regular-mod (+ (dec wide) (:direction-step stream)) space)))))))

(defn choose-rank [stream n]
  (when-not (and (integer? n) (pos? n))
    (throw (ex-info "De geordende familie moet minstens één element bevatten." {:code :empty-family :size n})))
  (if (<= n m)
    (choose-rank-short stream n)
    (choose-rank-wide stream n)))

(defn falling-factorial [n k]
  (when-not (<= 0 k n)
    (throw (ex-info "De partiële permutatiegrootte is ongeldig." {:code :invalid-falling-factorial :n n :k k})))
  (reduce *' 1N (map #(- n %) (range k))))

(defn unrank-distinct-indices [n k rank1]
  (let [total (falling-factorial n k)]
    (when-not (<= 1N rank1 total)
      (throw (ex-info "De naamrang ligt buiten het geldige bereik." {:code :invalid-name-rank :rank rank1 :total total})))
    (loop [position 1
           remaining (vec (range 1 (inc n)))
           r rank1
           out []]
      (if (> position k)
        out
        (let [suffix-length (- k position)
              block (falling-factorial (dec (count remaining)) suffix-length)
              chosen
              (loop [idx 0
                     local-r r]
                (if (>= idx (count remaining))
                  (throw (ex-info "De naamrang kon niet worden geopend." {:code :name-unrank-failed :rank rank1}))
                  (if (> local-r block)
                    (recur (inc idx) (- local-r block))
                    {:idx idx :r local-r :value (nth remaining idx)})))]
          (recur (inc position)
                 (remove-at remaining (:idx chosen))
                 (:r chosen)
                 (conj out (:value chosen))))))))

(defn bounded-composition-family [total slots lo hi]
  (let [memo (atom {})]
    (letfn [(count-suffix [rem k]
              (cond
                (= k 0) (if (= rem 0) 1N 0N)
                (< rem (*' k lo)) 0N
                (> rem (*' k hi)) 0N
                :else
                (if-let [hit (find @memo [rem k])]
                  (val hit)
                  (let [value (reduce +' 0N (map #(count-suffix (- rem %) (dec k)) (range lo (inc hi))))]
                    (swap! memo assoc [rem k] value)
                    value))))
            (unrank1 [rank1]
              (let [all (count-suffix total slots)]
                (when-not (<= 1N rank1 all)
                  (throw (ex-info "De compositierang ligt buiten het geldige bereik." {:code :invalid-composition-rank :rank rank1 :total all})))
                (loop [position 1
                       rem total
                       r rank1
                       out []]
                  (if (> position slots)
                    out
                    (let [choice
                          (loop [x lo
                                 local-r r]
                            (if (> x hi)
                              (throw (ex-info "De compositierang kon niet worden geopend." {:code :composition-unrank-failed :rank rank1}))
                              (let [block (count-suffix (- rem x) (- slots position))]
                                (if (> local-r block)
                                  (recur (inc x) (- local-r block))
                                  {:x x :r local-r}))))]
                      (recur (inc position)
                             (- rem (:x choice))
                             (:r choice)
                             (conj out (:x choice))))))))]
      {:count #(count-suffix total slots)
       :unrank1 unrank1})))

(defn new-gate-state []
  (atom {:gates {0 foundation-day} :min-index 0 :max-index 0}))

(defn positive-gate-gap [n]
  (let [result (sauce foundation-day (+ foundation-day n))
        stream (ask-bowl result 1 seal-gate-gap)
        chosen (choose-rank stream 922N)]
    (+ 41N chosen)))

(defn negative-gate-gap [n]
  (let [result (sauce foundation-day (- foundation-day n))
        stream (ask-bowl result 1 seal-gate-gap)
        chosen (choose-rank stream 922N)]
    (+ 41N chosen)))

(defn ensure-gate-index! [state k]
  (when (> k (:max-index @state))
    (loop [n (inc (:max-index @state))]
      (when (<= n k)
        (let [previous (get-in @state [:gates (dec n)])
              value (+ previous (positive-gate-gap n))]
          (swap! state assoc-in [:gates n] value)
          (swap! state assoc :max-index n)
          (recur (inc n))))))
  (when (< k (:min-index @state))
    (loop [n (dec (:min-index @state))]
      (when (>= n k)
        (let [next-day (get-in @state [:gates (inc n)])
              value (- next-day (negative-gate-gap (abs-int n)))]
          (swap! state assoc-in [:gates n] value)
          (swap! state assoc :min-index n)
          (recur (dec n))))))
  (get-in @state [:gates k]))

(defn ensure-gates-cover! [state low-day high-day]
  (when (> low-day high-day)
    (throw (ex-info "Het poortbereik is omgekeerd." {:code :invalid-gate-range :low low-day :high high-day})))
  (loop []
    (let [{:keys [min-index]} @state
          day (get-in @state [:gates min-index])]
      (when (> day low-day)
        (ensure-gate-index! state (dec min-index))
        (recur))))
  (loop []
    (let [{:keys [max-index]} @state
          day (get-in @state [:gates max-index])]
      (when (< day high-day)
        (ensure-gate-index! state (inc max-index))
        (recur))))
  state)

(defn gate-index-at-or-before! [state day]
  (ensure-gates-cover! state day day)
  (loop [lo (:min-index @state)
         hi (:max-index @state)]
    (if (= lo hi)
      lo
      (let [mid (+ lo (quot (inc (- hi lo)) 2))]
        (if (<= (get-in @state [:gates mid]) day)
          (recur mid hi)
          (recur lo (dec mid)))))))

(defn exact-gate-index! [state day]
  (let [idx (gate-index-at-or-before! state day)]
    (when (= (get-in @state [:gates idx]) day)
      idx)))

(defn year-length [state open-index close-index]
  (- (get-in @state [:gates close-index])
     (get-in @state [:gates open-index])))

(defn valid-year-pair? [state open-index close-index]
  (and (>= (- close-index open-index) 6)
       (let [length (year-length state open-index close-index)]
         (<= year-min-days length year-max-days))))

(defn stable-sort-by [key-fn coll]
  (->> coll
       (map-indexed vector)
       (sort-by (fn [[idx value]] [(key-fn value) idx]))
       (mapv second)))

(defn make-year [state number open-index close-index]
  {:number number
   :open-gate-index open-index
   :close-gate-index close-index
   :open-gate-day (get-in @state [:gates open-index])
   :close-gate-day (get-in @state [:gates close-index])})

(defn year5000 [state calculation-day]
  (ensure-gates-cover! state (- calculation-day year-max-days) (+ calculation-day year-max-days))
  (let [{:keys [min-index max-index]} @state
        candidates
        (vec
         (for [i (range min-index max-index)
               j (range (inc i) (inc max-index))
               :when (valid-year-pair? state i j)
               :let [open-day (get-in @state [:gates i])
                     close-day (get-in @state [:gates j])]
               :when (and (< open-day calculation-day) (<= calculation-day close-day))]
           {:open-index i :close-index j :open-day open-day :length (- close-day open-day)}))
        ordered (vec (sort-by (juxt :length :open-day) candidates))
        result (sauce calculation-day calculation-day)
        stream (ask-bowl result 1 seal-year-5000)
        rank (choose-rank stream (count ordered))
        chosen (nth ordered (dec (int rank)))]
    (make-year state 5000 (:open-index chosen) (:close-index chosen))))

(defn next-year [state calculation-day known-year]
  (let [open-index (:close-gate-index known-year)
        open-day (ensure-gate-index! state open-index)]
    (ensure-gates-cover! state open-day (+ open-day year-max-days))
    (let [candidates
          (loop [close-index (inc open-index)
                 out []]
            (let [close-day (ensure-gate-index! state close-index)
                  length (- close-day open-day)]
              (if (> length year-max-days)
                out
                (recur (inc close-index)
                       (if (valid-year-pair? state open-index close-index)
                         (conj out close-index)
                         out)))))
          ordered (stable-sort-by #(year-length state open-index %) candidates)
          result (sauce calculation-day open-day)
          stream (ask-bowl result 1 seal-next-year)
          rank (choose-rank stream (count ordered))
          close-index (nth ordered (dec (int rank)))]
      (make-year state (inc (:number known-year)) open-index close-index))))

(defn previous-year [state calculation-day known-year]
  (let [close-index (:open-gate-index known-year)
        close-day (ensure-gate-index! state close-index)]
    (ensure-gates-cover! state (- close-day year-max-days) close-day)
    (let [candidates
          (loop [open-index (dec close-index)
                 out []]
            (let [open-day (ensure-gate-index! state open-index)
                  length (- close-day open-day)]
              (if (> length year-max-days)
                out
                (recur (dec open-index)
                       (if (valid-year-pair? state open-index close-index)
                         (conj out open-index)
                         out)))))
          ordered (stable-sort-by #(year-length state % close-index) candidates)
          result (sauce calculation-day close-day)
          stream (ask-bowl result 1 seal-previous-year)
          rank (choose-rank stream (count ordered))
          open-index (nth ordered (dec (int rank)))]
      (make-year state (dec (:number known-year)) open-index close-index))))

(defn find-target-year [state calculation-day target-day]
  (loop [year (year5000 state calculation-day)]
    (cond
      (> target-day (:close-gate-day year)) (recur (next-year state calculation-day year))
      (<= target-day (:open-gate-day year)) (recur (previous-year state calculation-day year))
      :else year)))

(defn choose-cutlet-count [structure-sauce year]
  (let [gate-gaps (- (:close-gate-index year) (:open-gate-index year))
        candidates (vec (filter #(<= % gate-gaps) (range min-cutlets (inc max-cutlets))))
        stream (ask-bowl structure-sauce 2 seal-cutlet-count)
        rank (choose-rank stream (count candidates))]
    (nth candidates (dec (int rank)))))

(defn cutlet-partition-family [gate-gaps cutlet-count required-boundary]
  (let [memo (atom {})]
    (letfn [(count-state [rem slots cumulative hit-boundary]
              (cond
                (= slots 0) (if (and (= rem 0) (or (nil? required-boundary) hit-boundary)) 1N 0N)
                (< rem slots) 0N
                :else
                (let [key [rem slots cumulative hit-boundary]]
                  (if-let [hit (find @memo key)]
                    (val hit)
                    (let [max-x (- rem (dec slots))
                          total
                          (reduce
                           +' 0N
                           (for [x (range 1 (inc max-x))
                                 :let [next-cumulative (+ cumulative x)
                                       next-hit (or hit-boundary
                                                    (and required-boundary (= next-cumulative required-boundary)))]
                                 :when (or (nil? required-boundary)
                                           hit-boundary
                                           (<= next-cumulative required-boundary))]
                             (count-state (- rem x) (dec slots) next-cumulative next-hit)))]
                      (swap! memo assoc key total)
                      total)))))
            (unrank1 [rank1]
              (let [all (count-state gate-gaps cutlet-count 0 false)]
                (when-not (<= 1N rank1 all)
                  (throw (ex-info "De koteletverdelingsrang ligt buiten het geldige bereik." {:code :invalid-cutlet-partition-rank :rank rank1 :total all})))
                (loop [rem gate-gaps
                       slots cutlet-count
                       cumulative 0
                       hit false
                       r rank1
                       out []]
                  (if (= slots 0)
                    out
                    (let [max-x (- rem (dec slots))
                          choice
                          (loop [x 1
                                 local-r r]
                            (if (> x max-x)
                              (throw (ex-info "De koteletverdelingsrang kon niet worden geopend." {:code :cutlet-partition-unrank-failed :rank rank1}))
                              (let [next-cumulative (+ cumulative x)
                                    next-hit (or hit
                                                 (and required-boundary (= next-cumulative required-boundary)))
                                    allowed (or (nil? required-boundary)
                                                hit
                                                (<= next-cumulative required-boundary))
                                    block (if allowed
                                            (count-state (- rem x) (dec slots) next-cumulative next-hit)
                                            0N)]
                                (if (> local-r block)
                                  (recur (inc x) (- local-r block))
                                  {:x x :r local-r :cumulative next-cumulative :hit next-hit}))))]
                      (recur (- rem (:x choice))
                             (dec slots)
                             (:cumulative choice)
                             (:hit choice)
                             (:r choice)
                             (conj out (:x choice))))))))]
      {:count #(count-state gate-gaps cutlet-count 0 false)
       :unrank1 unrank1})))

(defn choose-cutlet-partition [state calculation-day structure-sauce year cutlet-count]
  (let [gate-gaps (- (:close-gate-index year) (:open-gate-index year))
        gate-index (exact-gate-index! state calculation-day)
        required (when (and gate-index
                            (< (:open-gate-index year) gate-index (:close-gate-index year)))
                   (- gate-index (:open-gate-index year)))
        family (cutlet-partition-family gate-gaps cutlet-count required)
        stream (ask-bowl structure-sauce 2 seal-cutlet-partition)
        rank (choose-rank stream ((:count family)))]
    ((:unrank1 family) rank)))

(defn choose-cutlet-names [structure-sauce cutlet-count]
  (let [n (falling-factorial 17 cutlet-count)
        stream (ask-bowl structure-sauce 5 seal-cutlet-names)
        rank (choose-rank stream n)]
    (unrank-distinct-indices 17 cutlet-count rank)))

(defn materialize-cutlets [state year partition name-indices]
  (loop [parts partition
         names name-indices
         cursor (:open-gate-index year)
         out []]
    (if (empty? parts)
      out
      (let [close-index (+ cursor (first parts))]
        (recur (rest parts)
               (rest names)
               close-index
               (conj out {:name-index (first names)
                          :open-gate-index cursor
                          :close-gate-index close-index
                          :first-day (inc (get-in @state [:gates cursor]))
                          :last-day (get-in @state [:gates close-index])}))))))

(defn choose-month-count [structure-sauce year]
  (let [length (- (:close-gate-day year) (:open-gate-day year))
        low (ceil-div length max-month-days)
        high (min max-months (quot length min-month-days))
        candidates (vec (range (int low) (inc (int high))))
        stream (ask-bowl structure-sauce 3 seal-month-count)
        rank (choose-rank stream (count candidates))]
    (nth candidates (dec (int rank)))))

(defn choose-month-lengths [structure-sauce year month-count]
  (let [length (- (:close-gate-day year) (:open-gate-day year))
        family (bounded-composition-family length month-count min-month-days max-month-days)
        stream (ask-bowl structure-sauce 3 seal-month-lengths)
        rank (choose-rank stream ((:count family)))]
    ((:unrank1 family) rank)))

(defn legal-weave-move? [state month-id lengths]
  (let [idx (dec month-id)
        remaining (nth (:remaining state) idx)]
    (and (pos? remaining)
         (let [already-opened (< remaining (nth lengths idx))
               will-close (= remaining 1N)]
           (and (or already-opened (= month-id (inc (:opened-up-to state))))
                (or (not will-close) (= month-id (inc (:closed-up-to state)))))))))

(defn apply-weave-move [state month-id lengths]
  (let [idx (dec month-id)
        before (nth (:remaining state) idx)
        first-open (= before (nth lengths idx))
        after (dec before)
        remaining (assoc (:remaining state) idx after)]
    {:remaining remaining
     :opened-up-to (if first-open month-id (:opened-up-to state))
     :closed-up-to (if (zero? after) month-id (:closed-up-to state))}))

(defn weaving-family [lengths]
  (let [lengths (mapv bigint lengths)
        month-count (count lengths)
        memo (atom {})
        initial {:remaining lengths :opened-up-to 0 :closed-up-to 0}]
    (letfn [(count-weavings [state]
              (if (every? zero? (:remaining state))
                1N
                (if-let [hit (find @memo state)]
                  (val hit)
                  (let [total
                        (reduce
                         +' 0N
                         (for [month-id (range 1 (inc month-count))
                               :when (legal-weave-move? state month-id lengths)]
                           (count-weavings (apply-weave-move state month-id lengths))))]
                    (swap! memo assoc state total)
                    total))))
            (unrank1 [rank1]
              (let [all (count-weavings initial)
                    total-days (reduce + 0 (map int lengths))]
                (when-not (<= 1N rank1 all)
                  (throw (ex-info "De weefrang ligt buiten het geldige bereik." {:code :invalid-weaving-rank :rank rank1 :total all})))
                (loop [state initial
                       r rank1
                       out []]
                  (if (= (count out) total-days)
                    out
                    (let [choice
                          (loop [month-id 1
                                 local-r r]
                            (if (> month-id month-count)
                              (throw (ex-info "De weefrang kon niet worden geopend." {:code :weaving-unrank-failed :rank rank1}))
                              (if-not (legal-weave-move? state month-id lengths)
                                (recur (inc month-id) local-r)
                                (let [next-state (apply-weave-move state month-id lengths)
                                      block (count-weavings next-state)]
                                  (if (> local-r block)
                                    (recur (inc month-id) (- local-r block))
                                    {:month-id month-id :r local-r :state next-state})))))]
                      (recur (:state choice) (:r choice) (conj out (:month-id choice))))))))]
      {:count #(count-weavings initial)
       :unrank1 unrank1})))

(defn choose-month-weaving [structure-sauce month-lengths]
  (let [family (weaving-family month-lengths)
        stream (ask-bowl structure-sauce 4 seal-month-weaving)
        rank (choose-rank stream ((:count family)))]
    ((:unrank1 family) rank)))

(defn choose-month-names [structure-sauce month-count]
  (let [n (falling-factorial 47 month-count)
        stream (ask-bowl structure-sauce 5 seal-month-names)
        rank (choose-rank stream n)]
    (unrank-distinct-indices 47 month-count rank)))

(defn build-year-structure [state calculation-day year]
  (let [first-day (inc (:open-gate-day year))
        result (sauce calculation-day first-day)
        cutlet-count (choose-cutlet-count result year)
        cutlet-partition (choose-cutlet-partition state calculation-day result year cutlet-count)
        cutlet-names (choose-cutlet-names result cutlet-count)
        cutlets (materialize-cutlets state year cutlet-partition cutlet-names)
        month-count (choose-month-count result year)
        month-lengths (choose-month-lengths result year month-count)
        month-weaving (choose-month-weaving result month-lengths)
        month-names (choose-month-names result month-count)]
    {:cutlet-count cutlet-count
     :cutlet-partition cutlet-partition
     :cutlet-names cutlet-names
     :cutlets cutlets
     :month-count month-count
     :month-lengths month-lengths
     :month-weaving month-weaving
     :month-names month-names}))

(defn calendar-date-canonical [calculation-day target-day]
  (let [state (new-gate-state)
        year (find-target-year state calculation-day target-day)
        structure (build-year-structure state calculation-day year)
        chosen-cutlet (some #(when (<= (:first-day %) target-day (:last-day %)) %) (:cutlets structure))]
    (when-not chosen-cutlet
      (throw (ex-info "Geen kotelet bevat de gevraagde dag." {:code :cutlet-not-found :day target-day})))
    (let [day-in-cutlet (inc (- target-day (:first-day chosen-cutlet)))
          year-offset (int (- target-day (inc (:open-gate-day year))))
          month-id (nth (:month-weaving structure) year-offset)
          month-index (nth (:month-names structure) (dec month-id))
          day-in-month (count (filter #(= % month-id) (take (inc year-offset) (:month-weaving structure))))]
      [(:number year)
       (:name-index chosen-cutlet)
       day-in-cutlet
       month-index
       day-in-month])))

(defn calendar-date [calculation-day target-day]
  (let [[year-number cutlet-index day-in-cutlet month-index day-in-month]
        (calendar-date-canonical calculation-day target-day)]
    [year-number
     (catalog/cutlet-source cutlet-index)
     day-in-cutlet
     (catalog/month-source month-index)
     day-in-month]))
