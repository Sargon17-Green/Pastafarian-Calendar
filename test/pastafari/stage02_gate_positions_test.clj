(ns pastafari.stage02-gate-positions-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as posities]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn8 (delay (posities/bouw-poortlijn 8N)))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

;; Tweede pad: telkens een zelfstandige som van normatieve afstanden,
;; zonder de productievector of binaire zoekmethode te hergebruiken.
(defn- referentiedag [k]
  (let [stichting orakel/foundation-day
        aantal (if (neg? k) (- k) k)]
    (if (neg? k)
      (reduce -' stichting
              (map orakel/negative-gate-gap (range 1 (inc aantal))))
      (reduce +' stichting
              (map orakel/positive-gate-gap (range 1 (inc aantal)))))))

(deftest onafhankelijk-anker-en-indexen
  (testing "17 exacte posities, inclusief twee richtingen en nulpunt."
    (let [lijn @lijn8]
      (is (= dagen/stichtingsdag (posities/poortdag lijn 0N)))
      (doseq [k (range -8 9)]
        (is (= (referentiedag k) (posities/poortdag lijn k)))
        (is (integer? (posities/poortdag lijn k)))))))

(deftest strikte-monotonie-en-gaten
  (let [lijn @lijn8
        dagen (:dagen lijn)]
    (is (= 17 (count dagen)))
    (doseq [[a b] (partition 2 1 dagen)]
      (is (< a b))
      (is (<= 42N (-' b a) 963N)))))

(deftest zoeken-met-grensgevallen
  (let [lijn @lijn8]
    (testing "Exacte poort en laatste dag voor de volgende poort."
      (doseq [k (range -8 9)]
        (let [dag (referentiedag k)]
          (is (= {:index k :day dag}
                 (posities/poort-op-of-voor lijn dag)))))
      (doseq [k (range -8 8)]
        (let [dag (referentiedag k)
              volgende (referentiedag (inc k))]
          (is (= {:index k :day dag}
                 (posities/poort-op-of-voor lijn (dec volgende))))
          (is (= {:index k :day dag}
                 (posities/poort-op-of-voor lijn (inc dag)))))))
    (testing "Grote exacte BigInt-dag buiten eindig venster."
      (let [groot (reduce *' 1N (repeat 101 10N))]
        (is (= :day-outside-gate-window
               (foutcode #(posities/poort-op-of-voor lijn groot))))
        (is (= :day-outside-gate-window
               (foutcode #(posities/poort-op-of-voor lijn (-' groot)))))))))

(deftest eenpuntsvenster-en-afwijzingen
  (let [nul (posities/bouw-poortlijn 0N)
        dag dagen/stichtingsdag
        groot (reduce *' 1N (repeat 101 10N))]
    (is (= [dag] (:dagen nul)))
    (is (= {:index 0N :day dag}
           (posities/poort-op-of-voor nul dag)))
    (is (= :invalid-gate-radius
           (foutcode #(posities/bouw-poortlijn -1N))))
    (is (= :invalid-gate-radius
           (foutcode #(posities/bouw-poortlijn 1.5))))
    (is (= :invalid-gate-radius
           (foutcode #(posities/bouw-poortlijn groot))))
    (is (= :gate-index-outside-window
           (foutcode #(posities/poortdag nul 1N))))
    (is (= :gate-index-outside-window
           (foutcode #(posities/poortdag @lijn8 groot))))
    (is (= :invalid-day
           (foutcode #(posities/poort-op-of-voor nul 1.5))))
    (is (= :invalid-gate-line
           (foutcode #(posities/poortdag nil 0N))))
    (is (= :day-outside-gate-window
           (foutcode #(posities/poort-op-of-voor nul (inc dag)))))))