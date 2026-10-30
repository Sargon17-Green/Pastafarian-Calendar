(ns pastafari.stage02-sauce-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.saus :as saus]
            [pastafari.normative-oracle :as orakel]
            [pastafari.stenen :as stenen]))

(defn- bereken [bron doel]
  (let [tellingen (dagen/werk-tellingen bron doel)
        v (verborgen/verborgen-druppels tellingen)
        z (zichtbaar/zichtbare-druppels tellingen v)]
    (saus/saus tellingen z)))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest onafhankelijke-ankers
  (testing "Python-exacte-berekening, zonder Clojure-testorakel."
    (let [a (bereken -15055671N -15055671N)
          b (bereken -15055673N -15055668N)]
      (is (= [4 5 2 3 6 1] (:order-at-drop46 a)))
      (is (= [1 5 4 3 6 2] (:order-at-drop46 b)))
      (is (= [65286679584284972964194865805379907599N
              127720283375330263615328810127751035299N
              54364069496183805843611594721403108554N
              93072329024469476118876155742008280619N
              54867842942953573450868747713087920246N
              111207247632761530752404582123499651367N]
             (:bowls a)))
      (is (= [126777157998887816726160022494463086839N
              167786733098211737687823213007701008000N
              106765590325099009267806434714032846023N
              7262782294839784715074308336922412185N
              22564410742912570906796755980352830687N
              6226225913021924421755637570397638672N]
             (:bowls b)))
      (is (= 166236085135045159281910148801361692230N
             (stenen/save (reduce +' 0N (:bowls a)))))
      (is (= 97100533452034380262041764672101610952N
             (stenen/save (reduce +' 0N (:bowls b))))))))

(deftest differentieel-49-dagparen
  (testing "49 paren, zes kommen en de volgorde: 343 assertions."
    (let [stichting dagen/stichtingsdag]
      (doseq [a (range -3 4)
              b (range -3 4)]
        (let [bron (+' stichting a)
              doel (+' stichting b)
              verwacht (orakel/sauce bron doel)
              werkelijk (bereken bron doel)]
          (is (= (:order-at-drop46 verwacht)
                 (:order-at-drop46 werkelijk)))
          (doseq [index (range 6)]
            (is (= (nth (:bowls verwacht) index)
                   (nth (:bowls werkelijk) index)))))))))

(deftest grote-getallen-en-chronologie
  (testing "Exacte positieve residuen voor dagen van meer dan 100 cijfers."
    (let [groot (reduce *' 1N (repeat 100 10N))
          uitkomst (bereken (-' groot) groot)]
      (is (= 6 (count (:bowls uitkomst))))
      (is (every? #(and (integer? %) (<= 1N % stenen/modulus))
                  (:bowls uitkomst)))))
  (testing "Omgekeerde richting beïnvloedt de hele saus."
    (let [stichting dagen/stichtingsdag]
      (is (not= (bereken (-' stichting 2N) (+' stichting 3N))
                (bereken (+' stichting 3N) (-' stichting 2N)))))))

(deftest ongeldige-invoer
  (let [werk (dagen/werk-tellingen dagen/stichtingsdag dagen/stichtingsdag)
        verborgen-waarden (verborgen/verborgen-druppels werk)
        druppels (zichtbaar/zichtbare-druppels werk verborgen-waarden)]
    (is (= :invalid-sauce-input (foutcode #(saus/saus nil druppels))))
    (is (= :invalid-sauce-input
           (foutcode #(saus/saus (assoc werk :direction 4N) druppels))))
    (is (= :invalid-sauce-input
           (foutcode #(saus/saus (assoc werk :target 1.5) druppels))))
    (is (= :invalid-sauce-input
           (foutcode #(saus/saus werk (subvec druppels 0 45)))))
    (is (= :invalid-sauce-input
           (foutcode #(saus/saus werk (assoc druppels 0 0N)))))
    (is (= :invalid-sauce-input
           (foutcode #(saus/saus werk (assoc druppels 0
                                            (inc stenen/modulus))))))
    (is (= :invalid-sauce-input
           (foutcode #(saus/saus werk (seq druppels)))))))
