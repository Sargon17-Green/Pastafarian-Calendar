(ns pastafari.stage02-cutlet-count-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.doeljaar :as doeljaar]
            [pastafari.jaargrenzen :as jaren]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.koteletaantal :as koteletten]
            [pastafari.poortposities :as poorten]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private uitgebreide-lijn
  (delay (poorten/verleng-poortlijn (poorten/bouw-poortlijn 64N) 128N)))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest onafhankelijk-orakel-voor-drie-jaren
  (testing "Oracle bouwt eigen poorten, doeljaar en saus zonder productie-import."
    (doseq [verschuiving [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag verschuiving)
            staat (orakel/new-gate-state)
            basis (orakel/year5000 staat dag)
            volgend (orakel/next-year staat dag basis)
            vorig (orakel/previous-year staat dag basis)]
        (doseq [doel [(:close-gate-day vorig)
                      dag
                      (:close-gate-day volgend)]]
          (let [normjaar (orakel/find-target-year (orakel/new-gate-state) dag doel)
                normsaus (orakel/sauce dag (inc (:open-gate-day normjaar)))
                normaantal (orakel/choose-cutlet-count normsaus normjaar)
                direct (koteletten/kies-aantal @lijn dag doel)
                uitgebreid (koteletten/kies-aantal @uitgebreide-lijn dag doel)
                gaten (-' (:close-gate-index normjaar)
                          (:open-gate-index normjaar))]
            (is (= normjaar (:year direct)))
            (is (= normaantal (:cutlet-count direct)))
            (is (<= 6N (:cutlet-count direct) (min 17N gaten)))
            (is (= (count (koteletten/kandidaat-aantallen gaten))
                   (:candidate-count direct)))
            (is (= direct uitgebreid))))))))

(deftest doeljaargrenzen-en-nulbudget
  (let [dag dagen/stichtingsdag
        jaar (jaren/jaar5000 @lijn dag)
        eerste (inc (:open-gate-day jaar))
        laatste (:close-gate-day jaar)
        links (:open-gate-day jaar)
        a (koteletten/kies-aantal @lijn dag eerste 0N)
        b (koteletten/kies-aantal @lijn dag laatste 0N)]
    (is (= a b))
    (is (= 5000N (get-in a [:year :number])))
    (is (= 4999N (get-in (koteletten/kies-aantal @lijn dag links)
                        [:year :number])))
    (is (= :year-step-budget-exhausted
           (foutcode #(koteletten/kies-aantal @lijn dag links 0N))))))

(deftest kandidaatvolgorde-en-foutgrenzen
  (is (= [6] (koteletten/kandidaat-aantallen 6N)))
  (is (= (vec (range 6 18)) (koteletten/kandidaat-aantallen 17N)))
  (is (= (vec (range 6 18)) (koteletten/kandidaat-aantallen 256N)))
  (doseq [gaten [0N 5N]]
    (is (= :no-cutlet-candidates
           (foutcode #(koteletten/kandidaat-aantallen gaten)))))
  (doseq [gaten [-1N 257N 2.5 nil (reduce *' 1N (repeat 101 10N))]]
    (is (= :invalid-gate-gap-count
           (foutcode #(koteletten/kandidaat-aantallen gaten))))))

(deftest zegel-kom-en-rangpositie
  (let [dag dagen/stichtingsdag
        jaar (jaren/jaar5000 @lijn dag)
        gaten (-' (:close-gate-index jaar) (:open-gate-index jaar))
        laatste (min 17N gaten)
        gezien (atom [])
        positie (atom :eerste)]
    (with-redefs [doeljaar/vind-doeljaar (fn [_ _ _ _] jaar)
                  keuzes/vraag-kom (fn [_ kom zegel]
                                     (swap! gezien conj [kom zegel])
                                     {:first 1N :direction-step 1N})
                  keuzes/kies-rang (fn [_ grootte]
                                     (if (= @positie :eerste) 1N grootte))]
      (is (= 6 (int (:cutlet-count (koteletten/kies-aantal @lijn dag dag 0N)))))
      (reset! positie :laatste)
      (is (= laatste (:cutlet-count (koteletten/kies-aantal @lijn dag dag 0N))))
      (is (= [[2N 20N] [2N 20N]] @gezien)))))

(deftest ongeldige-invoer-en-begrensde-dekking
  (let [dag dagen/stichtingsdag
        klein (poorten/bouw-poortlijn 1N)
        groot (reduce *' 1N (repeat 101 10N))]
    (doseq [budget [-1N 129N 1.5 nil]]
      (is (= :invalid-step-budget
             (foutcode #(koteletten/kies-aantal @lijn dag dag budget)))))
    (is (= :invalid-day
           (foutcode #(koteletten/kies-aantal @lijn dag 1.5))))
    (is (= :invalid-day
           (foutcode #(koteletten/kies-aantal @lijn nil dag))))
    (is (= :invalid-gate-line
           (foutcode #(koteletten/kies-aantal nil dag dag))))
    (is (= :year-window-unproven
           (foutcode #(koteletten/kies-aantal klein dag dag))))
    (is (= :year-window-unproven
           (foutcode #(koteletten/kies-aantal @lijn dag (+' dag groot)))))))
