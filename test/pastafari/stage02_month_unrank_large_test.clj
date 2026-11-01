(ns pastafari.stage02-month-unrank-large-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.maandrang :as rang]
            [pastafari.maandweving :as weving]))

(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

;; Onafhankelijke permutatie-enumeratie zonder productiepruning.
(defn- alle-woorden [restvector]
  (if (every? zero? restvector)
    '(())
    (mapcat (fn [i]
              (when (pos? (nth restvector i))
                (map #(cons (inc i) %)
                     (alle-woorden (update restvector i dec)))))
            (range (count restvector)))))

(defn- juist? [woord n]
  (let [v (vec woord)
        ids (range 1 (inc n))]
    (and (apply < (map #(.indexOf v %) ids))
         (apply < (map #(.lastIndexOf v %) ids)))))

(defn- brute-lex [lengtes]
  (->> (alle-woorden (vec lengtes))
       (filter #(juist? % (count lengtes)))
       (map vec) sort vec))

(defn- geldig-woord? [lengtes woord]
  (and (= (reduce + lengtes) (count woord))
       (= (vec lengtes)
          (mapv #(count (filter (fn [x] (= x %)) woord))
                (range 1 (inc (count lengtes)))))
       (juist? woord (count lengtes))))

(deftest lex-rangen-met-onafhankelijk-orakel
  (testing "Alle kleine tweemaandsrangen en extreme drie-maandsrangen."
    (doseq [lengtes [[4] [4 4] [4 5] [4 4 4] [4 4 5]]]
      (let [woorden (brute-lex lengtes)
            indices (if (<= (count woorden) 40)
                      (range (count woorden))
                      (distinct [0 1 2 17 (quot (count woorden) 2)
                                 (dec (count woorden))]))]
        (is (= (bigint (count woorden))
               (weving/aantal-wevingen-groot lengtes)))
        (doseq [i indices]
          (is (= (nth woorden i)
                 (rang/weving-op-rang-groot lengtes (inc i)))
              (str lengtes " rang " (inc i))))))))

(deftest grotere-families
  (doseq [lengtes [(vec (repeat 6 4))
                   (vec (repeat 8 4))
                   [4 9 6 8 4 4]]]
    (let [totaal (weving/aantal-wevingen-groot lengtes)
          eerste (rang/weving-op-rang-groot lengtes 1N)
          midden (rang/weving-op-rang-groot lengtes
                                            (inc (quot totaal 2N)))
          laatste (rang/weving-op-rang-groot lengtes totaal)]
      (is (= (vec (mapcat (fn [id n] (repeat n id))
                            (range 1 (inc (count lengtes)))
                            lengtes))
             eerste))
      (is (every? #(geldig-woord? lengtes %) [eerste midden laatste]))
      (is (= 3 (count (distinct [eerste midden laatste])))))))

(deftest fouten-en-bestaande-grens
  (doseq [lengtes [nil [] [3] [124] [4 0] [4 2.5] "444"]]
    (is (= :invalid-weaving-family
           (foutcode #(rang/weving-op-rang-groot lengtes 1N)))))
  (doseq [lengtes [(vec (repeat 48 4))
                   (vec (repeat 47 123))]]
    (is (= :weaving-bound-exceeded
           (foutcode #(rang/weving-op-rang-groot lengtes 1N)))))
  (let [total (weving/aantal-wevingen-groot [4 4])]
    (doseq [r [nil 0N -1N 1.5 (inc total)]]
      (is (= :invalid-weaving-rank
             (foutcode #(rang/weving-op-rang-groot [4 4] r))))))
  (doseq [budget [nil 0 -1 2.5 5000001N]]
    (is (= :invalid-weaving-budget
           (foutcode #(rang/weving-op-rang-groot [4 4] 1N budget)))))
  (is (= :weaving-unrank-budget-exceeded
         (foutcode #(rang/weving-op-rang-groot [4 4 4] 1N 1N))))
  (is (= :weaving-bound-exceeded
         (foutcode #(weving/weving-op-rang (vec (repeat 6 4)) 1N)))))
