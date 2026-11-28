(ns pastafari.discovery24-inplace-insertion-test
  (:require [clojure.test :refer [deftest is testing]]
            [clojure.string :as string]
            [pastafari.maandrang :as maandrang]
            [pastafari.discovery24-dp-feasibility-test :as canonical]
            [pastafari.normative-oracle :as oracle])
  (:import [java.nio.charset StandardCharsets]
           [java.security MessageDigest]
           [java.util LinkedHashMap ArrayList Collections Arrays]
           [java.io ByteArrayInputStream SequenceInputStream PushbackInputStream]))

(def ^:private cache-limit 2048)
(def ^:private alternative-write-limit 5000000N)
(def ^:private small-profiles
  [[2 2] [2 3] [3 2] [2 2 2] [2 3 2] [3 2 2] [2 2 2 2] [4 4]])

(def ^:private source-raming-var
  (or (ns-resolve 'pastafari.maandrang 'raming)
      (throw (ex-info "production raming Var is missing" {}))))


(def ^:private alternative-scalar-limit 550000000000N)
(def ^:private alternative-bit-limit 65000000000000000000000N)
(def ^:private alternative-payload-limit 1000000000N)
(def ^:private alternative-wall-limit-nanos 90000000000)
(def ^:private alternative-heap-delta-limit-bytes (* 256 1024 1024))
(def ^:private alternative-frame-limit-bytes 176120)
(def ^:private alternative-chunk-limit-bytes 4096)
(defn- used-heap-bytes []
  (let [runtime (Runtime/getRuntime)] (- (.totalMemory runtime) (.freeMemory runtime))))
(defn- integer-bit-length [value] (max 1 (.bitLength (biginteger value))))
(defn- watchdog-check! [context]
  (when-let [watchdog (:watchdog context)]
    (let [now (System/nanoTime) used (used-heap-bytes)
          delta (- used (:baseline-heap-bytes watchdog))]
      (vswap! (:peak-heap-bytes context) max used)
      (when (.isInterrupted (Thread/currentThread))
        (throw (ex-info "Alternative C execution interrupted" {:code :alternative-c-interrupted})))
      (when (> now (:deadline-nanos watchdog))
        (throw (ex-info "Alternative C wall-clock watchdog exceeded"
                        {:code :alternative-c-time-watchdog :elapsed-nanos (- now (:start-nanos watchdog))})))
      (when (> delta (:heap-delta-limit-bytes watchdog))
        (throw (ex-info "Alternative C heap-delta watchdog exceeded"
                        {:code :alternative-c-heap-watchdog :heap-delta-bytes delta
                         :heap-delta-limit-bytes (:heap-delta-limit-bytes watchdog)})))))
  nil)
