(ns pastafari.stage02-year-boundaries-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.jaargrenzen :as jaren]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private langere-lijn
  (delay (-> (poorten/bouw-poortlijn 64N)
             (poorten/verleng-poortlijn 128N))))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest normatieve-jaar5000-ankers
  (testing "Drie berekeningsdagen; het oracle bouwt eigen poorten en eigen saus."
    (doseq [verschuiving [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag verschuiving)
            verwachte (orakel/year5000 (orakel/new-gate-state) dag)
            gevonden (jaren/jaar5000 @lijn dag)
            kandidaten (jaren/jaar5000-kandidaten @lijn dag)]
        (is (= verwachte gevonden))
        (is (seq kandidaten))
        (is (= (count kandidaten) (count (distinct kandidaten))))
        (is (every? #(and (<= 252N (:length %) 5778N)
                          (< (:open-day %) dag)
                          (<= dag (poorten/poortdag @lijn (:close-index %)))
                          (>= (-' (:close-index %) (:open-index %)) 6N))
                    kandidaten))
        (is (= (sort-by (juxt :length :open-day) kandidaten) kandidaten))))))

(deftest normatieve-opeenvolgende-jaren
  (testing "Voorwaarts en achterwaarts met afzonderlijke oracle-state."
    (let [dag dagen/stichtingsdag
          referentie (orakel/new-gate-state)
          basis (orakel/year5000 referentie dag)
          huidig (jaren/jaar5000 @lijn dag)
          na (jaren/volgend-jaar @lijn dag huidig)
          voor (jaren/vorig-jaar @lijn dag huidig)]
      (is (= basis huidig))
      (is (= (orakel/next-year referentie dag basis) na))
      (is (= (orakel/previous-year referentie dag basis) voor))
      (is (= (:close-gate-index huidig) (:open-gate-index na)))
      (is (= (:open-gate-index huidig) (:close-gate-index voor)))
      (is (= 5001N (:number na)))
      (is (= 4999N (:number voor)))
      (is (= huidig (jaren/jaar5000 @langere-lijn dag))))))

(deftest bewijsgrenzen-en-foutcodes
  (let [dag dagen/stichtingsdag
        klein (poorten/bouw-poortlijn 1N)
        jaar (jaren/jaar5000 @lijn dag)
        groot (reduce *' 1N (repeat 101 10N))]
    (is (= :invalid-day (foutcode #(jaren/jaar5000 @lijn 0.5))))
    (is (= :year-window-unproven (foutcode #(jaren/jaar5000 klein dag))))
    (is (= :year-window-unproven (foutcode #(jaren/jaar5000 @lijn (+' dag groot)))))
    (is (= :year-window-unproven (foutcode #(jaren/jaar5000 @lijn (-' dag groot)))))
    (is (= :invalid-gate-line (foutcode #(jaren/jaar5000 nil dag))))
    (is (= :invalid-known-year
           (foutcode #(jaren/volgend-jaar @lijn dag (assoc jaar :close-gate-day 0N)))))
    (is (= :invalid-known-year
           (foutcode #(jaren/vorig-jaar @lijn dag (assoc jaar :open-gate-index 129N)))))
    (is (= :invalid-day (foutcode #(jaren/volgend-jaar @lijn 2.5 jaar))))
    (is (= :invalid-day (foutcode #(jaren/vorig-jaar @lijn 2.5 jaar))))))