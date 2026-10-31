(ns pastafari.stage02-cutlet-names-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.koteletnamen :as namen]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.poortposities :as poorten]
            [pastafari.normative-oracle :as orakel]))

(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private verlengd
  (delay (poorten/verleng-poortlijn (poorten/bouw-poortlijn 64N) 128N)))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- opsomming [vrije aantal]
  ;; Volledige expliciete testenumeratie; productie gebruikt geen enumeratie.
  (if (zero? aantal)
    [[]]
    (vec (mapcat (fn [id]
                   (map #(into [id] %)
                        (opsomming (remove #{id} vrije) (dec aantal))))
                 vrije))))

(deftest onafhankelijke-uitputtende-kleine-permutaties
  (testing "Alle rangen van alle partiele permutaties voor voorraad 1..6."
    (doseq [n (range 1 7)
            k (range 1 (inc n))]
      (let [bruut (opsomming (range 1 (inc n)) k)]
        (is (= (bigint (count bruut)) (namen/aantal-naamreeksen n k)))
        (doseq [[i verwacht] (map-indexed vector bruut)]
          (is (= verwacht (namen/namen-op-rang n k (inc i)))))))))

(deftest normatieve-ankerjaren-en-verlenging
  (testing "Normatieve naamkeuze via eigen saus/oracle voor bewezen jaren."
    (doseq [offset [-157N 0N 413N]]
      (let [dag (+' dagen/stichtingsdag offset)
            normstaat (orakel/new-gate-state)
            jaar5000 (orakel/year5000 normstaat dag)
            vorig (orakel/previous-year normstaat dag jaar5000)
            volgend (orakel/next-year normstaat dag jaar5000)]
        (doseq [doeldag [(:close-gate-day vorig) dag (:close-gate-day volgend)]]
          (let [staat (orakel/new-gate-state)
                jaar (orakel/find-target-year staat dag doeldag)
                saus (orakel/sauce dag (inc (:open-gate-day jaar)))
                aantal (orakel/choose-cutlet-count saus jaar)
                partitie (orakel/choose-cutlet-partition staat dag saus jaar aantal)
                naamindices (orakel/choose-cutlet-names saus aantal)
                direct (namen/kies-namen @lijn dag doeldag)
                uitgebreid (namen/kies-namen @verlengd dag doeldag)]
            (is (= jaar (:year direct)))
            (is (= aantal (:cutlet-count direct)))
            (is (= partitie (:partition direct)))
            (is (= naamindices (:name-indices direct)))
            (is (= (orakel/falling-factorial 17 aantal)
                   (:name-family-count direct)))
            (is (= (count naamindices) (count (set (:name-indices direct)))))
            (is (every? #(<= 1 % 17) (:name-indices direct)))
            (is (= direct uitgebreid))))))))

(deftest eerste-laatste-rang-en-kom
  (let [gezien (atom [])
        rang (atom :eerste)
        jaar {:open-gate-day 1N}
        basis {:year jaar :cutlet-count 6N :partition [1N 1N 1N 1N 1N 1N]
               :partition-count 1N :required-boundary nil}]
    (with-redefs [verdelingen/kies-verdeling (fn [_ _ _ _] basis)
                  verdelingen/structuur-saus (fn [_ _] {:test-only true})
                  keuzes/vraag-kom (fn [_ kom zegel]
                                     (swap! gezien conj [kom zegel])
                                     {:first 1N :direction-step 1N})
                  keuzes/kies-rang (fn [_ totaal]
                                     (if (= @rang :eerste) 1N totaal))]
      (let [a (namen/kies-namen nil 0N 0N 0N)]
        (is (= basis (select-keys a (keys basis))))
        (is (= [1 2 3 4 5 6] (:name-indices a)))
        (is (= (orakel/falling-factorial 17 6) (:name-family-count a))))
      (reset! rang :laatste)
      (is (= [17 16 15 14 13 12]
             (:name-indices (namen/kies-namen nil 0N 0N 0N))))
      (is (= [[5N 22N] [5N 22N]] @gezien)))))

(deftest maximale-grenzen-en-fouten
  (let [groot (reduce *' 1N (repeat 101 10N))
        totaal (namen/aantal-naamreeksen 17N 17N)
        laatste (namen/namen-op-rang 17N 17N totaal)]
    (is (= (orakel/falling-factorial 17 17) totaal))
    (is (= (vec (range 17 0 -1)) laatste))
    (is (= (vec (range 1 18)) (namen/namen-op-rang 17N 17N 1N)))
    (is (= 17 (count (set laatste))))
    (doseq [n [0N -1N 18N 2.5 nil groot]]
      (is (= :invalid-name-pool
             (foutcode #(namen/aantal-naamreeksen n 1N)))))
    (doseq [k [0N -1N 18N 2.5 nil groot]]
      (is (= :invalid-name-count
             (foutcode #(namen/aantal-naamreeksen 17N k)))))
    (doseq [r [0N -1N 2.5 nil (inc totaal) groot]]
      (is (= :invalid-name-rank
             (foutcode #(namen/namen-op-rang 17N 17N r)))))
    (is (= :invalid-name-count
           (foutcode #(namen/namen-op-rang 3N 4N 1N))))))

(deftest geerfde-foutgrenzen
  (let [dag dagen/stichtingsdag]
    (is (= :invalid-gate-line (foutcode #(namen/kies-namen nil dag dag))))
    (is (= :invalid-day (foutcode #(namen/kies-namen @lijn dag 2.5))))
    (is (= :invalid-step-budget
           (foutcode #(namen/kies-namen @lijn dag dag 129N))))
    (is (= :year-window-unproven
           (foutcode #(namen/kies-namen @lijn dag
                                       (+' dag (reduce *' 1N (repeat 101 10N)))))))))