(defn- ledger-op! [context operation a b result]
  (when-let [ledger (:ledger context)]
    (let [a-bits (integer-bit-length a) b-bits (integer-bit-length b)
          cost (if (#{:mul :div :mod} operation) (*' a-bits b-bits) (+' (max a-bits b-bits) 1N))
          arithmetic-count (vswap! (:primitive-count ledger) +' 1N)
          bit-work (vswap! (:bit-work ledger) +' cost)
          controls (bigint @(:control-count ledger))
          total-primitives (+' arithmetic-count controls)
          total-bit-work (+' bit-work (*' 64N controls))
          result-bits (when (some? result) (integer-bit-length result))]
      (when (or (> a-bits (:word-bits ledger)) (> b-bits (:word-bits ledger)))
        (throw (ex-info "Alternative C operand exceeded W"
                        {:code :alternative-c-word-width :a-bits a-bits :b-bits b-bits
                         :limit (:word-bits ledger)})))
      (vswap! (:ops ledger) update operation (fnil +' 0N) 1N)
      (vswap! (:max-word-bits ledger) max a-bits b-bits (or result-bits 1N))
      (when (> total-primitives (:scalar-limit ledger))
        (throw (ex-info "Alternative C scalar primitive limit exceeded"
                        {:code :alternative-c-scalar-limit :observed total-primitives :limit (:scalar-limit ledger)})))
      (when (> total-bit-work (:bit-limit ledger))
        (throw (ex-info "Alternative C bit-work limit exceeded"
                        {:code :alternative-c-bit-limit :observed total-bit-work :limit (:bit-limit ledger)})))
      (when (and result-bits (> result-bits (:word-bits ledger)))
        (throw (ex-info "Alternative C result exceeded W"
                        {:code :alternative-c-word-width :observed result-bits :limit (:word-bits ledger)})))
      (when (zero? (mod total-primitives 256N)) (watchdog-check! context))))
  result)
(defn- control-op! [context]
  (when-let [ledger (:ledger context)]
    (let [controls (vswap! (:control-count ledger) inc)]
      (when (zero? (mod controls 256))
        (let [total-primitives (+' @(:primitive-count ledger) (bigint controls))
              total-bit-work (+' @(:bit-work ledger) (*' 64N (bigint controls)))]
          (when (> total-primitives (:scalar-limit ledger))
            (throw (ex-info "Alternative C scalar primitive limit exceeded"
                            {:code :alternative-c-scalar-limit :observed total-primitives :limit (:scalar-limit ledger)})))
          (when (> total-bit-work (:bit-limit ledger))
            (throw (ex-info "Alternative C bit-work limit exceeded"
                            {:code :alternative-c-bit-limit :observed total-bit-work :limit (:bit-limit ledger)})))
          (watchdog-check! context)))))
  nil)
(defn- alt-add [context a b] (ledger-op! context :add a b (+' a b)))
(defn- alt-sub [context a b]
  (when (< a b) (throw (ex-info "Alternative C negative subtraction"
                                {:code :alternative-c-negative-subtraction :a a :b b})))
  (ledger-op! context :sub a b (-' a b)))
(defn- alt-mul [context a b] (ledger-op! context :mul a b (*' a b)))
(defn- alt-div-exact [context a b]
  (when (zero? b) (throw (ex-info "Alternative C division by zero" {:code :alternative-c-division-by-zero})))
  (let [remainder (rem a b) _ (ledger-op! context :mod a b remainder)]
    (when-not (zero? remainder)
      (throw (ex-info "Alternative C expected exact integer division"
                      {:code :alternative-c-inexact-division :a a :b b :remainder remainder})))
    (ledger-op! context :div a b (quot a b))))
(defn- alt-gt? [context a b] (ledger-op! context :compare a b nil) (> a b))
(defn- new-arithmetic-ledger [certificate]
  {:ops (volatile! {:add 0N :sub 0N :mul 0N :div 0N :mod 0N :compare 0N})
   :primitive-count (volatile! 0N) :control-count (volatile! 0)
   :bit-work (volatile! 0N) :max-word-bits (volatile! 1N)
   :word-bits (:W certificate) :scalar-limit alternative-scalar-limit
   :bit-limit alternative-bit-limit :payload-limit alternative-payload-limit
   :live-payload-upper-bound-bits (:payload certificate)})
(defn- ceil-log2 [value]
  (loop [power 1N bits 0N] (if (>= power value) bits (recur (*' power 2N) (inc bits)))))
(defn- alternative-admission-certificate [profile position]
  (let [m (bigint (count profile)) n (reduce +' 0N profile) p (bigint position)
        B (+' (*' 2N n (ceil-log2 (inc m))) (*' 2N (ceil-log2 (inc n))) 8N)
        W (+' (*' 2N B) 2N) Q (+' 1N (*' (dec p) m))
        scalar (*' 256N (+' (*' Q (+' (*' (inc m) (inc n)) n m 1N))
                            (*' p (*' (inc m) (inc m))) n p 1N))
        chars (+' (*' 4N B) (*' 8N m) (*' 8N p) 256N)
        bit (+' (*' 16N (*' (inc W) (inc W)) scalar)
                (*' 32N chars (*' (inc W) (inc W))))
        payload (+' (*' W (+' (*' 3N (inc n)) (*' 4N m) p 128N))
                    (*' 8N chars) (*' 16N (inc W)))]
    {:m m :n n :p p :B B :W W :Q Q :scalar scalar :chars chars :bit bit :payload payload}))
(defn- alternative-admission-status [certificate rank-length limits]
  (cond (> (bigint rank-length) (:B certificate)) :REFUSE_RANK_ENCODING
        (some (fn [key] (> (get certificate key) (get limits key))) [:scalar :bit :payload])
        :REFUSE_RESOURCE_BOUND :else :ADMIT_MODEL_ONLY))
(defn- parser-fail! [code details]
  (throw (ex-info (str "Alternative C streaming parser refused: " (name code))
                  (assoc details :code code))))
(defn- expect-literal! [^PushbackInputStream input literal]
  (doseq [expected-byte (.getBytes literal StandardCharsets/US_ASCII)]
    (let [actual (.read input) expected (bit-and (int expected-byte) 255)]
      (when-not (= actual expected)
        (parser-fail! (if (= actual -1) :truncated :grammar)
                      {:expected expected :actual actual :literal literal}))))
  nil)
(defn- read-number-until! [^PushbackInputStream input delimiters max-digits]
  (loop [digits 0 value 0]
    (let [byte-value (.read input)]
      (cond
        (= byte-value -1) (parser-fail! :truncated {:field :number})
        (<= 48 byte-value 57)
        (do (when (and (zero? digits) (= byte-value 48))
              (parser-fail! :leading-zero {:field :number}))
            (when (>= digits max-digits)
              (parser-fail! :number-width {:field :number :max-digits max-digits}))
            (recur (inc digits) (+ (* value 10) (- byte-value 48))))
        (contains? delimiters byte-value)
        (if (zero? digits) (parser-fail! :empty-number {:field :number})
            {:value value :delimiter byte-value})
        :else (parser-fail! :grammar {:field :number :byte byte-value})))))
(defn- parse-streamed-frame [chunks]
  (let [chunks (vec chunks) chunk-count (count chunks)]
    (when (or (empty? chunks)
              (some (fn [chunk]
                      (or (not (instance? (Class/forName "[B") chunk))
                          (zero? (alength ^bytes chunk))
                          (> (alength ^bytes chunk) alternative-chunk-limit-bytes))) chunks))
      (parser-fail! :chunk-size {:chunk-count chunk-count}))
    (let [frame-bytes (reduce + 0 (map #(alength ^bytes %) chunks))]
      (when (> frame-bytes alternative-frame-limit-bytes)
        (parser-fail! :frame-size {:frame-bytes frame-bytes}))
      (let [streams (ArrayList.)]
        (doseq [chunk chunks] (.add streams (ByteArrayInputStream. ^bytes chunk)))
        (with-open [input (PushbackInputStream. (SequenceInputStream. (Collections/enumeration streams)) 1)]
          (expect-literal! input "{\"profile\":[")
          (let [profile
                (loop [values [] total 0]
                  (let [{value :value delimiter :delimiter} (read-number-until! input #{44 93} 3)]
                    (when (or (< value 4) (> value 123) (>= (count values) 33) (> (+ total value) 3569))
                      (parser-fail! :profile-scope {:value value :count (count values) :total (+ total value)}))
                    (let [next-values (conj values (bigint value)) next-total (+ total value)]
                      (if (= delimiter 93)
                        (if (< (count next-values) 2)
                          (parser-fail! :profile-scope {:count (count next-values)})
                          next-values)
                        (recur next-values next-total)))))]
            (expect-literal! input ",\"p\":")
            (let [{position :value delimiter :delimiter} (read-number-until! input #{44} 3)
                  total-days (reduce + 0 profile)]
              (when (or (not= delimiter 44) (< position 1) (>= position total-days) (> position 520))
                (parser-fail! :position-scope {:position position :total-days total-days}))
              (let [certificate (alternative-admission-certificate profile position)
                    rank-buffer (byte-array (int (:B certificate)))]
                (expect-literal! input "\"rank\":\"")
                (let [rank-length
                      (loop [index 0]
                        (let [byte-value (.read input)]
                          (cond
                            (= byte-value -1) (parser-fail! :truncated {:field :rank})
                            (= byte-value 34) (if (zero? index) (parser-fail! :empty-rank {}) index)
                            (<= 48 byte-value 57)
                            (do (when (and (zero? index) (= byte-value 48))
                                  (parser-fail! :leading-zero {:field :rank}))
                                (when (>= index (alength rank-buffer))
                                  (parser-fail! :rank-width {:capacity (alength rank-buffer)}))
                                (aset-byte rank-buffer index (unchecked-byte byte-value))
                                (recur (inc index)))
                            :else (parser-fail! :rank-encoding {:byte byte-value}))))]
                  (expect-literal! input "}")
                  (when-not (= -1 (.read input)) (parser-fail! :trailing-bytes {}))
                  {:profile profile :p position :rank-bytes (Arrays/copyOf rank-buffer rank-length)
                   :rank-capacity (:B certificate) :frame-bytes frame-bytes :chunk-count chunk-count})))))))))
(defn- byte-chunks [^bytes bytes chunk-size]
  (loop [offset 0 chunks []]
    (if (>= offset (alength bytes))
      chunks
      (let [end (min (alength bytes) (+ offset chunk-size))]
        (recur end (conj chunks (Arrays/copyOfRange bytes offset end)))))))
(defn- canonical-request-frame [canonical-input position]
  (str "{\"profile\":[" (string/join "," (map str (:profile canonical-input)))
       "],\"p\":" position ",\"rank\":\"" (:rank canonical-input) "\"}"))
(defn- parse-rank-after-admission [parsed certificate context]
  (let [^bytes bytes (:rank-bytes parsed) length (alength bytes)]
    (loop [index 0 value 0N]
      (if (= index length) value
          (let [digit (- (bit-and (int (aget bytes index)) 255) 48)
                next-value (alt-add context (alt-mul context value 10N) (bigint digit))
                bits (.bitLength (biginteger next-value))]
            (when (> bits (:W certificate))
              (parser-fail! :word-width {:bits bits :limit (:W certificate)}))
            (recur (inc index) next-value))))))
(defn- thrown-code [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo error (:code (ex-data error)))))
(defn- streaming-parser-small-checks []
  (let [sample (.getBytes "{\"profile\":[4,5],\"p\":3,\"rank\":\"35\"}" StandardCharsets/US_ASCII)
        length (alength sample)]
    (let [parsed (parse-streamed-frame [sample])]
      (is (= [4N 5N] (:profile parsed)))
      (is (= 3 (:p parsed)))
      (is (= "35" (String. ^bytes (:rank-bytes parsed) StandardCharsets/US_ASCII))))
    (is (= :chunk-size (thrown-code #(parse-streamed-frame []))))
    (is (= :chunk-size (thrown-code #(parse-streamed-frame [(byte-array 0)]))))
    (doseq [split (range 1 length)]
      (let [parsed (parse-streamed-frame [(Arrays/copyOfRange sample 0 split)
                                          (Arrays/copyOfRange sample split length)])]
        (is (= [4N 5N] (:profile parsed)))
        (is (= 3 (:p parsed)))
        (is (= "35" (String. ^bytes (:rank-bytes parsed) StandardCharsets/US_ASCII)))))
    (is (= :truncated (thrown-code #(parse-streamed-frame
                                     [(Arrays/copyOfRange sample 0 (dec length))]))))
    (is (= :leading-zero (thrown-code #(parse-streamed-frame
                                        [(.getBytes "{\"profile\":[04,5],\"p\":3,\"rank\":\"35\"}"
                                                    StandardCharsets/US_ASCII)]))))
    (is (= :position-scope (thrown-code #(parse-streamed-frame
                                          [(.getBytes "{\"profile\":[4,5],\"p\":9,\"rank\":\"35\"}"
                                                      StandardCharsets/US_ASCII)]))))
    (is (= :profile-scope (thrown-code #(parse-streamed-frame
                                         [(.getBytes "{\"profile\":[3,5],\"p\":3,\"rank\":\"35\"}"
                                                     StandardCharsets/US_ASCII)]))))
    (is (= :chunk-size (thrown-code #(parse-streamed-frame
                                      [(byte-array (inc alternative-chunk-limit-bytes))]))))
    (is (= :frame-size
           (thrown-code
            #(parse-streamed-frame
              (vec (repeat 44 (byte-array alternative-chunk-limit-bytes)))))))
    (is (= :trailing-bytes
           (thrown-code
            #(let [trailing (Arrays/copyOf sample (inc length))]
               (aset-byte trailing length (byte 32))
               (parse-streamed-frame [trailing])))))
    {:two-chunk-splits (dec length) :truncated-refusal :passed
     :leading-zero-refusal :passed :position-refusal :passed
     :profile-scope-refusal :passed :chunk-cap-refusal :passed
     :frame-cap-refusal :passed :trailing-byte-refusal :passed}))

(defn- new-lru-cache []
  (LinkedHashMap. 16 (float 0.75) true))

(defn- cache-put! [^LinkedHashMap cache key value]
  (.put cache key value)
  (when (> (.size cache) cache-limit)
    (let [iterator (.iterator (.keySet cache))]
      (.next iterator)
      (.remove iterator)))
  value)

(defn- new-context
  ([] (new-context {}))
  ([{:keys [ledger watchdog]}]
   {:suffix-cache (new-lru-cache) :tail-cache (new-lru-cache)
    :writes (volatile! 0) :ledger ledger :watchdog watchdog
    :peak-heap-bytes (volatile! (or (:baseline-heap-bytes watchdog) (used-heap-bytes)))}))

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

(defn- binomial
  ([n k] (binomial nil n k))
  ([context n k]
   (loop [i 1 acc 1N]
     (if (> i k) acc
         (recur (inc i) (alt-div-exact context (alt-mul context acc (alt-add context (alt-sub context n k) i)) i))))))

(defn- tail-factor-inplace [active-days unopened-counts first-constrained? context]
  (watchdog-check! context)
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
                                    (alt-div-exact context (alt-mul context weight (+ t k -2)) t)
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
                                  value (alt-mul context factor ways)
                                  _ (aset ^objects next-dp (inc a) value)
                                  cell-control (control-op! context)
                                  next-prefix
                                  (if (and (some? dp) constrained?)
                                    (alt-sub context prefix old)
                                    prefix)]
                              (recur (dec a) next-weight next-prefix
                                     (alt-add context subtotal value)))))]
                    (when-not (nil? dp)
                      (aset ^objects next-dp 0 0N))
                    (let [next-writes (+ @(:writes context) (inc n))]
                      (when (> next-writes alternative-write-limit)
                        (throw (ex-info "alternative DP cell-write budget exceeded"
                                        {:code :alternative-dp-cell-write-budget-exceeded
                                         :writes next-writes})))
                      (vreset! (:writes context) next-writes)
                      (when (zero? (mod next-writes 256N)) (watchdog-check! context)))
                    (recur (+ n k) (next future) next-dp new-total (inc step))))))]
        (cache-put! cache key answer)))))

(defn- suffix-count-inplace [state context]
  (watchdog-check! context)
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
                                next-active (alt-add context active-days amount)
                                next-base (alt-mul context base
                                              (binomial context (dec next-active)
                                                        (dec amount)))]
                            (recur (inc index) next-active next-base))))]
                  (alt-mul context base
                           (tail-factor-inplace active-days (subvec counts opened) false context))))]
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
   (watchdog-check! context)
   (let [profile (vec profile)
         month-count (count profile)
         root [profile 0 0]
         total (suffix-count-inplace root context)]
     (when-not (and (>= month-count 2)
                    (every? #(>= % 2) profile)
                    (<= 1 target (reduce + 0 profile))
                    (integer? ordinal)
                    (and (not (alt-gt? context 1N ordinal))
                         (not (alt-gt? context ordinal total))))
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
         (watchdog-check! context)
         (if (>= (count prefix) target)
           {:status :PREFIX_CERTIFIED
            :total total
            :prefix prefix
            :billed shared-cost
            :source-raming-cost source-cost
            :state state
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
                   (alt-add context 1N
                            (alt-mul context (- month-count opened)
                                     (reduce (fn [total amount]
                                               (alt-add context total amount))
                                             0N counts))))]
             (if (and production-budget
                      active-charge
                      (alt-gt? context (alt-add context shared-cost active-charge) production-budget))
               {:status :PRODUCTION_BUDGET_REFUSAL
                :prefix prefix
                :prefix-length (count prefix)
                :billed-before shared-cost
                :required-next (alt-add context shared-cost active-charge)
                :next-charge active-charge
                :group :ACTIVE
                :tested tested
                :skipped skipped}
               (let [shared-after-active
                     (if active-charge (alt-add context shared-cost active-charge) shared-cost)
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
                           (control-op! context)
                           (if (alt-gt? context rank block)
                             (recur (next candidates)
                                    (alt-sub context rank block)
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
                           (alt-add context 1N
                                    (alt-mul context (- month-count opened 1)
                                             (reduce (fn [total amount]
                                                       (alt-add context total amount))
                                                     0N counts))))]
                     (if (and production-budget
                              new-charge
                              (> (alt-add context shared-after-active new-charge) production-budget))
                       {:status :PRODUCTION_BUDGET_REFUSAL
                        :prefix prefix
                        :prefix-length (count prefix)
                        :billed-before shared-after-active
                        :required-next (alt-add context shared-after-active new-charge)
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
                           (control-op! context)
                           (when (alt-gt? context (:rank active-result) block)
                             (throw (ex-info "new candidate block is too small"
                                             {:rank (:rank active-result)
                                              :block block
                                              :state state})))
                           (let [next-prefix (conj prefix month)
                                 next-shared (if new-charge
                                               (alt-add context shared-after-active new-charge)
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
              (swap! totals update :source-accounting-non-equal inc))))))
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

(defn- ensure-invariant! [condition message details]
  (when-not condition
    (throw (ex-info message details))))

(def ^:private canonical-calculation-day -15055654N)

(defn- normative-five-fields [calculation-day target-day month-id day-in-month]
  ;; The month ID and occurrence come from the independent gap-convolution
  ;; prefix oracle. All other date fields are recomputed by the normative
  ;; oracle; no full 3,569-symbol month weaving is materialized.
  (let [state (oracle/new-gate-state)
        year (oracle/find-target-year state calculation-day target-day)
        first-day (inc (:open-gate-day year))
        target-position (inc (-' target-day first-day))
        structure-sauce (oracle/sauce calculation-day first-day)
        cutlet-count (oracle/choose-cutlet-count structure-sauce year)
        cutlet-partition (oracle/choose-cutlet-partition
                          state calculation-day structure-sauce year cutlet-count)
        cutlet-name-indices (oracle/choose-cutlet-names structure-sauce cutlet-count)
        cutlets (oracle/materialize-cutlets
                 state year cutlet-partition cutlet-name-indices)
        matching-cutlets (filterv #(<= (:first-day %) target-day (:last-day %))
                                  cutlets)
        month-count (oracle/choose-month-count structure-sauce year)
        month-name-indices (oracle/choose-month-names structure-sauce month-count)]
    (ensure-invariant! (= 520N target-position)
                       "canonical target is not the p520 day"
                       {:target-position target-position :target-day target-day
                        :first-day first-day})
    (ensure-invariant! (= 1 (count matching-cutlets))
                       "normative oracle did not identify exactly one cutlet"
                       {:matching-cutlets (count matching-cutlets)})
    (ensure-invariant! (and (integer? month-id) (<= 1 month-id month-count))
                       "gap oracle month ID is outside the normative month range"
                       {:month-id month-id :month-count month-count})
    (ensure-invariant! (and (integer? day-in-month) (pos? day-in-month))
                       "gap oracle returned an invalid day-in-month"
                       {:day-in-month day-in-month})
    (let [cutlet (first matching-cutlets)
          month-name-index (nth month-name-indices (dec (int month-id)))
          date-components
          [(bigint (:number year))
           (bigint (:name-index cutlet))
           (inc (-' target-day (:first-day cutlet)))
           (bigint month-name-index)
           (bigint day-in-month)]]
      {:target-position target-position
       :first-day first-day
       :year (:number year)
       :cutlet-name-index (:name-index cutlet)
       :day-in-cutlet (nth date-components 2)
       :month-id (bigint month-id)
       :month-name-index (bigint month-name-index)
       :day-in-month (bigint day-in-month)
       :date-components date-components})))

(deftest discovery24-streaming-helpers-top-level-bound
  (doseq [helper [#'byte-chunks #'canonical-request-frame #'parse-rank-after-admission
             #'thrown-code #'streaming-parser-small-checks #'new-lru-cache #'cache-put! #'new-context]]
    (is (bound? helper) (str "Unbound streaming helper: " helper))))

(deftest discovery24-inplace-insertion-cross-check
  (println "DISCOVERY24_CLOJURE_INPLACE_BEGIN")
  (testing "the measured source-accounting function is pinned"
    (is (= "62f304dc013a9a9f70475bb0d34f186838b27318"
           (git-blob-sha (slurp "src/pastafari/maandrang.clj")))))
  (let [small (small-family-summary)
        canonical-input (canonical/write-canonical-input!)
        python (run-python-reference (:path canonical-input))
        frame (canonical-request-frame canonical-input 520)
        frame-bytes (.getBytes frame StandardCharsets/US_ASCII)
        chunks (byte-chunks frame-bytes alternative-chunk-limit-bytes)
        parser-checks (streaming-parser-small-checks)
        parsed (parse-streamed-frame chunks)
        certificate (alternative-admission-certificate (:profile parsed) (:p parsed))
        admission-limits {:scalar alternative-scalar-limit :bit alternative-bit-limit
                          :payload alternative-payload-limit}
        admission-status (alternative-admission-status
                          certificate (alength ^bytes (:rank-bytes parsed)) admission-limits)
        exact-cap-status (alternative-admission-status
                          certificate (alength ^bytes (:rank-bytes parsed))
                          {:scalar (:scalar certificate) :bit (:bit certificate) :payload (:payload certificate)})
        admission-accepted (ensure-invariant! (= :ADMIT_MODEL_ONLY admission-status)
                                              "Alternative C admission refused canonical p520"
                                              {:admission-status admission-status :certificate certificate})
        profile-accepted (ensure-invariant! (= (:profile parsed) (:profile canonical-input))
                                            "streamed profile differs from canonical profile"
                                            {:streamed-profile (:profile parsed)
                                             :canonical-profile (:profile canonical-input)})
        watchdog-start (System/nanoTime)
        heap-before (used-heap-bytes)
        watchdog {:start-nanos watchdog-start
                  :deadline-nanos (+ watchdog-start alternative-wall-limit-nanos)
                  :baseline-heap-bytes heap-before
                  :heap-delta-limit-bytes alternative-heap-delta-limit-bytes}
        ledger (new-arithmetic-ledger certificate)
        context (new-context {:ledger ledger :watchdog watchdog})
        rank (parse-rank-after-admission parsed certificate context)
        rank-accepted (ensure-invariant! (= rank (:rank canonical-input))
                                         "streamed decimal rank differs from canonical rank"
                                         {:streamed-rank-digits (count (str rank))
                                          :canonical-rank-digits (count (str (:rank canonical-input)))})
        actual (rank-trace-inplace (:profile parsed) rank (:p parsed) context)
        elapsed-ms (/ (- (System/nanoTime) watchdog-start) 1000000.0)
        heap-peak @(:peak-heap-bytes context)
        heap-delta (max 0 (- heap-peak heap-before))
        snapshots (:snapshots actual)
        p520 (get snapshots 520)
        gap-month-id (bigint (python-long python :GAP_P520_MONTH_ID))
        gap-day-in-month (bigint (python-long python :GAP_P520_DAY_IN_MONTH))
        gap-five-fields (normative-five-fields canonical-calculation-day
                                               canonical-calculation-day
                                               gap-month-id gap-day-in-month)
        inplace-five-fields (normative-five-fields canonical-calculation-day
                                                   canonical-calculation-day
                                                   (:month-id p520)
                                                   (:day-in-month p520))
        five-field-match? (= (:date-components gap-five-fields)
                             (:date-components inplace-five-fields))
        metric-snapshots
        (into {}
              (map (fn [position]
                     (let [snapshot (get snapshots position)]
                       [position
                        {:source-raming-cost (:source-raming-cost snapshot)
                         :alternative-dp-cell-writes (:dp-cell-writes snapshot)
                         :shared-group-cost (:python-shared-group-cost snapshot)}]))
                   [81 82 520]))
        report
        {:project-id "PC-BRANCH-CLOJURE-DUTCH"
         :branch "Clojure+Nederlands"
         :source-sha (System/getenv "GITHUB_SHA")
         :production-source-blob-sha "62f304dc013a9a9f70475bb0d34f186838b27318"
         :python-insertion-oracle-blob-sha "e3a5616acda7c1fd1853e9c6114049efa86d7bd3"
         :normative-oracle-blob-sha "5b2f486a12aeb8ff3cea0d762ba26882d67fb4cc"
         :canonical-input {:calculation-day canonical-calculation-day
                           :target-day canonical-calculation-day
                           :target-year (:year canonical-input)
                           :profile (:profile canonical-input)
                           :profile-months (count (:profile canonical-input))
                           :profile-days (reduce +' 0N (:profile canonical-input))
                           :weaving-total-digits (count (str (:total canonical-input)))
                           :weaving-rank-digits (count (str (:rank canonical-input)))
                           :search-budget 128N
                           :production-shared-group-ceiling 5000000N}
         :streaming-transport
         {:status :passed :frame-bytes (:frame-bytes parsed) :chunk-count (:chunk-count parsed)
          :max-chunk-bytes alternative-chunk-limit-bytes
          :rank-digits (alength ^bytes (:rank-bytes parsed))
          :rank-buffer-capacity (:rank-capacity parsed)
          :rank-decoded-after-admission? true :small-parser-checks parser-checks}
         :admission-certificate
         {:status admission-status :m (:m certificate) :n (:n certificate) :p (:p certificate)
          :B (:B certificate) :W (:W certificate) :Q (:Q certificate)
          :scalar (:scalar certificate) :chars (:chars certificate)
          :bit (:bit certificate) :payload (:payload certificate)
          :exact-cap-status exact-cap-status
          :live-payload-bound-type :analytical-upper-bound-not-measured}
         :arithmetic-ledger
         {:machine-semantics :jvm-clojure-bigint-java-math-biginteger
          :operations (assoc @(:ops ledger) :control (bigint @(:control-count ledger)))
          :scalar-primitives (+' @(:primitive-count ledger) (bigint @(:control-count ledger)))
          :scalar-limit alternative-scalar-limit
          :bit-work-upper-bound (+' @(:bit-work ledger) (*' 64N (bigint @(:control-count ledger))))
          :bit-work-limit alternative-bit-limit :word-bits (:word-bits ledger)
          :max-observed-word-bits @(:max-word-bits ledger)
          :live-payload-upper-bound-bits (:live-payload-upper-bound-bits ledger)
          :live-payload-limit-bits alternative-payload-limit
          :dp-cell-writes (:dp-cell-writes actual)
          :production-raming-diagnostic-included? false}
         :jvm-watchdog
         {:status :passed :elapsed-ms elapsed-ms :wall-limit-ms 90000
          :heap-baseline-bytes heap-before :heap-peak-used-bytes heap-peak
          :heap-delta-bytes heap-delta :heap-delta-limit-bytes alternative-heap-delta-limit-bytes
          :heap-sampled-every-dp-writes 256}
         :small-exhaustive {:profiles (:profiles small)
                            :legal-words (:legal-words small)
                            :rank-position-checks (:rank-position-checks small)
                            :exact-budget-accepts (:exact-budget-accepts small)
                            :budget-minus-one-refusals (:budget-minus-one-refusals small)
                            :source-accounting-non-equal (:source-accounting-non-equal small)
                            :digest (:digest small)}
         :p81 (get snapshots 81)
         :p82 (get snapshots 82)
         :p520 p520
         :cost-comparison metric-snapshots
         :cost-units {:source-raming-cost
                      "Cumulative sum of the pinned production raming() result for each candidate examined, including the root candidate; not the production shared-group bill."
                      :alternative-dp-cell-writes
                      "One unit per output-distribution array entry written by the test-only in-place DP; a separate work metric."
                      :shared-group-cost
                      "The active/new candidate-group charge schedule independently reproduced by the Python gap oracle; compare this metric with the existing 5000000 production ceiling."}
         :five-field-differential {:status (if five-field-match? :passed :mismatch)
                                   :method :normative-oracle-plus-independent-gap-convolution-prefix
                                   :target-position (:target-position gap-five-fields)
                                   :gap-oracle-date-components (:date-components gap-five-fields)
                                   :clojure-inplace-date-components (:date-components inplace-five-fields)}
         :full-month-weaving-materialized? false
         :production-date-api-invoked? false
         :stage2 :open
         :result :MODEL_ONLY_DIAGNOSTIC
         :successful-ci-test-required true}]
    (ensure-invariant! (= (:source-sha canonical-input) (System/getenv "GITHUB_SHA"))
                       "canonical input SHA does not match this checkout"
                       {:canonical-source-sha (:source-sha canonical-input)
                        :github-sha (System/getenv "GITHUB_SHA")})
    (ensure-invariant! five-field-match?
                       "p520 five-field differential mismatch"
                       {:gap-date (:date-components gap-five-fields)
                        :inplace-date (:date-components inplace-five-fields)})
    (ensure-invariant! (= :ADMIT_MODEL_ONLY exact-cap-status)
                       "exact resource caps did not admit" {:certificate certificate})
    (doseq [key [:scalar :bit :payload]]
      (let [below (alternative-admission-status
                   certificate (alength ^bytes (:rank-bytes parsed))
                   (assoc admission-limits key (dec (get certificate key))))]
        (ensure-invariant! (= :REFUSE_RESOURCE_BOUND below)
                           "resource cap minus one did not refuse"
                           {:resource key :status below :certificate certificate})))
    (ensure-invariant! (= 42860N (:B certificate)) "rank decimal capacity drift" {:certificate certificate})
    (ensure-invariant! (= 85722N (:W certificate)) "integer word width drift" {:certificate certificate})
    (ensure-invariant! (= 17128N (:Q certificate)) "candidate query bound drift" {:certificate certificate})
    (ensure-invariant! (= 548176392704N (:scalar certificate)) "scalar admission envelope drift" {:certificate certificate})
    (ensure-invariant! (= 64451838941170797954816N (:bit certificate)) "bit admission envelope drift" {:certificate certificate})
    (ensure-invariant! (= 987726308N (:payload certificate)) "payload admission envelope drift" {:certificate certificate})
    (ensure-invariant! (<= (+' @(:primitive-count ledger) (bigint @(:control-count ledger)))
                           alternative-scalar-limit)
                       "measured scalar primitive ledger exceeded cap"
                       {:observed (+' @(:primitive-count ledger) (bigint @(:control-count ledger)))
                        :limit alternative-scalar-limit})
    (ensure-invariant! (<= (+' @(:bit-work ledger) (*' 64N (bigint @(:control-count ledger))))
                           alternative-bit-limit)
                       "measured bit-work ledger exceeded cap"
                       {:observed (+' @(:bit-work ledger) (*' 64N (bigint @(:control-count ledger))))
                        :limit alternative-bit-limit})
    (ensure-invariant! (<= @(:max-word-bits ledger) (:W certificate))
                       "observed integer width exceeded W"
                       {:observed @(:max-word-bits ledger) :W (:W certificate)})
    (ensure-invariant! (<= heap-delta alternative-heap-delta-limit-bytes)
                       "JVM heap watchdog exceeded" {:heap-delta heap-delta})
    (ensure-invariant! (<= elapsed-ms 90000.0)
                       "JVM wall-clock watchdog exceeded" {:elapsed-ms elapsed-ms})
    (let [[counts opened closed] (:state actual)
          first-seen (vec (distinct (:prefix actual)))
          closed-last (mapv #(.lastIndexOf ^java.util.List (:prefix actual) %)
                            (range 1 (inc closed)))]
      (ensure-invariant! (= first-seen (vec (range 1 (inc (count first-seen)))))
                         "p520 prefix first-occurrence order mismatch" {:first-seen first-seen})
      (ensure-invariant! (every? true? (map < closed-last (rest closed-last)))
                         "p520 completed-month last-occurrence order mismatch" {:closed-last closed-last})
      (ensure-invariant! (and (<= closed opened (count counts))
                              (every? zero? (subvec counts 0 closed))
                              (every? pos? (subvec counts closed)))
                         "p520 insertion state grammar mismatch" {:state (:state actual)}))
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
      (is (= 4995675N (:shared-group-cost (get metric-snapshots 81))))
      (is (= 5002652N (:shared-group-cost (get metric-snapshots 82))))
      (is (= 5218257N (:shared-group-cost (get metric-snapshots 520))))
      (is (= 3507625N (:alternative-dp-cell-writes (get metric-snapshots 82))))
      (is (= 3713186N (:alternative-dp-cell-writes (get metric-snapshots 520))))
      (is (= 10N (:month-id p520)))
      (is (= 18N (:day-in-month p520)))
      (is (= "65c683810ee69f740e38334bbc67969d4ac429bc7d7943646a2a02aa14d8ae0b"
             (:prefix-sha256 p520)))
      (is (<= (:dp-cell-writes actual) alternative-write-limit)))
    (testing "independent normative five-field differential for canonical p520"
      (is (= 520N (:target-position gap-five-fields)))
      (is (= 5000N (first (:date-components gap-five-fields))))
      (is (= 5 (count (:date-components gap-five-fields))))
      (is (every? integer? (:date-components gap-five-fields)))
      (is (= (:date-components gap-five-fields)
             (:date-components inplace-five-fields))))
    (spit "qa/clojure-dutch/discovery24_inplace_five_field.edn"
          (str (pr-str report) "\n"))
    (spit "qa/clojure-dutch/discovery24_alternative_c_native.edn"
          (str (pr-str report) "\n"))
    (println "DISCOVERY24_CLOJURE_INPLACE_RESULT" (pr-str report))
    (println "DISCOVERY24_ALTERNATIVE_C_NATIVE_RESULT"
             (pr-str {:status :MODEL_ONLY_DIAGNOSTIC
                      :source-sha (:source-sha canonical-input)
                      :streaming (:streaming-transport report)
                      :admission (:admission-certificate report)
                      :ledger (:arithmetic-ledger report)
                      :watchdog (:jvm-watchdog report)
                      :five-fields (:five-field-differential report)}))))
