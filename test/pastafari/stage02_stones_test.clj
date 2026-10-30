(ns pastafari.stage02-stones-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.stenen :as stenen]
            [pastafari.normative-oracle :as orakel]))

(defn- foutcode [bewerking]
  (try
    (bewerking)
    nil
    (catch clojure.lang.ExceptionInfo e
      (:code (ex-data e)))))

(deftest save-modulo-en-grenzen
  (testing "SAVE gebruikt een 1-gebaseerd residu, ook voor nul en negatieven."
    (let [m stenen/modulus]
      (is (= 170141183460469231731687303715884105727N m))
      (doseq [[invoer verwacht] [[0N m]
                                 [-1N (dec m)]
                                 [1N 1N]
                                 [m m]
                                 [(inc m) 1N]
                                 [(-' m) m]
                                 [(+' (*' 1000N m) 39N) 39N]]]
        (is (= verwacht (stenen/save invoer))))
      (is (= :invalid-save-input (foutcode #(stenen/save 1.5))))
      (is (= :invalid-save-input (foutcode #(stenen/save nil)))))))

(deftest vaste-steenankers
  (testing "Onafhankelijk berekende ankers: eerste, tweede, derde en laatste steen."
    (is (= [17N 29N 43N 71N 101N] (stenen/steen 1)))
    (is (= [378N 1073N 2375N 6195N 10493N] (stenen/steen 2)))
    (is (= [146106N 1163582N 5685063N 38495823N 110114158N]
           (stenen/steen 3)))
    (is (= [73799454308499791987382386781055001470N
            147925408106533232424672641008220632365N
            94499522601819303005579577099149028685N
            108473647672201258090947028490673028834N
            137131922036975206684616468948804344042N]
           (stenen/steen 46)))))

(deftest tabel-grenzen
  (testing "De volledige 46 maal 5 tabel blijft exact binnen de residugrenzen."
    (is (= 46 (count stenen/stenen)))
    (is (every? #(= 5 (count %)) stenen/stenen))
    (is (every? #(and (integer? %) (<= 1N % stenen/modulus))
                (mapcat identity stenen/stenen)))
    (is (= :invalid-stone-index (foutcode #(stenen/steen 0))))
    (is (= :invalid-stone-index (foutcode #(stenen/steen 47))))
    (is (= :invalid-stone-index (foutcode #(stenen/steen 1.5))))))

(deftest differentieel-alle-stenen
  (testing "230 onafhankelijke veldvergelijkingen met het testorakel; productie verwijst er niet naar."
    (doseq [index (range 46)
            soort (range 5)]
      (is (= (get-in orakel/stones [index soort])
             (get-in stenen/stenen [index soort]))))))
