(ns pastafari.stage02-month-weaving-large-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.maandweving :as weving]))

(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- binomiaal [n k]
  (quot (reduce *' 1N (range (inc (- n k)) (inc n)))
        (reduce *' 1N (range 1 (inc k)))))

(deftest onafhankelijk-klein-dp
  (testing "De reeds bestaande restvector-DP is een andere telmethode."
    (doseq [lengtes [[4] [5] [4 4] [4 9] [9 4] [14 12]
                     [4 4 4] [4 4 5] [4 4 4 4 4]
                     [4 4 4 4 13] [4 9 6 8]]]
      (is (= (weving/aantal-wevingen lengtes)
             (weving/aantal-wevingen-groot lengtes))
          (str "Niet gelijk: " lengtes)))))

(deftest twee-maanden-en-omkering
  (testing "Binomiale identiteit is onafhankelijk van de grote teller."
    (doseq [[a b] [[4 123] [123 4] [123 123] [14 12]]]
      (is (= (binomiaal (- (+ a b) 2) (dec a))
             (weving/aantal-wevingen-groot [a b])))))
  (testing "Omkeer woord en hernummer de maanden: exacte bijectie."
    (doseq [lengtes [[4 9 6 8] [4 123 9] [4 5 6 7 8]]]
      (is (= (weving/aantal-wevingen-groot lengtes)
             (weving/aantal-wevingen-groot (vec (reverse lengtes))))))))

(deftest groot-eindig-bereik
  (is (= 1N (weving/aantal-wevingen-groot [123])))
  (is (= 223578939N
         (mod (weving/aantal-wevingen-groot (vec (repeat 47 4)))
              1000000007N)))
  (let [lengtes (conj (vec (repeat 46 123)) 120)
        begin (System/nanoTime)
        telling (weving/aantal-wevingen-groot lengtes)
        milliseconden (quot (- (System/nanoTime) begin) 1000000)]
    (println "DISCOVERY18 47 maanden / 5778 dagen, tijd (ms):"
             milliseconden)
    (is (pos? telling))
    (is (= 368726924N (mod telling 1000000007N)))))

(deftest fouten-blijven-afgeschermd
  (doseq [lengtes [nil [] [3] [124] [4 0] [4 2.5] "444"]]
    (is (= :invalid-weaving-family
           (foutcode #(weving/aantal-wevingen-groot lengtes)))))
  (doseq [lengtes [(vec (repeat 48 4))
                   (vec (repeat 47 123))]]
    (is (= :weaving-bound-exceeded
           (foutcode #(weving/aantal-wevingen-groot lengtes)))))
  (is (= :weaving-bound-exceeded
         (foutcode #(weving/weving-op-rang (vec (repeat 47 4)) 1N)))))
