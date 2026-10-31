(ns pastafari.stage02-cutlet-partition-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.jaargrenzen :as jaren]
            [pastafari.koteletaantal :as koteletten]
            [pastafari.koteletverdeling :as verdeling]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.poortposities :as poorten]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private verlengde-lijn
  (delay (poorten/verleng-poortlijn (poorten/bouw-poortlijn 64N) 128N)))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- somdelingen [ruimte vakken]
  ;; Test-only expliciete opsomming, niet de binomiale productieroute.
  (cond
    (zero? vakken) (if (zero? ruimte) [[]] [])
    (< ruimte vakken) []
    :else
    (vec (mapcat
          (fn [x]
            (map (fn [staart] (into [x] staart))
                 (somdelingen (- ruimte x) (dec vakken))))
          (range 1 (inc (- ruimte (dec vakken))))))))

(defn- bevat-grens? [delen grens]
  (or (nil? grens)
      (contains? (set (rest (butlast (reductions +' 0N delen)))) grens)))

(deftest lexicografische-composities-uitputtend
  (testing "Eigen brute-force enumeratie bevestigt getal en iedere rang."
    (doseq [p (range 6 11)
            k (range 6 (inc (min 8 p)))
            grens (distinct [nil 1 (quot p 2) (dec p)])]
      (let [kandidaten (->> (somdelingen p k)
                            (filter #(bevat-grens? % grens))
                            vec)]
        (is (= (bigint (count kandidaten))
               (verdeling/aantal-verdelingen p k grens)))
        (doseq [[i kandidaat] (map-indexed vector kandidaten)]
          (is (= kandidaat
                 (verdeling/verdeling-op-rang p k grens (inc i)))))))))

(deftest onafhankelijke-norm-voor-doeljaren
  (testing "Drie rekenmomenten, vorig/doeljaar/volgend; norm bouwt eigen poorten."
    (doseq [verschuiving [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag verschuiving)
            staat (orakel/new-gate-state)
            basis (orakel/year5000 staat dag)
            vorig (orakel/previous-year staat dag basis)
            volgend (orakel/next-year staat dag basis)]
        (doseq [doel [(:close-gate-day vorig) dag (:close-gate-day volgend)]]
          (let [normstaat (orakel/new-gate-state)
                jaar (orakel/find-target-year normstaat dag doel)
                saus (orakel/sauce dag (inc (:open-gate-day jaar)))
                aantal (orakel/choose-cutlet-count saus jaar)
                partitie (orakel/choose-cutlet-partition normstaat dag saus jaar aantal)
                direct (verdeling/kies-verdeling @lijn dag doel)
                verlengd (verdeling/kies-verdeling @verlengde-lijn dag doel)]
            (is (= jaar (:year direct)))
            (is (= aantal (:cutlet-count direct)))
            (is (= partitie (:partition direct)))
            (is (= (count partitie) (:cutlet-count direct)))
            (is (= (-' (:close-gate-index jaar) (:open-gate-index jaar))
                   (reduce +' 0N (:partition direct))))
            (is (= direct verlengd))))))))

(deftest interne-grens-en-zegel
  (let [dag dagen/stichtingsdag
        jaar (jaren/jaar5000 @lijn dag)
        interne-index (inc (:open-gate-index jaar))
        interne-dag (poorten/poortdag @lijn interne-index)
        gezien (atom [])
        rangpositie (atom :eerste)]
    (with-redefs [koteletten/kies-aantal
                  (fn [_ _ _ _] {:year jaar :cutlet-count 6N})
                  keuzes/vraag-kom
                  (fn [_ kom zegel]
                    (swap! gezien conj [kom zegel])
                    {:first 1N :direction-step 1N})
                  keuzes/kies-rang
                  (fn [_ totaal] (if (= @rangpositie :eerste) 1N totaal))]
      (let [a (verdeling/kies-verdeling @lijn interne-dag dag 0N)]
        (is (= 1N (:required-boundary a)))
        (is (= 1N (first (:partition a))))
        (is (= [2N 21N] (first @gezien))))
      (reset! rangpositie :laatste)
      (let [b (verdeling/kies-verdeling @lijn (dec interne-dag) dag 0N)]
        (is (nil? (:required-boundary b)))
        (is (= (verdeling/verdeling-op-rang
                (-' (:close-gate-index jaar) (:open-gate-index jaar))
                6N nil (:partition-count b))
               (:partition b))))
      (is (= [[2N 21N] [2N 21N]] @gezien)))))

(deftest grenzen-bereik-en-fouten
  (let [groot (reduce *' 1N (repeat 101 10N))
        n (verdeling/aantal-verdelingen 256N 17N 128N)
        p (verdeling/verdeling-op-rang 256N 17N 128N n)]
    (is (pos? n))
    (is (= 17 (count p)))
    (is (= 256N (reduce +' 0N p)))
    (is (bevat-grens? p 128N))
    (is (= :no-cutlet-candidates
           (foutcode #(verdeling/aantal-verdelingen 5N 6N nil))))
    (doseq [g [-1N 257N 2.5 nil groot]]
      (is (= :invalid-gate-gap-count
             (foutcode #(verdeling/aantal-verdelingen g 6N nil)))))
    (doseq [k [0N 5N 18N 2.5 nil]]
      (is (= :invalid-cutlet-count
             (foutcode #(verdeling/aantal-verdelingen 10N k nil)))))
    (doseq [b [0N 10N -1N 2.5 groot]]
      (is (= :invalid-required-boundary
             (foutcode #(verdeling/aantal-verdelingen 10N 6N b)))))
    (doseq [r [0N -1N 2.5 nil (inc n)]]
      (is (= :invalid-cutlet-partition-rank
             (foutcode #(verdeling/verdeling-op-rang 256N 17N 128N r)))))))

(deftest begindag-en-dekkingsbudget
  (let [dag dagen/stichtingsdag
        jaar (jaren/jaar5000 @lijn dag)
        eerste (inc (:open-gate-day jaar))
        laatste (:close-gate-day jaar)
        a (verdeling/kies-verdeling @lijn dag eerste 0N)
        b (verdeling/kies-verdeling @lijn dag laatste 0N)]
    (is (= a b))
    (is (= 5000N (get-in a [:year :number])))
    (is (= :year-step-budget-exhausted
           (foutcode #(verdeling/kies-verdeling
                       @lijn dag (:open-gate-day jaar) 0N))))
    (is (= :invalid-day
           (foutcode #(verdeling/kies-verdeling @lijn dag 2.5))))
    (is (= :invalid-step-budget
           (foutcode #(verdeling/kies-verdeling @lijn dag dag 129N))))
    (is (= :invalid-gate-line
           (foutcode #(verdeling/kies-verdeling nil dag dag))))
    (is (= :year-window-unproven
           (foutcode #(verdeling/kies-verdeling @lijn dag (+' dag (reduce *' 1N (repeat 101 10N)))))))))
