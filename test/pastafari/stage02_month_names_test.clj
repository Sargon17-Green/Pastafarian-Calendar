(ns pastafari.stage02-month-names-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.maandnamen :as namen]
            [pastafari.maandselectie :as selectie]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]
            [pastafari.normative-oracle :as orakel]))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- expliciete-woorden [vrije aantal]
  ;; Een zelfstandige recursieve enumeratie, alleen voor n<=6 in tests.
  (if (zero? aantal)
    [[]]
    (vec (mapcat (fn [id]
                   (map #(into [id] %)
                        (expliciete-woorden (remove #{id} vrije) (dec aantal))))
                 vrije))))

(defn- basis-voor [aantal]
  {:year {:open-gate-day 0N :close-gate-day 252N}
   :month-count aantal
   :month-lengths (vec (repeat aantal 4))
   :month-weaving [1 1 1 1]
   :month-weaving-family-count 1N
   :month-weaving-cell-bound 400N
   :cutlets [{:name-index 1N :first-day 1N :last-day 8N}]})

(defn- voorbeeldrangen [totaal]
  (distinct [1N 2N (quot (inc totaal) 2N) (dec totaal) totaal]))

(deftest uitputtend-kleine-lexicografische-families
  (testing "Alle rangen voor n=1..6 en k=1..n tegen onafhankelijke recursie."
    (doseq [n (range 1 7)
            k (range 1 (inc n))]
      (let [woorden (expliciete-woorden (range 1 (inc n)) k)]
        (is (= (bigint (count woorden))
               (namen/aantal-maandnaamreeksen n k)))
        (doseq [[index verwacht] (map-indexed vector woorden)]
          (is (= verwacht
                 (namen/maandnamen-op-rang n k (inc index)))))))))

(deftest onafhankelijke-normatieve-maandnaamselectie
  (testing "De bouwstenen blijven intact; de kom en de 47-naamoracle stemmen overeen."
    (doseq [aantal [3N 6N 47N]]
      (let [basis (basis-voor aantal)
            totaal (orakel/falling-factorial 47 aantal)
            gezien (atom [])]
        (doseq [rang (voorbeeldrangen totaal)]
          (with-redefs [selectie/kies-bewezen-maandweving
                        (fn [_ _ _ _ _] basis)
                        verdelingen/structuur-saus
                        (fn [_ _] {:test-saus true})
                        keuzes/vraag-kom
                        (fn [_ kom zegel]
                          (swap! gezien conj [kom zegel])
                          {:first 1N :direction-step 1N})
                        keuzes/kies-rang (fn [_ _] rang)]
            (let [resultaat (namen/kies-maandnamen nil 0N 0N 128N 5000000N)
                  gekozen (:month-name-indices resultaat)]
              (is (= basis (dissoc resultaat
                                   :month-name-indices
                                   :month-name-family-count)))
              (is (= totaal (:month-name-family-count resultaat)))
              (is (= (orakel/unrank-distinct-indices 47 aantal rang)
                     gekozen))
              (is (= (int aantal) (count gekozen)))
              (is (= (count gekozen) (count (set gekozen))))
              (is (every? #(<= 1 % 47) gekozen)))))
        (is (= (count (voorbeeldrangen totaal)) (count @gezien)))
        (is (every? #{[5N 33N]} @gezien)))))
  (testing "De uiterste rangen behouden de volledige naamvoorraad."
    (let [totaal (namen/aantal-maandnaamreeksen 47N 47N)]
      (is (= (vec (range 1 48))
             (namen/maandnamen-op-rang 47N 47N 1N)))
      (is (= (vec (range 47 0 -1))
             (namen/maandnamen-op-rang 47N 47N totaal)))
      (is (= (orakel/falling-factorial 47 47) totaal)))))

(deftest overgeerfde-budgetpoort-en-argumenten
  (testing "De standaardbudgetten en expliciete grenzen worden ongewijzigd doorgegeven."
    (let [gezien (atom [])]
      (with-redefs [selectie/kies-bewezen-maandweving
                    (fn [_ _ _ zoek cel]
                      (swap! gezien conj [zoek cel])
                      (basis-voor 3N))
                    verdelingen/structuur-saus (fn [_ _] {:test-saus true})
                    keuzes/vraag-kom (fn [_ _ _] {:first 1N :direction-step 1N})
                    keuzes/kies-rang (fn [_ _] 1N)]
        (is (= [1 2 3] (:month-name-indices
                         (namen/kies-maandnamen nil 0N 0N))))
        (is (= [1 2 3] (:month-name-indices
                         (namen/kies-maandnamen nil 0N 0N 64N 80000N))))
        (is (= [[128N 5000000N] [64N 80000N]] @gezien)))))
  (testing "Een geweigerde onveilige weving mag nooit saus/rangkeuze bereiken."
    (let [saus-geroepen (atom false)]
      (with-redefs [selectie/kies-bewezen-maandweving
                    (fn [& _]
                      (throw (ex-info "Niet bewezen"
                                      {:code :weaving-unrank-budget-unproven})))
                    verdelingen/structuur-saus
                    (fn [& _] (reset! saus-geroepen true)
                      (throw (ex-info "Niet bereikbaar" {})))]
        (is (= :weaving-unrank-budget-unproven
               (foutcode #(namen/kies-maandnamen nil 0N 0N))))
        (is (false? @saus-geroepen)))))
  (testing "Een ongeldige poortlijn blijft een ongeldige poortlijn."
    (is (= :invalid-gate-line
           (foutcode #(namen/kies-maandnamen nil 0N 0N))))))

(deftest strikt-begrensde-fouten
  (let [enorm (reduce *' 1N (repeat 101 10N))
        totaal (namen/aantal-maandnaamreeksen 47N 47N)]
    (doseq [n [0N -1N 48N 2.5 nil enorm]]
      (is (= :invalid-month-name-pool
             (foutcode #(namen/aantal-maandnaamreeksen n 1N)))))
    (doseq [k [0N -1N 48N 2.5 nil enorm]]
      (is (= :invalid-month-name-count
             (foutcode #(namen/aantal-maandnaamreeksen 47N k)))))
    (doseq [rang [0N -1N 2.5 nil (inc totaal) enorm]]
      (is (= :invalid-month-name-rank
             (foutcode #(namen/maandnamen-op-rang 47N 47N rang)))))
    (is (= :invalid-month-name-count
           (foutcode #(namen/maandnamen-op-rang 3N 4N 1N))))))
