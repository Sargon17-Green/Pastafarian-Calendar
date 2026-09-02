(ns pastafari.stage01-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.infrastructure :as infra]
            [pastafari.monster :as monster]
            [pastafari.monster-context :as context]
            [pastafari.normative-oracle :as oracle]
            [pastafari.source-language-catalog :as catalog]
            [pastafari.stage01-fixtures :as fixtures]))

(deftest bron-en-constanten
  (testing "De grote teller en de twee dagankers zijn exact."
    (is (= fixtures/expected-m oracle/m))
    (is (= 14777149N (- oracle/tablets-day oracle/foundation-day))))
  (testing "SAVE bewaart veelvouden van M als M."
    (doseq [[input expected] fixtures/save-cases]
      (is (= expected (oracle/save input))))))

(deftest dagtellingen
  (testing "De stichtingsdag en beide zijden volgen de normatieve pariteit."
    (is (= 1N (oracle/day-count oracle/foundation-day)))
    (is (= 2N (oracle/day-count (dec oracle/foundation-day))))
    (is (= 3N (oracle/day-count (inc oracle/foundation-day))))
    (is (= 4N (oracle/day-count (- oracle/foundation-day 2N))))
    (is (= 5N (oracle/day-count (+ oracle/foundation-day 2N)))))
  (testing "De afstand is chronologisch en inclusief."
    (is (= {:action 2N :target 3N :distance 3N :connection 5N :direction 3N}
           (oracle/work-counts (dec oracle/foundation-day) (inc oracle/foundation-day))))
    (is (= {:action 1N :target 1N :distance 1N :connection 2N :direction 2N}
           (oracle/work-counts oracle/foundation-day oracle/foundation-day)))))

(deftest stenen-en-komstart
  (testing "De tweede stenenrij is rechtstreeks uit de ingebedde formules afgeleid."
    (is (= fixtures/stone-two (second oracle/stones))))
  (testing "De eerste zes kommen voor stichting tegen stichting hebben vaste verwachte waarden."
    (is (= fixtures/foundation-initial-bowls
           (oracle/initial-bowls (oracle/work-counts oracle/foundation-day oracle/foundation-day))))))

(deftest permutaties-en-selectie
  (testing "De lexicografische permutatierangen zijn één-gebaseerd."
    (is (= [1 2 3 4 5 6] (oracle/bowl-order-from-number 1N)))
    (is (= [6 5 4 3 2 1] (oracle/bowl-order-from-number 720N)))
    (is (= [6 5 4 3 2 1] (oracle/bowl-order-from-drop 720N))))
  (testing "De korte afwijzing blijft op dezelfde antwoordenring."
    (is (= 1N (oracle/choose-rank-short {:first oracle/m :direction-step 1N} 10N))))
  (testing "De brede selectie bouwt één breed getal en verschuift dat getal."
    (is (= (inc oracle/m)
           (oracle/choose-rank-wide {:first 1N :direction-step 1N} (inc oracle/m))))))

(deftest geordende-families
  (testing "Een kleine begrensde compositiefamilie heeft exact de expliciete lexicografische volgorde."
    (let [family (oracle/bounded-composition-family 7N 2 1N 6N)]
      (is (= 6N ((:count family))))
      (is (= [1N 6N] ((:unrank1 family) 1N)))
      (is (= [6N 1N] ((:unrank1 family) 6N)))))
  (testing "De kleine weeffamilie respecteert eerste en laatste verschijningen."
    (let [family (oracle/weaving-family [2N 2N])]
      (is (= 2N ((:count family))))
      (is (= [1 1 2 2] ((:unrank1 family) 1N)))
      (is (= [1 2 1 2] ((:unrank1 family) 2N)))))
  (testing "Partiële permutaties gebruiken uitsluitend canonieke indexen."
    (is (= [1 2 3 4 5 6] (oracle/unrank-distinct-indices 17 6 1N)))
    (is (= [6 5 4 3 2 1] (oracle/unrank-distinct-indices 6 6 720N)))))

(deftest bron-taalcatalogus
  (testing "Alle zeventien koteletnamen hebben precies één vaste canonieke index."
    (is (= 17 (count catalog/cutlet-catalog)))
    (is (= (vec (range 1 18)) (mapv :canonical-index catalog/cutlet-catalog)))
    (is (= 17 (count (set (map :source catalog/cutlet-catalog))))))
  (testing "Alle zevenenveertig maandnamen hebben precies één vaste canonieke index."
    (is (= 47 (count catalog/month-catalog)))
    (is (= (vec (range 1 48)) (mapv :canonical-index catalog/month-catalog)))
    (is (= 47 (count (set (map :source catalog/month-catalog))))))
  (testing "Presentatie wordt pas na de canonieke index opgelost."
    (is (= "tarwe" (catalog/cutlet-source 12)))
    (is (= "de gesloten deur" (catalog/month-source 32)))))

(deftest saus-kern-determinisme
  (testing "De volledige normatieve saus is deterministisch zonder externe implementatie."
    (let [a (oracle/sauce oracle/foundation-day oracle/foundation-day)
          b (oracle/sauce oracle/foundation-day oracle/foundation-day)]
      (is (= a b))
      (is (= 6 (count (:bowls a))))
      (is (= #{1 2 3 4 5 6} (set (:order-at-drop46 a))))
      (is (every? #(<= 1N % oracle/m) (:bowls a))))))

(deftest neutrale-monsterinfrastructuur
  (testing "De bootstrapcontext is per aanroep nieuw en bevat alleen algemene infrastructuur."
    (let [a (context/new-context 1N 2N)
          b (context/new-context 1N 2N)]
      (is (= a b))
      (is (not (identical? a b)))
      (is (= :validated (:status (infra/validate-inputs a))))))
  (testing "Het productiepad gebruikt in fase één geen testorakel als terugval."
    (let [failure (try
                    (monster/calendar-date-spaghetti 1N 1N)
                    nil
                    (catch clojure.lang.ExceptionInfo e e))]
      (is failure)
      (is (= :production-path-not-yet-built (:code (ex-data failure)))))))
