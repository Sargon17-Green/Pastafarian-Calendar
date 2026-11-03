(ns pastafari.stage02-end-to-end-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.doeljaar :as zoeken]
            [pastafari.datumprojectie :as projectie]
            [pastafari.normative-oracle :as orakel]))

;; DISCOVERY24: geen with-redefs. Beide berekeningen doorlopen de echte
;; selectie; de normatieve oracle blijft uitsluitend in de testomgeving.
(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private celbudget 100000N)

(defn- poging [lijn berekeningsdag doeldag budget]
  (try
    {:status :bewezen
     :resultaat (projectie/kies-bewezen-datum
                 lijn berekeningsdag doeldag 128N budget)}
    (catch clojure.lang.ExceptionInfo fout
      {:status :geweigerd :code (:code (ex-data fout))})))

(deftest echte-end-to-end-jaargrenzen-met-budgetpoort
  (testing "Geen stubs: jaar 4999/5000/5001, eerste/midden/laatste dag en twee rekendagen."
    (let [berekeningsdag dagen/stichtingsdag
          basis (zoeken/vind-doeljaar @lijn berekeningsdag berekeningsdag)
          vorig (zoeken/vind-doeljaar @lijn berekeningsdag (:open-gate-day basis))
          volgend (zoeken/vind-doeljaar @lijn berekeningsdag
                                           (inc (:close-gate-day basis)))
          midden (+' (:open-gate-day basis)
                     (quot (-' (:close-gate-day basis)
                               (:open-gate-day basis)) 2N))
          gevallen [[berekeningsdag (inc (:open-gate-day basis))]
                    [berekeningsdag midden]
                    [berekeningsdag (:close-gate-day basis)]
                    [berekeningsdag (:close-gate-day vorig)]
                    [berekeningsdag (inc (:open-gate-day volgend))]
                    [(+' berekeningsdag 17N) (+' berekeningsdag 17N)]
                    [(-' berekeningsdag 23N) (-' berekeningsdag 23N)]]
          getallen (atom {:bewezen 0 :geweigerd 0})]
      (is (= [4999N 5000N 5001N]
             (mapv :number [vorig basis volgend])))
      (doseq [[berekening doel] gevallen]
        (let [{:keys [status resultaat code]}
              (poging @lijn berekening doel celbudget)]
          (case status
            :bewezen
            (do
              (swap! getallen update :bewezen inc)
              (is (= 5 (count (:date-components resultaat))))
              (is (every? integer? (:date-components resultaat)))
              (is (<= (:month-weaving-cell-bound resultaat) celbudget))
              (is (= (orakel/calendar-date-canonical berekening doel)
                     (:date-components resultaat))))
            :geweigerd
            (do
              (swap! getallen update :geweigerd inc)
              (is (= :weaving-unrank-budget-unproven code))))))
      (println "DISCOVERY24 echte E2E:" @getallen "budget" celbudget)
      (is (= (count gevallen)
             (+ (:bewezen @getallen) (:geweigerd @getallen)))))))

(deftest budgetweigering-voor-de-dure-maandrang
  (testing "De productie weigert een onvoldoende budget op echte poortlijn."
    (let [berekening dagen/stichtingsdag
          uitkomst (poging @lijn berekening berekening 1N)]
      (is (= :geweigerd (:status uitkomst)))
      (is (= :weaving-unrank-budget-unproven (:code uitkomst))))))
