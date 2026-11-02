(ns pastafari.stage02-date-projection-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.datumprojectie :as projectie]
            [pastafari.maandnamen :as namen]
            [pastafari.normative-oracle :as orakel]))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- fixture
  ([open]
   (fixture open (vec (repeat 3 84))
            (vec (take 252 (cycle [1 2 3])))
            (vec (range 1 7))))
  ([open lengtes weving koteletnamen]
   (let [duur (reduce +' 0N lengtes)
         maandnamen (vec (take (count lengtes) (range 47 0 -1)))
         aantal (count koteletnamen)
         stuk (quot duur aantal)
         begin (inc open)
         cutlets (mapv (fn [i naam]
                          {:name-index naam
                           :first-day (+' begin (*' stuk i))
                           :last-day (+' open (*' stuk (inc i)))})
                        (range aantal) koteletnamen)]
     {:year {:number 5000N :open-gate-day open
             :close-gate-day (+' open duur)}
      :cutlets cutlets
      :month-count (count lengtes)
      :month-lengths lengtes
      :month-weaving weving
      :month-name-indices maandnamen
      :month-weaving-cell-bound 400N})))

(defn- normatieve-projectie [basis dag]
  ;; We vervangen ALLEEN de zware structuurselectie. De publieke
  ;; calendar-date-canonical berekent zelf het vijfdelige dagresultaat.
  (let [jaar (:year basis)
        structuur {:cutlets (:cutlets basis)
                   :month-weaving (:month-weaving basis)
                   :month-names (:month-name-indices basis)}]
    (with-redefs [orakel/new-gate-state (fn [] (atom {}))
                  orakel/find-target-year (fn [_ _ _] jaar)
                  orakel/build-year-structure (fn [_ _ _] structuur)]
      (orakel/calendar-date-canonical 0N dag))))

(deftest begrensde-dag-differentiaal-met-canonieke-oracle
  (testing "252 dagposities, jaargrenzen en unieke numerieke naamindices."
    (let [basis (fixture 1000N)]
      (doseq [dag (range 1001 1253)]
        (let [actueel (projectie/projecteer-bewezen-dag basis dag)
              verwacht (normatieve-projectie basis dag)]
          (is (= verwacht actueel))
          (is (= 5 (count actueel)))
          (is (every? integer? actueel))))
      (is (= [5000N 1 1N 47 1]
             (projectie/projecteer-bewezen-dag basis 1001N)))
      (is (= [5000N 6 42N 45 84]
             (projectie/projecteer-bewezen-dag basis 1252N)))))
  (testing "Maximale 5778 dagposities: 46×123+120, 47 maanden, 6 koteletten."
    (let [lengtes (conj (vec (repeat 46 123)) 120)
          weving (vec (mapcat (fn [i n] (repeat n i))
                              (range 1 48) lengtes))
          basis (fixture -8000N lengtes weving [1 2 3 4 5 6])]
      (is (= 5778 (count weving)))
      (doseq [offset [0 1 122 123 2940 5776 5777]]
        (let [dag (+' -7999N offset)]
          (is (= (normatieve-projectie basis dag)
                 (projectie/projecteer-bewezen-dag basis dag))))))))

(deftest afwijkingen-worden-vroeg-geweigerd
  (let [b (fixture 1000N)]
    (doseq [dag [nil 2.5 1000N 1253N]]
      (is (= :target-day-outside-proven-year
             (foutcode #(projectie/projecteer-bewezen-dag b dag)))))
    (doseq [slechte [(assoc b :month-count 48)
                     (assoc b :month-lengths [84 84 85])
                     (assoc b :month-weaving [1 2 3])
                     (assoc b :month-weaving (assoc (:month-weaving b) 0 4))
                     (assoc b :month-name-indices [1 1 2])
                     (assoc b :month-name-indices [1 2 48])
                     (assoc b :cutlets (assoc-in (:cutlets b) [1 :first-day] 1042N))
                     (assoc b :cutlets (assoc-in (:cutlets b) [0 :name-index] 18N))
                     (assoc b :year (assoc (:year b) :close-gate-day 1253N))
                     (assoc b :year (dissoc (:year b) :number))
                     (dissoc b :year)]]
      (is (= :invalid-date-projection-structure
             (foutcode #(projectie/projecteer-bewezen-dag slechte 1001N)))))))

(deftest opt-in-behoud-en-fail-closed
  (let [basis (fixture 1000N)
        gezien (atom [])]
    (with-redefs [namen/kies-maandnamen
                  (fn [_ _ _ zoek cel]
                    (swap! gezien conj [zoek cel])
                    basis)]
      (let [a (projectie/kies-bewezen-datum nil 0N 1001N)
            b (projectie/kies-bewezen-datum nil 0N 1252N 64N 80000N)]
        (is (= basis (dissoc a :date-components)))
        (is (= basis (dissoc b :date-components)))
        (is (= [5000N 1 1N 47 1] (:date-components a)))
        (is (= [5000N 6 42N 45 84] (:date-components b)))
        (is (= [[128N 5000000N] [64N 80000N]] @gezien)))))
  (let [doorgeroepen (atom false)]
    (with-redefs [namen/kies-maandnamen
                  (fn [& _] (throw (ex-info "Budget geweigerd"
                                           {:code :weaving-unrank-budget-unproven}))) ]
      (is (= :weaving-unrank-budget-unproven
             (foutcode #(projectie/kies-bewezen-datum nil 0N 1001N)))))
    (with-redefs [namen/kies-maandnamen
                  (fn [& _] (reset! doorgeroepen true) (fixture 1000N))]
      (is (= :target-day-outside-proven-year
             (foutcode #(projectie/kies-bewezen-datum nil 0N 1253N))))
      (is @doorgeroepen))))
