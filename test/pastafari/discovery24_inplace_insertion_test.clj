(ns pastafari.discovery24-inplace-insertion-test
  (:require [clojure.test :refer [deftest is testing]]
            [clojure.string :as string]
            [pastafari.maandrang :as maandrang]
            [pastafari.discovery24-dp-feasibility-test :as canonical])
  (:import [java.nio.charset StandardCharsets]
           [java.security MessageDigest]
           [java.util LinkedHashMap]))

(def ^:private cache-limit 2048)
(def ^:private alternative-write-limit 5000000N)
(def ^:private small-profiles
  [[2 2] [2 3] [3 2] [2 2 2] [2 3 2] [3 2 2] [2 2 2 2] [4 4]])

(def ^:private source-raming-var
  (or (ns-resolve 'pastafari.maandrang 'raming)
      (throw (ex-info "production raming Var is missing" {}))))

(defn- new-lru-cache []
  (LinkedHashMap. 16 (float 0.75) true))

(defn- cache-put! [^LinkedHashMap cache key value]
  (.put cache key value)
  (when (> (.size cache) cache-limit)
    (let [iterator (.iterator (.keySet cache))]
      (.next iterator)
      (.remove iterator)))
  value)

(defn- new-context []
  {:suffix-cache (new-lru-cache)
   :tail-cache (new-lru-cache)
   :writes (volatile! 0N)})

(defn- hex-bytes [bytes]
  (let [digits "0123456789abcdef"]
    (apply str
           (mapcat (fn [byte-value]
                     (let [value (bit-and (int byte-value) 255)]
                       [(nth digits (bit-shift-right value 4))
                        (nth digits (bit-and value 15))]))
                   bytes))))

(defn- sha256-hex [value]
  (let [digest (MessageDigest/getInstance "SHA-256")]
    (.update digest (.getBytes value StandardCharsets/US_ASCII))
    (hex-bytes (.digest digest))))

(defn- git-blob-sha [content]
  (let [bytes (.getBytes content StandardCharsets/UTF_8)
        header (.getBytes (str "blob " (alength bytes) (char 0))
                          StandardCharsets/UTF_8)
        digest (MessageDigest/getInstance "SHA-1")]
    (.update digest header)
    (.update digest bytes)
    (hex-bytes (.digest digest))))

