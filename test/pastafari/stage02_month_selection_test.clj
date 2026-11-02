(ns pastafari.stage02-month-selection-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.maandselectie :as selectie]
            [pastafari.maandlengtes :as lengtes]
            [pastafari.maandweving :as weving]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.normative-oracle :as orakel]))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- basis-voor [v]
  {:year {:open-gate-day 0N :close-gate-day (reduce +' 0N v)}
   :month-count (count v)
   :month-lengths v
   :month-length-family-count 1N
   :cutlets [{:name-index 1N :first-day 1N :last-day 8N}]})

(defn- uiterste-rangen [totaal]
  (distinct [1N 2N (quot (inc totaal) 2N) (dec totaal) totaal]))

(deftest geselecteerde-weving-tegen-onafhankelijk-orakel
  (testing "De samengevoegde selectie behoudt velden en volgt de normatieve recursieve rangoracle."
    (doseq [v [[4 4] [4 4 4] [4 5 4]]]
      (let [basis (basis-voor v)
            oracle (orakel/weaving-family v)
            totaal ((:count oracle))
            aanvragen (atom [])]
        (is (= (weving/aantal-wevingen-groot v) totaal))
        (doseq [r (uiterste-rangen totaal)]
          (with-redefs [lengtes/kies-maandlengtes
                        (fn [_ _ _ _] basis)
                        verdelingen/structuur-saus
                        (fn [_ _] {:test-saus true})
                        keuzes/vraag-kom
                        (fn [_ kom zegel]
                          (swap! aanvragen conj [kom zegel])
                          {:first 1N :direction-step 1N})
                        keuzes/kies-rang (fn [_ _] r)]
            (let [uitkomst (selectie/kies-bewezen-maandweving
                             nil 0N 0N 128N 5000000N)]
              (is (= basis (apply dissoc uitkomst
                                  [:month-weaving
                                   :month-weaving-family-count
                                   :month-weaving-cell-bound])))
              (is (= totaal (:month-weaving-family-count uitkomst)))
              (is (= ((:unrank1 oracle) r) (:month-weaving uitkomst)))
              (is (<= (:month-weaving-cell-bound uitkomst) 5000000N)))))
        (is (every? #{[4N 32N]} @aanvragen))
        (is (= (count (uiterste-rangen totaal)) (count @aanvragen)))))))

(deftest grotere-opt-in-familie-zonder-datumclaim
  (testing "Zes maanden blijven buiten de oude API, maar binnen de expliciete nieuwe budgetpoort."
    (let [v (vec (repeat 6 4))
          basis (basis-voor v)
          totaal (weving/aantal-wevingen-groot v)]
      (is (= :weaving-bound-exceeded
             (foutcode #(weving/weving-op-rang v 1N))))
      (doseq [r [1N totaal]]
        (with-redefs [lengtes/kies-maandlengtes (fn [_ _ _ _] basis)
                      verdelingen/structuur-saus (fn [_ _] {:test-saus true})
                      keuzes/vraag-kom (fn [_ _ _]
                                          {:first 1N :direction-step 1N})
                      keuzes/kies-rang (fn [_ _] r)]
          (let [uitkomst (selectie/kies-bewezen-maandweving
                           nil 0N 0N 128N 5000000N)
                woord (:month-weaving uitkomst)]
            (is (= 24 (count woord)))
            (is (= v (mapv #(count (filter (fn [x] (= x %)) woord))
                           (range 1 7))))
            (is (= totaal (:month-weaving-family-count uitkomst)))
            (when (= r 1N)
              (is (= (vec (mapcat #(repeat 4 %) (range 1 7))) woord)))))))))

(deftest geen-stilzwijgende-domeinverruiming
  (testing "Ontoereikend budget wordt geweigerd VOOR saus, telling en rangkeuze."
    (doseq [[v budget verwacht]
            [[[4 4] 1N :weaving-unrank-budget-unproven]
             [(conj (vec (repeat 46 123)) 120) 5000000N
              :weaving-unrank-budget-unproven]
             [[4 4] 0N :invalid-weaving-budget]
             [[4 4] 5000001N :invalid-weaving-budget]]]
      (let [opgeroepen (atom false)]
        (with-redefs [lengtes/kies-maandlengtes
                      (fn [_ _ _ _] (basis-voor v))
                      verdelingen/structuur-saus
                      (fn [& _] (reset! opgeroepen true)
                        (throw (ex-info "Mag niet worden bereikt" {})))]
          (is (= verwacht
                 (foutcode #(selectie/kies-bewezen-maandweving
                              nil 0N 0N 128N budget))))
          (is (false? @opgeroepen))))))
  (testing "Geërfde bronfouten gaan zonder translatie door."
    (is (= :invalid-gate-line
           (foutcode #(selectie/kies-bewezen-maandweving
                        nil 0N 0N 128N 5000000N))))))
