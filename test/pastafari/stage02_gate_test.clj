(ns pastafari.stage02-gate-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.saus :as saus]
            [pastafari.stenen :as stenen]
            [pastafari.keuzestroom :as stroom]
            [pastafari.poortafstanden :as poorten]
            [pastafari.normative-oracle :as orakel]))

(defn- saus-voor [berekeningsdag doeldag]
  (let [werk (dagen/werk-tellingen berekeningsdag doeldag)
        verborgenwaarden (verborgen/verborgen-druppels werk)
        zichtbarewaarden (zichtbaar/zichtbare-druppels werk verborgenwaarden)]
    (saus/saus werk zichtbarewaarden)))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest ankers-zelfstandig
  (testing "Twee onafhankelijke exacte Python-ankers voor kom 1, zegel 1."
    (let [a (stroom/vraag-kom
             (saus-voor dagen/stichtingsdag dagen/stichtingsdag) 1N 1N)
          b (stroom/vraag-kom
             (saus-voor (-' dagen/stichtingsdag 2N)
                        (+' dagen/stichtingsdag 3N)) 1N 1N)]
      (is (= 90411690289794975082828500805689671121N (:first a)))
      (is (= -1N (:direction-step a)))
      (is (= 169326633423250172875125532324848427594N (:first b)))
      (is (= 1N (:direction-step b)))
      (is (= 189N (stroom/kies-rang a 922N)))
      (is (= 274N (stroom/kies-rang b 922N)))
      (is (= 2N (stroom/kies-rang a (inc stenen/modulus))))
      (is (= (inc stenen/modulus)
             (stroom/kies-rang b (inc stenen/modulus)))))))

(deftest differentieel-keuze
  (testing "49 dagparen, twee zegels, zeven familiebreedten: 784 vergelijkingen."
    (let [stichting dagen/stichtingsdag
          groot (reduce *' 1N (repeat 100 10N))
          groottes [1N 2N 922N stenen/modulus
                    (inc stenen/modulus)
                    (inc (*' stenen/modulus stenen/modulus))
                    groot]]
      (doseq [a (range -3 4)
              b (range -3 4)]
        (let [berekeningsdag (+' stichting a)
              doeldag (+' stichting b)
              werkelijk (saus-voor berekeningsdag doeldag)
              verwacht (orakel/sauce berekeningsdag doeldag)]
          (doseq [zegel [1N 30N]]
            (let [w (stroom/vraag-kom werkelijk 1N zegel)
                  e (orakel/ask-bowl verwacht 1N zegel)]
              (is (= e w))
              (doseq [grootte groottes]
                (is (= (orakel/choose-rank e grootte)
                       (stroom/kies-rang w grootte)))))))))))

(deftest poorten-verificatie
  (testing "24 voor- en achterwaartse poortafstanden met onafhankelijk orakel."
    (doseq [nummer (range 1 13)]
      (let [vooruit (poorten/positieve-poortafstand nummer)
            achteruit (poorten/negatieve-poortafstand nummer)]
        (is (= (orakel/positive-gate-gap nummer) vooruit))
        (is (= (orakel/negative-gate-gap nummer) achteruit))
        (is (<= 42N vooruit 963N))
        (is (<= 42N achteruit 963N)))))
  (testing "Grote exact-gehele poortindex boven 100 cijfers."
    (let [groot (reduce *' 1N (repeat 101 10N))]
      (is (= (orakel/positive-gate-gap groot)
             (poorten/positieve-poortafstand groot)))
      (is (= (orakel/negative-gate-gap groot)
             (poorten/negatieve-poortafstand groot))))))

(deftest ongeldige-invoer
  (let [goed (saus-voor dagen/stichtingsdag dagen/stichtingsdag)
        keuze (stroom/vraag-kom goed 1N 1N)]
    (is (= :invalid-choice-input (foutcode #(stroom/vraag-kom nil 1N 1N))))
    (is (= :invalid-choice-input (foutcode #(stroom/vraag-kom goed 7N 1N))))
    (is (= :invalid-choice-input (foutcode #(stroom/vraag-kom goed 1N 0N))))
    (is (= :invalid-choice-input
           (foutcode #(stroom/vraag-kom (assoc goed :bowls [1N]) 1N 1N))))
    (is (= :invalid-choice-input
           (foutcode #(stroom/vraag-kom (assoc goed :order-at-drop46
                                              [1 2 2 4 5 6]) 1N 1N))))
    (is (= :invalid-choice-input (foutcode #(stroom/antwoord-op keuze -1N))))
    (is (= :invalid-choice-input (foutcode #(stroom/kies-rang keuze 0N))))
    (is (= :invalid-choice-input
           (foutcode #(stroom/kies-rang (assoc keuze :first 0N) 1N))))
    (is (= :invalid-gate-index
           (foutcode #(poorten/positieve-poortafstand 0N))))
    (is (= :invalid-gate-index
           (foutcode #(poorten/negatieve-poortafstand 1.5))))))

(deftest ring-en-grenzen
  (let [m stenen/modulus
        stroom-plus {:first m :direction-step 1N}
        stroom-min {:first 1N :direction-step -1N}]
    (is (= 1N (stroom/antwoord-op stroom-plus 1N)))
    (is (= m (stroom/antwoord-op stroom-min 1N)))
    (is (= 1N (stroom/antwoord-op stroom-plus (inc m))))
    (is (= 1N (stroom/kies-rang stroom-min 1N)))
    (is (<= 1N (stroom/kies-rang stroom-plus (+ m 1N)) (+ m 1N)))))
