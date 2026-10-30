(ns pastafari.stage02-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.monster :as monster]
            [pastafari.normative-oracle :as orakel]))

(defn- foutcode [f]
  (try (f)
       nil
       (catch clojure.lang.ExceptionInfo e
         (:code (ex-data e)))))

(defn- foutgegevens [f]
  (try (f)
       nil
       (catch clojure.lang.ExceptionInfo e
         (ex-data e))))

(deftest stichtingsgrenzen
  (testing "Een-op-een grensvectoren voor de alternerende dagtelling."
    (let [f dagen/stichtingsdag]
      (doseq [[dag verwacht] [[(-' f 3N) 6N]
                             [(-' f 2N) 4N]
                             [(dec f) 2N]
                             [f 1N]
                             [(inc f) 3N]
                             [(+' f 2N) 5N]
                             [(+' f 3N) 7N]]]
        (is (= verwacht (dagen/dagtelling dag)))))))

(deftest chronologische-afstand
  (testing "Inclusieve afstand en richting zijn niet de alternerende dagtelling."
    (let [f dagen/stichtingsdag]
      (is (= {:action 4N :target 7N :distance 6N :connection 11N :direction 3N}
             (dagen/werk-tellingen (-' f 2N) (+' f 3N))))
      (is (= {:action 7N :target 4N :distance 6N :connection 11N :direction 1N}
             (dagen/werk-tellingen (+' f 3N) (-' f 2N))))
      (is (= {:action 1N :target 1N :distance 1N :connection 2N :direction 2N}
             (dagen/werk-tellingen f f))))))

(deftest grote-exacte-getallen
  (testing "Zonder floating point of integer-overloop."
    (let [groot (reduce *' 1N (repeat 120 10N))
          f dagen/stichtingsdag]
      (is (= (+' 1N (*' 2N (-' groot f)))
             (dagen/dagtelling groot)))
      (is (= (*' 2N (-' f (-' groot)))
             (dagen/dagtelling (-' groot))))
      (is (= (+' groot 2N)
             (:distance (dagen/werk-tellingen (-' groot) 1N)))))))

(deftest differentieel-kleine-matrix
  (testing "49 paren: productie tegenover het testorakel van dezelfde tak."
    (let [f dagen/stichtingsdag]
      (doseq [a (range -3 4)
              b (range -3 4)]
        (let [bron (+' f a)
              doel (+' f b)]
          (is (= (orakel/work-counts bron doel)
                 (dagen/werk-tellingen bron doel))))))))

(deftest invoer-en-productiegrens
  (testing "Ongeldige inputs en eerlijke onvolledigheid van het datumtraject."
    (is (= :invalid-day (foutcode #(dagen/dagtelling 0.5))))
    (is (= :invalid-day (foutcode #(dagen/werk-tellingen nil 1N))))
    (is (= :invalid-day (foutcode #(dagen/werk-tellingen 1N "morgen"))))
    (let [gegevens (foutgegevens #(monster/calendar-date-spaghetti
                                    dagen/stichtingsdag dagen/stichtingsdag))]
      (is (= :production-path-not-yet-built (:code gegevens)))
      (is (= :stage02-discovery01 (:phase gegevens)))
      (is (= :day-counts (:completed gegevens))))))
