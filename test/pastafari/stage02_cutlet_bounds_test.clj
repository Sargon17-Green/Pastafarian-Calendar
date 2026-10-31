(ns pastafari.stage02-cutlet-bounds-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.koteletgrenzen :as grenzen]
            [pastafari.koteletnamen :as namen]
            [pastafari.poortposities :as poorten]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private verlengd
  (delay (poorten/verleng-poortlijn (poorten/bouw-poortlijn 64N) 128N)))
(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- composities [ruimte aantal]
  ;; Onafhankelijke brute-force testgenerator.
  (cond
    (zero? aantal) (if (zero? ruimte) [[]] [])
    (< ruimte aantal) []
    :else (mapcat
           (fn [x] (map (fn [rest] (into [x] rest))
                        (composities (- ruimte x) (dec aantal))))
           (range 1 (inc (- ruimte (dec aantal)))))))

(def ^:private kleine-lijn
  {:straal 8N
   :dagen (mapv (fn [i] (+' dagen/stichtingsdag (*' i 50N))) (range -8 9))})

(defn- basis [partitie]
  (let [open -4N
        close (+' open (reduce +' 0N partitie))]
    {:year {:number 5000N
            :open-gate-index open :close-gate-index close
            :open-gate-day (+' dagen/stichtingsdag (*' open 50N))
            :close-gate-day (+' dagen/stichtingsdag (*' close 50N))}
     :cutlet-count (count partitie) :partition (vec partitie)
     :partition-count 1N :required-boundary nil
     :name-indices (vec (take (count partitie) (range 17 0 -1)))
     :name-family-count 1N}))

(deftest uitputtende-kleine-partities
  (testing "Alle positieve composities tot negen poortgaten vs onafhankelijk orakel."
    (let [staat (atom {:gates (into {} (map vector (range -8 9)
                                          (:dagen kleine-lijn)))})]
      (doseq [gaten (range 6 10)
              aantal (range 6 (inc (min 8 gaten)))
              partitie (composities gaten aantal)]
        (let [invoer (basis partitie)
              uit (grenzen/materialiseer-koteletten kleine-lijn invoer)
              delen (:cutlets uit)
              norm (orakel/materialize-cutlets staat (:year invoer)
                                               partitie (:name-indices invoer))]
          (is (= norm delen))
          (is (= invoer (dissoc uit :cutlets)))
          (is (= (count partitie) (count delen)))
          (is (= (inc (get-in invoer [:year :open-gate-day]))
                 (:first-day (first delen))))
          (is (= (get-in invoer [:year :close-gate-day])
                 (:last-day (peek delen))))
          (is (every? (fn [[a b]]
                        (= (inc (:last-day a)) (:first-day b)))
                      (partition 2 1 delen))))))))

(deftest verplichte-grens-en-fouten
  (let [invoer (assoc (basis [1N 2N 1N 1N 1N 2N])
                      :required-boundary 3N)
        delen (:cutlets (grenzen/materialiseer-koteletten kleine-lijn invoer))]
    (is (= -1N (:close-gate-index (second delen))))
    (is (= (poorten/poortdag kleine-lijn -1N)
           (:last-day (second delen))))
    (is (= :invalid-cutlet-required-boundary
           (foutcode #(grenzen/materialiseer-koteletten
                       kleine-lijn (assoc invoer :required-boundary 7N)))))
    (is (= :invalid-cutlet-materialization
           (foutcode #(grenzen/materialiseer-koteletten
                       kleine-lijn (assoc invoer :partition [1N 1N 1N 1N 1N 1N])))))
    (is (= :invalid-cutlet-name-indices
           (foutcode #(grenzen/materialiseer-koteletten
                       kleine-lijn (assoc invoer :name-indices [1N 1N 2N 3N 4N 5N])))))
    (is (= :invalid-cutlet-name-indices
           (foutcode #(grenzen/materialiseer-koteletten
                       kleine-lijn (assoc invoer :name-indices [1N 2N 3N 4N 5N 18N])))))
    (is (= :invalid-proven-year
           (foutcode #(grenzen/materialiseer-koteletten
                       kleine-lijn (assoc-in invoer [:year :close-gate-day] 0N)))))
    (is (= :gate-index-outside-window
           (foutcode #(grenzen/materialiseer-koteletten kleine-lijn
                       (assoc invoer :year
                         (assoc (:year invoer)
                           :open-gate-index 3N :close-gate-index 11N
                           :open-gate-day (poorten/poortdag kleine-lijn 3N)))))))
    (is (= :invalid-gate-line
           (foutcode #(grenzen/materialiseer-koteletten nil invoer))))))

(deftest normatieve-jaren-en-verlenging
  (testing "Onafhankelijke jaarnorm en 3x3 vorige/huidige/volgende doeljaren."
    (doseq [offset [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag offset)
            staat (orakel/new-gate-state)
            midden (orakel/year5000 staat dag)
            vorig (orakel/previous-year staat dag midden)
            volgend (orakel/next-year staat dag midden)]
        (doseq [doel [(:close-gate-day vorig) dag (:close-gate-day volgend)]]
          (let [normstaat (orakel/new-gate-state)
                jaar (orakel/find-target-year normstaat dag doel)
                saus (orakel/sauce dag (inc (:open-gate-day jaar)))
                aantal (orakel/choose-cutlet-count saus jaar)
                partitie (orakel/choose-cutlet-partition normstaat dag saus jaar aantal)
                naamindices (orakel/choose-cutlet-names saus aantal)
                norm (orakel/materialize-cutlets normstaat jaar partitie naamindices)
                direct (grenzen/kies-koteletten @lijn dag doel)
                uitgerekt (grenzen/kies-koteletten @verlengd dag doel)]
            (is (= jaar (:year direct)))
            (is (= partitie (:partition direct)))
            (is (= naamindices (:name-indices direct)))
            (is (= norm (:cutlets direct)))
            (is (= direct uitgerekt))))))))

(deftest geerfde-foutcodes
  (let [dag dagen/stichtingsdag
        groot (reduce *' 1N (repeat 101 10N))]
    (is (= :invalid-gate-line
           (foutcode #(grenzen/kies-koteletten nil dag dag))))
    (is (= :invalid-day
           (foutcode #(grenzen/kies-koteletten @lijn dag 2.5))))
    (is (= :invalid-step-budget
           (foutcode #(grenzen/kies-koteletten @lijn dag dag 129N))))
    (is (= :year-window-unproven
           (foutcode #(grenzen/kies-koteletten @lijn dag (+' dag groot)))))
    (is (= :invalid-cutlet-materialization
           (foutcode #(grenzen/materialiseer-koteletten kleine-lijn nil))))
    (is (= (:year (namen/kies-namen @lijn dag dag))
           (:year (grenzen/kies-koteletten @lijn dag dag))))))
