(ns pastafari.stage02-target-year-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.jaargrenzen :as jaren]
            [pastafari.doeljaar :as zoeken]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private verlengde-lijn
  (delay (-> (poorten/bouw-poortlijn 64N)
             (poorten/verleng-poortlijn 128N))))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest normatieve-doeljaren-in-drie-berekeningsdagen
  (testing "Onafhankelijke oracle-state en saus; jaar 5000, vooruit en achteruit."
    (doseq [verschuiving [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag verschuiving)
            staat (orakel/new-gate-state)
            basis (orakel/year5000 staat dag)
            volgende (orakel/next-year staat dag basis)
            vorige (orakel/previous-year staat dag basis)
            doelen [dag
                    (:close-gate-day volgende)
                    (:close-gate-day vorige)]]
        (doseq [doel doelen]
          (is (= (orakel/find-target-year (orakel/new-gate-state) dag doel)
                 (zoeken/vind-doeljaar @lijn dag doel)))
          (is (= (zoeken/vind-doeljaar @lijn dag doel)
                 (zoeken/vind-doeljaar @verlengde-lijn dag doel))))))))

(deftest grensdagen-van-open-en-sluitpoort
  (let [dag dagen/stichtingsdag
        basis (jaren/jaar5000 @lijn dag)
        vorige (jaren/vorig-jaar @lijn dag basis)
        volgende (jaren/volgend-jaar @lijn dag basis)
        openen (:open-gate-day basis)
        sluiten (:close-gate-day basis)]
    (is (= vorige (zoeken/vind-doeljaar @lijn dag openen)))
    (is (= basis (zoeken/vind-doeljaar @lijn dag (inc openen))))
    (is (= basis (zoeken/vind-doeljaar @lijn dag sluiten)))
    (is (= volgende (zoeken/vind-doeljaar @lijn dag (inc sluiten))))
    (is (= basis (zoeken/vind-doeljaar @lijn dag dag 0N)))
    (is (= 5000N (:number basis)))
    (is (= 4999N (:number vorige)))
    (is (= 5001N (:number volgende)))))

(deftest begrensd-stappenbudget-en-strikte-voortgang
  (let [dag dagen/stichtingsdag
        basis (jaren/jaar5000 @lijn dag)
        volgend (jaren/volgend-jaar @lijn dag basis)
        tweede (jaren/volgend-jaar @lijn dag volgend)
        eerste-doel (:close-gate-day volgend)
        tweede-doel (:close-gate-day tweede)]
    (is (= :year-step-budget-exhausted
           (foutcode #(zoeken/vind-doeljaar @lijn dag eerste-doel 0N))))
    (is (= volgend (zoeken/vind-doeljaar @lijn dag eerste-doel 1N)))
    (is (= :year-step-budget-exhausted
           (foutcode #(zoeken/vind-doeljaar @lijn dag tweede-doel 1N))))
    (is (= tweede (zoeken/vind-doeljaar @lijn dag tweede-doel 2N)))
    (is (= (orakel/find-target-year (orakel/new-gate-state) dag tweede-doel)
           (zoeken/vind-doeljaar @lijn dag tweede-doel)))
    (with-redefs [jaren/volgend-jaar (fn [_ _ jaar] jaar)]
      (is (= :year-search-nonprogress
             (foutcode #(zoeken/vind-doeljaar @lijn dag eerste-doel 1N)))))))

(deftest ongeldige-invoer-en-onbewezen-vensters
  (let [dag dagen/stichtingsdag
        groot (reduce *' 1N (repeat 101 10N))
        klein (poorten/bouw-poortlijn 1N)]
    (is (= :invalid-day
           (foutcode #(zoeken/vind-doeljaar @lijn 0.5 dag))))
    (is (= :invalid-day
           (foutcode #(zoeken/vind-doeljaar @lijn dag 0.5))))
    (is (= :invalid-day
           (foutcode #(zoeken/vind-doeljaar @lijn dag nil))))
    (doseq [budget [-1N 129N 1.5 nil]]
      (is (= :invalid-step-budget
             (foutcode #(zoeken/vind-doeljaar @lijn dag dag budget)))))
    (is (= :invalid-gate-line
           (foutcode #(zoeken/vind-doeljaar nil dag dag))))
    (is (= :year-window-unproven
           (foutcode #(zoeken/vind-doeljaar klein dag dag))))
    (is (= :year-window-unproven
           (foutcode #(zoeken/vind-doeljaar @lijn dag (+' dag groot)))))
    (is (= :year-window-unproven
           (foutcode #(zoeken/vind-doeljaar @lijn dag (-' dag groot)))))))