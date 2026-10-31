(ns pastafari.stage02-month-length-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.maandaantal :as aantallen]
            [pastafari.maandlengtes :as lengtes]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.poortposities :as poorten]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private verlengd
  (delay (poorten/verleng-poortlijn (poorten/bouw-poortlijn 64N) 128N)))

(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- brute-reeksen [duur maanden]
  ;; Test-only depth-first enumeration, not production window-sum DP.
  (if (zero? maanden)
    (if (zero? duur) [[]] [])
    (let [laag (max 4 (- duur (* 123 (dec maanden))))
          hoog (min 123 (- duur (* 4 (dec maanden))))]
      (vec (mapcat (fn [x]
                     (map (fn [rest] (into [x] rest))
                          (brute-reeksen (- duur x) (dec maanden))))
                   (range laag (inc hoog)))))))

(deftest kleine-families-uitputtend
  (testing "Onafhankelijke brute-force lijst en elke lexicografische rang."
    (doseq [m (range 1 5)
            duur (range (* 4 m) (inc (+ (* 4 m) 12)))]
      (let [verwacht (brute-reeksen duur m)
            n (lengtes/aantal-lengtereeksen duur m)]
        (is (= (bigint (count verwacht)) n))
        (doseq [[i item] (map-indexed vector verwacht)]
          (is (= item (lengtes/lengtes-op-rang duur m (inc i)))))))))

(deftest uiterste-rangen-en-grote-getallen
  (is (= 1N (lengtes/aantal-lengtereeksen 12N 3N)))
  (is (= [4 4 4] (lengtes/lengtes-op-rang 12N 3N 1N)))
  (is (= [123 123 123] (lengtes/lengtes-op-rang 369N 3N 1N)))
  (let [n (lengtes/aantal-lengtereeksen 252N 3N)]
    (is (pos? n))
    (is (= [6 123 123] (lengtes/lengtes-op-rang 252N 3N 1N)))
    (is (= [123 123 6] (lengtes/lengtes-op-rang 252N 3N n))))
  (let [n (lengtes/aantal-lengtereeksen 5778N 47N)
        eerste (lengtes/lengtes-op-rang 5778N 47N 1N)
        laatste (lengtes/lengtes-op-rang 5778N 47N n)]
    (is (= 18424N n))
    (is (= (into [120] (repeat 46 123)) eerste))
    (is (= (conj (vec (repeat 46 123)) 120) laatste))
    (is (= 5778 (reduce + eerste)))
    (is (= 5778 (reduce + laatste)))))

(deftest eerste-en-laatste-keuze-met-zegel
  (let [gezien (atom [])
        laatste (atom false)
        jaar {:open-gate-day 0N :close-gate-day 252N}
        basis {:year jaar :month-count 3 :month-count-options 45
               :cutlets [] :name-indices [] :partition []}]
    (with-redefs [aantallen/kies-maandaantal (fn [_ _ _ _] basis)
                  verdelingen/structuur-saus (fn [_ _] {:test-only true})
                  keuzes/vraag-kom (fn [_ kom zegel]
                                     (swap! gezien conj [kom zegel])
                                     {:first 1N :direction-step 1N})
                  keuzes/kies-rang (fn [_ totaal] (if @laatste totaal 1N))]
      (let [eerste (lengtes/kies-maandlengtes nil 0N 0N 0N)]
        (is (= [6 123 123] (:month-lengths eerste)))
        (is (= basis (dissoc eerste :month-lengths :month-length-family-count))))
      (reset! laatste true)
      (is (= [123 123 6]
             (:month-lengths (lengtes/kies-maandlengtes nil 0N 0N 0N))))
      (is (= [[3N 31N] [3N 31N]] @gezien)))))

(deftest normatieve-doeljaren
  (testing "Recursief onafhankelijk normoracle voor twee echte doeldagen."
    (doseq [[offset richting] [[-157N :huidig] [413N :volgend]]]
      (let [dag (+' dagen/stichtingsdag offset)
            staat (orakel/new-gate-state)
            basisjaar (orakel/year5000 staat dag)
            volgend (orakel/next-year staat dag basisjaar)
            doel (if (= richting :huidig) dag (:close-gate-day volgend))
            normstaat (orakel/new-gate-state)
            jaar (orakel/find-target-year normstaat dag doel)
            saus (orakel/sauce dag (inc (:open-gate-day jaar)))
            m (orakel/choose-month-count saus jaar)
            verwacht (orakel/choose-month-lengths saus jaar m)
            direct (lengtes/kies-maandlengtes @lijn dag doel)
            uitgebreid (lengtes/kies-maandlengtes @verlengd dag doel)]
        (is (= jaar (:year direct)))
        (is (= m (:month-count direct)))
        (is (= verwacht (:month-lengths direct)))
        (is (= (:month-count direct) (count (:month-lengths direct))))
        (is (= (-' (:close-gate-day jaar) (:open-gate-day jaar))
               (reduce +' 0N (:month-lengths direct))))
        (is (every? #(<= 4 % 123) (:month-lengths direct)))
        (is (= direct uitgebreid))))))

(deftest fouten-en-geerfde-poorten
  (doseq [[duur m] [[nil 3] [2.5 3] [3 1] [5779 47]
                    [12 0] [12 nil] [12 2.5] [12 48]
                    [252 1] [4 2]]]
    (is (= :invalid-month-length-family
           (foutcode #(lengtes/aantal-lengtereeksen duur m)))))
  (let [n (lengtes/aantal-lengtereeksen 252N 3N)]
    (doseq [r [nil 0 -1 2.5 (inc n)]]
      (is (= :invalid-month-length-rank
             (foutcode #(lengtes/lengtes-op-rang 252N 3N r))))))
  (let [dag dagen/stichtingsdag
        groot (reduce *' 1N (repeat 101 10N))]
    (is (= :invalid-gate-line
           (foutcode #(lengtes/kies-maandlengtes nil dag dag))))
    (is (= :invalid-day
           (foutcode #(lengtes/kies-maandlengtes @lijn dag 2.5))))
    (is (= :invalid-step-budget
           (foutcode #(lengtes/kies-maandlengtes @lijn dag dag 129N))))
    (is (= :year-window-unproven
           (foutcode #(lengtes/kies-maandlengtes @lijn dag (+' dag groot)))))))
