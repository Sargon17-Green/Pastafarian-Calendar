(ns pastafari.stage02-month-weaving-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.maandweving :as weving]
            [pastafari.maandlengtes :as lengtes]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- alle-woorden [resterend]
  ;; Exhaustieve testoracle: alle multisetwoorden, zonder productie-pruning.
  (if (every? zero? resterend)
    '(())
    (mapcat
      (fn [index]
        (when (pos? (nth resterend index))
          (map #(cons (inc index) %)
               (alle-woorden (update resterend index dec)))))
      (range (count resterend)))))

(defn- juiste-volgorde? [woord n]
  (let [posities (reduce-kv
                   (fn [acc i maand] (update acc maand (fnil conj []) i))
                   {} (vec woord))
        ids (range 1 (inc n))]
    (and (apply < (map #(first (get posities %)) ids))
         (apply < (map #(last (get posities %)) ids)))))

(defn- brute-familie [lengtes]
  (->> (alle-woorden (vec lengtes))
       (filter #(juiste-volgorde? % (count lengtes)))
       (mapv vec)))

(defn- binomiaal [n k]
  (quot (reduce *' 1N (range (inc (- n k)) (inc n)))
        (reduce *' 1N (range 1 (inc k)))))

(deftest uitputtende-kleine-families
  (testing "Zelfstandige enumeratie en lexicografische reconstructie."
    (doseq [lengtes [[4] [5] [4 4] [4 5] [5 4] [5 5]
                     [4 6] [6 4] [4 4 4] [4 4 5]]]
      (let [verwacht (brute-familie lengtes)
            n (weving/aantal-wevingen lengtes)]
        (is (= (bigint (count verwacht)) n))
        (doseq [[i woord] (map-indexed vector verwacht)]
          (is (= woord (weving/weving-op-rang lengtes (inc i)))))))))

(deftest combinatorische-randgevallen
  (doseq [[a b] [[4 4] [4 9] [9 4] [14 12]]]
    (let [n (weving/aantal-wevingen [a b])]
      (is (= (binomiaal (- (+ a b) 2) (dec a)) n))
      (is (= (+ a b) (count (weving/weving-op-rang [a b] n))))
      (is (= [1 2] [(first (weving/weving-op-rang [a b] 1N))
                    (last (weving/weving-op-rang [a b] n))]))))
  (let [lengtes [4 4 4 4 4]
        n (weving/aantal-wevingen lengtes)
        eerste (weving/weving-op-rang lengtes 1N)
        laatste (weving/weving-op-rang lengtes n)]
    (is (= 41385102N n))
    (is (= 20 (count eerste)))
    (is (= 20 (count laatste)))
    (is (= [4 4 4 4 4]
           (mapv #(count (filter (fn [x] (= % x)) eerste)) (range 1 6))))
    (is (= (vec (mapcat #(repeat 4 %) (range 1 6))) eerste))
    (is (not= eerste laatste))))

(deftest kom-vier-zegel-tweeendertig
  (let [gezien (atom [])
        laatste? (atom false)
        basis {:year {:open-gate-day 0N :close-gate-day 8N}
               :month-count 2 :month-lengths [4 4]
               :month-length-family-count 1N :cutlets []}]
    (with-redefs [lengtes/kies-maandlengtes (fn [_ _ _ _] basis)
                  verdelingen/structuur-saus (fn [_ _] {:test true})
                  keuzes/vraag-kom (fn [_ kom zegel]
                                     (swap! gezien conj [kom zegel])
                                     {:first 1N :direction-step 1N})
                  keuzes/kies-rang (fn [_ n] (if @laatste? n 1N))]
      (let [eerste (weving/kies-maandweving nil 0N 0N 0N)]
        (is (= basis (dissoc eerste :month-weaving :month-weaving-family-count)))
        (is (= 20N (:month-weaving-family-count eerste)))
        (is (= [1 1 1 1 2 2 2 2] (:month-weaving eerste))))
      (reset! laatste? true)
      (is (= [1 2 2 2 1 1 1 2]
             (:month-weaving (weving/kies-maandweving nil 0N 0N 0N))))
      (is (= [[4N 32N] [4N 32N]] @gezien)))))

(deftest foutcodes-en-grenzen
  (doseq [lengtes [nil [] [3] [124] [4 0] [4 2.5] "444"]]
    (is (= :invalid-weaving-family
           (foutcode #(weving/aantal-wevingen lengtes)))))
  (doseq [lengtes [(vec (repeat 6 4)) [123]]]
    (is (= :weaving-bound-exceeded
           (foutcode #(weving/aantal-wevingen lengtes)))))
  (is (pos? (weving/aantal-wevingen [4 4 4 4 13])))
  (let [n (weving/aantal-wevingen [4 4])]
    (doseq [rang [nil 0N -1N 2.5 (inc n)]]
      (is (= :invalid-weaving-rank
             (foutcode #(weving/weving-op-rang [4 4] rang)))))))
