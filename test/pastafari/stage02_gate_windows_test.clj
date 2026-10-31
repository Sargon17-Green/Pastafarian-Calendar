(ns pastafari.stage02-gate-windows-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as posities]
            [pastafari.normative-oracle :as orakel]))

(def ^:private directe-lijn (delay (posities/bouw-poortlijn 128N)))
(def ^:private verlengde-lijn
  (delay (-> (posities/bouw-poortlijn 64N)
             (posities/verleng-poortlijn 65N)
             (posities/verleng-poortlijn 128N))))

(defn- foutcode [f]
  (try (f) nil
       (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(deftest volledig-differentieel-venster
  (testing "257 poortindices, oracle met eigen poortstaat en eigen sauspad."
    (let [lijn @verlengde-lijn
          referentie (orakel/new-gate-state)]
      (is (= 128N (:straal lijn)))
      (is (= 257 (count (:dagen lijn))))
      (doseq [k (range -128 129)]
        (is (= (orakel/ensure-gate-index! referentie k)
               (posities/poortdag lijn k)))
        (is (= (posities/poortdag @directe-lijn k)
               (posities/poortdag lijn k)))))))

(deftest verlenging-bewaart-oude-poorten
  (let [oud (posities/bouw-poortlijn 64N)
        een-stap (posities/verleng-poortlijn oud 65N)
        groot @verlengde-lijn
        nul (posities/bouw-poortlijn 0N)]
    (is (= (:dagen oud) (subvec (:dagen een-stap) 1 130)))
    (is (= (:dagen oud) (subvec (:dagen groot) 64 193)))
    (is (= groot (posities/verleng-poortlijn groot 128N)))
    (is (= [dagen/stichtingsdag] (:dagen nul)))
    (is (= (:dagen (posities/bouw-poortlijn 1N))
           (:dagen (posities/verleng-poortlijn nul 1N))))
    (is (< (posities/poortdag groot -128N)
           (posities/poortdag oud -64N)
           dagen/stichtingsdag
           (posities/poortdag oud 64N)
           (posities/poortdag groot 128N)))))

(deftest halfopen-intervallen-met-zelfstandige-grenzen
  (let [lijn @verlengde-lijn
        referentie (orakel/new-gate-state)]
    (doseq [k [-128 -127 -65 -64 -1 0 63 64 65 127]]
      (let [begin (orakel/ensure-gate-index! referentie k)
            eind (orakel/ensure-gate-index! referentie (inc k))
            lengte (-' eind begin)
            verwacht {:index k :begin begin :eind eind :lengte lengte :positie 0N}]
        (is (<= 42N lengte 963N))
        (is (= verwacht (posities/poortinterval lijn begin)))
        (is (= (assoc verwacht :positie (dec lengte))
               (posities/poortinterval lijn (dec eind))))))
    (let [eind (posities/poortdag lijn 128N)
          begin (posities/poortdag lijn -128N)]
      (is (= :gate-interval-not-proven
             (foutcode #(posities/poortinterval lijn eind))))
      (is (= :day-outside-gate-window
             (foutcode #(posities/poortinterval lijn (dec begin)))))
      (is (= :day-outside-gate-window
             (foutcode #(posities/poortinterval lijn (inc eind))))))))

(deftest begrensde-fouten-en-exacte-getallen
  (let [klein (posities/bouw-poortlijn 1N)
        nul (posities/bouw-poortlijn 0N)
        heel-groot (reduce *' 1N (repeat 101 10N))]
    (is (= :invalid-gate-radius
           (foutcode #(posities/bouw-poortlijn 129N))))
    (is (= :invalid-gate-radius
           (foutcode #(posities/verleng-poortlijn klein 129N))))
    (is (= :invalid-gate-radius
           (foutcode #(posities/verleng-poortlijn klein 1.5))))
    (is (= :cannot-shrink-gate-line
           (foutcode #(posities/verleng-poortlijn klein 0N))))
    (is (= :invalid-gate-line
           (foutcode #(posities/verleng-poortlijn nil 2N))))
    (is (= :gate-interval-not-proven
           (foutcode #(posities/poortinterval nul dagen/stichtingsdag))))
    (is (= :invalid-day
           (foutcode #(posities/poortinterval klein 1.5))))
    (is (= :day-outside-gate-window
           (foutcode #(posities/poortinterval klein heel-groot))))
    (is (= :day-outside-gate-window
           (foutcode #(posities/poortinterval klein (-' heel-groot)))))))
