(ns pastafari.stage02-month-count-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.maandaantal :as maanden]
            [pastafari.koteletgrenzen :as grenzen]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.poortposities :as poorten]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private verlengd (delay
  (poorten/verleng-poortlijn (poorten/bouw-poortlijn 64N) 128N)))
(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest alle-haalbare-jaarduren
  (testing "Alle 5527 jaarduren tegenover zelfstandige ceil/floor-formule."
    (doseq [duur (range 252 5779)]
      (let [jaar {:open-gate-day -100N :close-gate-day (+' -100N duur)}
            laag (max 3 (quot (+ duur 122) 123))
            hoog (min 47 (quot duur 4))
            norm (vec (range laag (inc hoog)))
            echt (maanden/mogelijke-maandaantallen jaar)]
        (is (= norm echt))
        (is (seq echt))
        (is (every? #(<= 3 % 47) echt))
        (is (every? #(<= (*' 4N %) duur (*' 123N %)) echt))))))

(deftest eerste-laatste-rang-en-kom
  (let [gezien (atom [])
        laatste (atom false)
        jaar {:number 5000N :open-gate-day 0N :close-gate-day 252N}
        basis {:year jaar :cutlets [] :name-indices [] :partition []}]
    (with-redefs [grenzen/kies-koteletten (fn [_ _ _ _] basis)
                  verdelingen/structuur-saus (fn [_ _] {:test-only true})
                  keuzes/vraag-kom (fn [_ kom zegel]
                                     (swap! gezien conj [kom zegel])
                                     {:first 1N :direction-step 1N})
                  keuzes/kies-rang (fn [_ n] (if @laatste n 1N))]
      (let [eerste (maanden/kies-maandaantal nil 0N 0N 0N)]
        (is (= 3 (:month-count eerste)))
        (is (= 45 (:month-count-options eerste)))
        (is (= basis (dissoc eerste :month-count :month-count-options))))
      (reset! laatste true)
      (is (= 47 (:month-count (maanden/kies-maandaantal nil 0N 0N 0N))))
      (is (= [[3N 30N] [3N 30N]] @gezien)))))

(deftest grensgevallen-en-fouten
  (is (= [47] (maanden/mogelijke-maandaantallen
               {:open-gate-day 0N :close-gate-day 5778N})))
  (is (= (vec (range 3 48))
         (maanden/mogelijke-maandaantallen
          {:open-gate-day 0N :close-gate-day 252N})))
  (doseq [jaar [nil
                {:open-gate-day 0N :close-gate-day 251N}
                {:open-gate-day 0N :close-gate-day 5779N}
                {:open-gate-day 0N :close-gate-day nil}
                {:open-gate-day 0N :close-gate-day 2.5}
                {:open-gate-day 0N :close-gate-day (reduce *' 1N (repeat 101 10N))}]]
    (is (= :invalid-year-duration
           (foutcode #(maanden/mogelijke-maandaantallen jaar))))))

(deftest normatieve-jaren-en-verlenging
  (testing "Drie rekenmomenten en vorig/doeljaar/volgend jaar met eigen orakel."
    (doseq [offset [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag offset)
            staat (orakel/new-gate-state)
            basisjaar (orakel/year5000 staat dag)
            vorig (orakel/previous-year staat dag basisjaar)
            volgend (orakel/next-year staat dag basisjaar)]
        (doseq [doel [(:close-gate-day vorig) dag (:close-gate-day volgend)]]
          (let [normstaat (orakel/new-gate-state)
                jaar (orakel/find-target-year normstaat dag doel)
                saus (orakel/sauce dag (inc (:open-gate-day jaar)))
                norm (orakel/choose-month-count saus jaar)
                direct (maanden/kies-maandaantal @lijn dag doel)
                uitgebreid (maanden/kies-maandaantal @verlengd dag doel)]
            (is (= jaar (:year direct)))
            (is (= norm (:month-count direct)))
            (is (= (count (maanden/mogelijke-maandaantallen jaar))
                   (:month-count-options direct)))
            (is (= (:cutlets (grenzen/kies-koteletten @lijn dag doel))
                   (:cutlets direct)))
            (is (= direct uitgebreid))))))))

(deftest geerfde-foutcodes
  (let [dag dagen/stichtingsdag
        groot (reduce *' 1N (repeat 101 10N))]
    (is (= :invalid-gate-line
           (foutcode #(maanden/kies-maandaantal nil dag dag))))
    (is (= :invalid-day
           (foutcode #(maanden/kies-maandaantal @lijn dag 2.5))))
    (is (= :invalid-step-budget
           (foutcode #(maanden/kies-maandaantal @lijn dag dag 129N))))
    (is (= :year-window-unproven
           (foutcode #(maanden/kies-maandaantal @lijn dag (+' dag groot)))))))