(defn- binomial [n k]
  (loop [i 1 acc 1N]
    (if (> i k)
      acc
      (recur (inc i)
             (quot (*' acc (+ (- n k) i)) i)))))

(defn- tail-factor-inplace [active-days unopened-counts first-constrained? context]
  (let [^LinkedHashMap cache (:tail-cache context)
        key [(int active-days) (vec unopened-counts) (boolean first-constrained?)]]
    (if (.containsKey cache key)
      (.get cache key)
      (let [answer
            (if (empty? unopened-counts)
              1N
              (loop [n (int active-days)
                     future (seq unopened-counts)
                     dp nil
                     total 1N
                     step 0]
                (if (nil? future)
                  total
                  (let [k (int (first future))
                        constrained? (or first-constrained? (pos? step))
                        old-length (if (nil? dp) 0 (alength ^objects dp))
                        new-length (+ n k 1)
                        next-dp
                        (if (nil? dp)
                          (object-array (repeat new-length 0N))
                          (let [array (object-array new-length)]
                            (System/arraycopy dp 0 array 0 old-length)
                            (doseq [index (range old-length new-length)]
                              (aset array index 0N))
                            array))
                        new-total
                        (loop [a n weight 1N prefix total subtotal 0N]
                          (if (neg? a)
                            subtotal
                            (let [t (- n a)
                                  next-weight
                                  (if (and (>= k 2) (pos? t))
                                    (quot (*' weight (+ t k -2)) t)
                                    weight)
                                  ways (if (>= k 2)
                                         next-weight
                                         (if (zero? t) 1N 0N))
                                  old (when-not (nil? dp)
                                        (aget ^objects next-dp a))
                                  factor
                                  (if (nil? dp)
                                    (if constrained?
                                      (if (pos? a) 1N 0N)
                                      total)
                                    (if constrained? prefix total))
                                  value (*' factor ways)
                                  _ (aset ^objects next-dp (inc a) value)
                                  next-prefix
                                  (if (and (some? dp) constrained?)
                                    (-' prefix old)
                                    prefix)]
                              (recur (dec a) next-weight next-prefix
                                     (+' subtotal value)))))]
                    (when-not (nil? dp)
                      (aset ^objects next-dp 0 0N))
                    (let [next-writes (+' @(:writes context) (inc n))]
                      (when (> next-writes alternative-write-limit)
                        (throw (ex-info "alternative DP cell-write budget exceeded"
                                        {:code :alternative-dp-cell-write-budget-exceeded
                                         :writes next-writes})))
                      (vreset! (:writes context) next-writes))
                    (recur (+ n k) (next future) next-dp new-total (inc step))))))]
        (cache-put! cache key answer)))))

(defn- suffix-count-inplace [state context]
  (let [^LinkedHashMap cache (:suffix-cache context)]
    (if (.containsKey cache state)
      (.get cache state)
      (let [[counts opened closed] state
            month-count (count counts)]
        (when-not (and (integer? closed)
                       (integer? opened)
                       (<= 0 closed opened month-count))
          (throw (ex-info "invalid insertion-state grammar indices"
                          {:state state})))
        (when (some #(not (zero? %)) (subvec counts 0 closed))
          (throw (ex-info "closed month still has remaining days" {:state state})))
        (when (some #(not (pos? %)) (subvec counts closed))
          (throw (ex-info "live month has no remaining days" {:state state})))
        (let [answer
              (cond
                (= closed month-count)
                1N

                (= opened closed)
                (tail-factor-inplace (nth counts closed)
                                     (subvec counts (inc closed))
                                     true
                                     context)

                :else
                (let [[active-days base]
                      (loop [index (inc closed)
                             active-days (nth counts closed)
                             base 1N]
                        (if (>= index opened)
                          [active-days base]
                          (let [amount (nth counts index)
                                next-active (+ active-days amount)
                                next-base (*' base
                                              (binomial (dec next-active)
                                                        (dec amount)))]
                            (recur (inc index) next-active next-base))))]
                  (*' base
                      (tail-factor-inplace active-days
                                           (subvec counts opened)
                                           false
                                           context))))]
          (cache-put! cache state answer))))))

(defn- legal-moves [state]
  (let [[counts opened closed] state
        month-count (count counts)]
    (vec
     (for [index (range (min month-count (inc opened)))
           :let [before (nth counts index)]
           :when (and (pos? before)
                      (or (not= before 1) (= index closed)))]
       [(inc index)
        [(assoc counts index (dec before))
         (max opened (inc index))
         (+ closed (if (= before 1) 1 0))]]))))

(defn- source-raming [restvector opened]
  (bigint (@source-raming-var restvector opened)))

(defn- maybe-snapshot [snapshots prefix shared-cost source-cost context]
  (let [position (count prefix)]
    (if (contains? #{81 82 520} position)
      (let [month-id (peek prefix)]
        (assoc snapshots position
               {:prefix-sha256 (sha256-hex (string/join "," prefix))
                :month-id month-id
                :day-in-month (count (filter #(= month-id %) prefix))
                :dp-cell-writes @(:writes context)
                ;; This reproduces the committed Python oracle's separate
                ;; shared-group diagnostic; it is not the source raming metric.
                :python-shared-group-cost shared-cost
                ;; This invokes the exact private raming Var from the pinned
                ;; production blob, once per candidate examined (root included).
                :source-raming-cost source-cost}))
      snapshots)))

(defn- rank-trace-inplace
  ([profile ordinal target context]
   (rank-trace-inplace profile ordinal target context nil))
  ([profile ordinal target context production-budget]
   (let [profile (vec profile)
         month-count (count profile)
         root [profile 0 0]
         total (suffix-count-inplace root context)]
     (when-not (and (>= month-count 2)
                    (every? #(>= % 2) profile)
                    (<= 1 target (reduce + 0 profile))
                    (integer? ordinal)
                    (<= 1N ordinal total))
       (throw (ex-info "invalid profile, rank, or target"
                       {:profile profile :rank ordinal :target target :total total})))
     (let [[first-month first-state] (first (legal-moves root))
           initial-source-cost (source-raming (first first-state)
                                              (second first-state))]
       (when-not (= first-month 1)
         (throw (ex-info "the mandatory first month is not month 1"
                         {:first-month first-month})))
       (loop [state first-state
              current-rank ordinal
              prefix [first-month]
              shared-cost 0N
              source-cost initial-source-cost
              tested 0
              skipped 0
              snapshots {}]
         (if (>= (count prefix) target)
           {:status :PREFIX_CERTIFIED
            :total total
            :prefix prefix
            :billed shared-cost
            :source-raming-cost source-cost
            :dp-cell-writes @(:writes context)
            :tested tested
            :skipped skipped
            :snapshots snapshots}
           (let [[counts opened _closed] state
                 legal (legal-moves state)
                 active (filterv (fn [[month _child]] (<= month opened)) legal)
                 new (filterv (fn [[month _child]] (= month (inc opened))) legal)
                 active-charge
                 (when (seq active)
                   (+' 1N (*' (- month-count opened)
                               (reduce +' 0N counts))))]
             (if (and production-budget
                      active-charge
                      (> (+' shared-cost active-charge) production-budget))
               {:status :PRODUCTION_BUDGET_REFUSAL
                :prefix prefix
                :prefix-length (count prefix)
                :billed-before shared-cost
                :required-next (+' shared-cost active-charge)
                :next-charge active-charge
                :group :ACTIVE
                :tested tested
                :skipped skipped}
               (let [shared-after-active
                     (if active-charge (+' shared-cost active-charge) shared-cost)
                     active-result
                     (loop [candidates (seq active)
                            rank current-rank
                            source source-cost
                            tested-count tested
                            skipped-count skipped]
                       (if (nil? candidates)
                         {:found? false
                          :rank rank
                          :source source
                          :tested tested-count
                          :skipped skipped-count}
                         (let [[month child] (first candidates)
                               next-source
                               (+' source
                                   (source-raming (first child) (second child)))
                               block (suffix-count-inplace child context)
                               next-tested (inc tested-count)]
                           (if (> rank block)
                             (recur (next candidates)
                                    (-' rank block)
                                    next-source
                                    next-tested
                                    (inc skipped-count))
                             {:found? true
                              :month month
                              :state child
                              :rank rank
                              :source next-source
                              :tested next-tested
                              :skipped skipped-count}))))] 
                 (if (:found? active-result)
                   (let [next-prefix (conj prefix (:month active-result))
                         next-snapshots
                         (maybe-snapshot snapshots next-prefix shared-after-active
                                         (:source active-result) context)]
                     (recur (:state active-result)
                            (:rank active-result)
                            next-prefix
                            shared-after-active
                            (:source active-result)
                            (:tested active-result)
                            (:skipped active-result)
                            next-snapshots))
                   (let [new-charge
                         (when (seq new)
                           (+' 1N (*' (- month-count opened 1)
                                       (reduce +' 0N counts))))]
                     (if (and production-budget
                              new-charge
                              (> (+' shared-after-active new-charge) production-budget))
                       {:status :PRODUCTION_BUDGET_REFUSAL
                        :prefix prefix
                        :prefix-length (count prefix)
                        :billed-before shared-after-active
                        :required-next (+' shared-after-active new-charge)
                        :next-charge new-charge
                        :group :NEW
                        :tested (:tested active-result)
                        :skipped (:skipped active-result)}
                       (if (seq new)
                         (let [[month child] (first new)
                               next-source
                               (+' (:source active-result)
                                   (source-raming (first child) (second child)))
                               block (suffix-count-inplace child context)
                               next-tested (inc (:tested active-result))]
                           (when (> (:rank active-result) block)
                             (throw (ex-info "new candidate block is too small"
                                             {:rank (:rank active-result)
                                              :block block
                                              :state state})))
                           (let [next-prefix (conj prefix month)
                                 next-shared (if new-charge
                                               (+' shared-after-active new-charge)
                                               shared-after-active)
                                 next-snapshots
                                 (maybe-snapshot snapshots next-prefix next-shared
                                                 next-source context)]
                             (recur child
                                    (:rank active-result)
                                    next-prefix
                                    next-shared
                                    next-source
                                    next-tested
                                    (:skipped active-result)
                                    next-snapshots)))
                         (throw (ex-info "no legal candidate"
                                         {:state state :rank current-rank})))))))))))))))
(defn- brute-legal-words [profile]
  (let [month-count (count profile)
        target-length (reduce + 0 profile)
        result (atom [])]
    (letfn [(visit [remaining word]
              (if (= (count word) target-length)
                (let [positions
                      (mapv (fn [month]
                              (keep-indexed (fn [index value]
                                              (when (= value month) index))
                                            word))
                            (range 1 (inc month-count)))
                      firsts (mapv first positions)
                      lasts (mapv last positions)]
                  (when (and (= firsts (vec (sort firsts)))
                             (= lasts (vec (sort lasts))))
                    (swap! result conj word)))
                (doseq [index (range month-count)
                        :let [amount (nth remaining index)]
                        :when (pos? amount)]
                  (visit (update remaining index dec)
                         (conj word (inc index))))))]
      (visit (vec profile) [])
      (vec (sort @result)))))

(defn- small-family-summary []
  (let [digest (MessageDigest/getInstance "SHA-256")
        totals (atom {:legal-words 0
                      :rank-position-checks 0
                      :exact-budget-accepts 0
                      :budget-minus-one-refusals 0
                      :source-accounting-non-equal 0})]
    (doseq [profile small-profiles]
      (let [words (brute-legal-words profile)
            context (new-context)
            root-total (suffix-count-inplace [profile 0 0] context)]
        (is (= (count words) root-total)
            (str "small root count mismatch for " profile))
        (swap! totals update :legal-words + (count words))
        (doseq [[rank-index word] (map-indexed vector words)]
          (let [rank (inc rank-index)]
            (doseq [position (range 1 (inc (count word)))]
              (let [full (rank-trace-inplace profile rank position context)
                    expected (subvec word 0 position)
                    line (str (string/join "," profile) "|"
                              rank "|" position "|"
                              (string/join "," (:prefix full)) "|"
                              (:total full) "|" (:dp-cell-writes full) "\n")]
                (is (= :PREFIX_CERTIFIED (:status full))
                    (str "small trace not certified: " profile "/" rank "/" position))
                (is (= expected (:prefix full))
                    (str "small prefix mismatch: " profile "/" rank "/" position))
                (.update digest (.getBytes line StandardCharsets/US_ASCII))
                (swap! totals update :rank-position-checks inc)
                (let [exact (rank-trace-inplace profile rank position context
                                                 (:billed full))]
                  (is (= :PREFIX_CERTIFIED (:status exact))
                      (str "exact shared-budget acceptance failed: "
                           profile "/" rank "/" position))
                  (is (= (:prefix full) (:prefix exact))))
                (when (pos? (:billed full))
                  (let [below (rank-trace-inplace profile rank position context
                                                  (dec (:billed full)))]
                    (is (= :PRODUCTION_BUDGET_REFUSAL (:status below))
                        (str "budget-minus-one did not refuse: "
                             profile "/" rank "/" position))
                    (swap! totals update :budget-minus-one-refusals inc)))
                (swap! totals update :exact-budget-accepts inc)))
            (let [source-trace
                  (rank-trace-inplace profile rank (count word) (new-context))]
              (is (> (:source-raming-cost source-trace)
                     (:dp-cell-writes source-trace))
                  (str "source raming and DP writes unexpectedly coincide: "
                       profile "/" rank))
              (swap! totals update :source-accounting-non-equal inc)))))
    (assoc @totals
           :profiles (count small-profiles)
           :digest (hex-bytes (.digest digest)))))

(defn- parse-python-output [output]
  (into {}
        (map (fn [line]
               (let [[key value] (string/split line #"\s+" 2)]
                 [(keyword key) value]))
             (remove string/blank? (string/split-lines output)))))

(defn- run-python-reference [canonical-input-path]
  (let [arguments (java.util.ArrayList.
                   ["python3"
                    "qa/clojure-dutch/discovery24_inplace_insertion_reference.py"
                    "--canonical-input"
                    canonical-input-path])
        builder (doto (ProcessBuilder. arguments)
                  (.redirectErrorStream true))
        process (.start builder)
        output (slurp (.getInputStream process))
        exit-code (.waitFor process)]
    (when-not (zero? exit-code)
      (throw (ex-info "committed Python reference failed"
                      {:exit-code exit-code :output output})))
    (parse-python-output output)))

(defn- python-long [python-result key]
  (Long/parseLong (get python-result key)))

(deftest discovery24-inplace-insertion-cross-check
  (testing "the measured source-accounting function is pinned"
    (is (= "62f304dc013a9a9f70475bb0d34f186838b27318"
           (git-blob-sha (slurp "src/pastafari/maandrang.clj")))))
  (let [small (small-family-summary)
        canonical-input (canonical/write-canonical-input!)
        python (run-python-reference (:path canonical-input))
        context (new-context)
        actual (rank-trace-inplace (:profile canonical-input)
                                   (:rank canonical-input)
                                   520
                                   context)
        snapshots (:snapshots actual)]
    (testing "small exhaustive profiles match the committed Python oracle"
      (is (= "PASS_MODEL_ONLY" (:RESULT python)))
      (is (= (:profiles small) (python-long python :SMALL_PROFILES)))
      (is (= (:legal-words small) (python-long python :SMALL_LEGAL_WORDS)))
      (is (= (:rank-position-checks small)
             (python-long python :SMALL_RANK_POSITION_CHECKS)))
      (is (= (:exact-budget-accepts small)
             (python-long python :SMALL_EXACT_BUDGET_ACCEPTS)))
      (is (= (:budget-minus-one-refusals small)
             (python-long python :SMALL_BUDGET_MINUS_ONE_REFUSALS)))
      (is (= (:digest small) (:SMALL_DIGEST python)))
      (is (= 67 (:source-accounting-non-equal small))))
    (testing "canonical p81/p82/p520 match both independent Python counters"
      (is (= :PREFIX_CERTIFIED (:status actual)))
      (is (= (:total canonical-input) (:total actual)))
      (is (= (str (:total actual)) (:CANONICAL_TOTAL python)))
      (is (= (str (:dp-cell-writes actual)) (:CANONICAL_DP_CELL_WRITES python)))
      (is (= (str (:total actual)) (:GAP_TOTAL python)))
      (doseq [position [81 82 520]]
        (let [snapshot (get snapshots position)
              p (str "P" position "_")
              gap (str "GAP_P" position "_")]
          (is (= (:prefix-sha256 snapshot)
                 (get python (keyword (str p "SHA")))))
          (is (= (:prefix-sha256 snapshot)
                 (get python (keyword (str gap "SHA")))))
          (is (= (str (:month-id snapshot))
                 (get python (keyword (str p "MONTH_ID")))))
          (is (= (str (:day-in-month snapshot))
                 (get python (keyword (str p "DAY_IN_MONTH")))))
          (is (= (str (:dp-cell-writes snapshot))
                 (get python (keyword (str p "DP_CELL_WRITES")))))
          (is (= (str (:python-shared-group-cost snapshot))
                 (get python (keyword (str p "SHARED_COST")))))
          (is (= (str (:month-id snapshot))
                 (get python (keyword (str gap "MONTH_ID")))))
          (is (= (str (:day-in-month snapshot))
                 (get python (keyword (str gap "DAY_IN_MONTH")))))
          (is (= (str (:python-shared-group-cost snapshot))
                 (get python (keyword (str gap "SHARED_COST")))))
          (is (not= (:source-raming-cost snapshot)
                    (:dp-cell-writes snapshot))
              (str "production raming units and alternative DP writes are not interchangeable at p"
                   position))))
      (is (<= (:dp-cell-writes actual) alternative-write-limit))
      (println "DISCOVERY24_CLOJURE_INPLACE_RESULT"
               (pr-str
                {:source-blob-sha "62f304dc013a9a9f70475bb0d34f186838b27318"
                 :python-oracle-blob-sha "e3a5616acda7c1fd1853e9c6114049efa86d7bd3"
                 :profile-months (count (:profile canonical-input))
                 :profile-days (reduce +' 0N (:profile canonical-input))
                 :rank-digits (count (str (:rank canonical-input)))
                 :dp-cell-writes (:dp-cell-writes actual)
                 :p81 (get snapshots 81)
                 :p82 (get snapshots 82)
                 :p520 (get snapshots 520)
                 :five-field-differential :not-run
                 :stage2 :open}))))))

