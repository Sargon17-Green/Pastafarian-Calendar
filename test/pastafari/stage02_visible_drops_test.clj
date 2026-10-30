(ns pastafari.stage02-visible-drops-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.normative-oracle :as orakel]
            [pastafari.stenen :as stenen]))

(defn- bereken [bron doel]
  (let [tellingen (dagen/werk-tellingen bron doel)]
    (zichtbaar/zichtbare-druppels
     tellingen (verborgen/verborgen-druppels tellingen))))

(defn- foutcode [bewerking]
  (try (bewerking)
       nil
       (catch clojure.lang.ExceptionInfo e
         (:code (ex-data e)))))

(deftest vaste-ankers-zonder-orakel
  (testing "Twee onafhankelijke invoerparen: begin, einde en sommodulus."
    (let [a (bereken -15055671N -15055671N)
          b (bereken -15055673N -15055668N)]
      (is (= 46 (count a)))
      (is (= 46 (count b)))
      (is (= [56644603826892212324764499696091907135N
              68953726611520950166075866637346981907N
              156248044892837952734926746199182095252N]
             (subvec a 0 3)))
      (is (= [66534692871825902579488225144948967863N
              141872771689426650819909896585756512282N]
             (subvec a 44 46)))
      (is (= 73196228498192230556730796012158569984N
             (stenen/save (reduce +' 0N a))))
      (is (= [30049950636190195007738971713454624345N
              39671331864868647782722892800081971458N
              9183844334509438246826772787946029406N]
             (subvec b 0 3)))
      (is (= [121906729444510755001420551745470684769N
              4383151497201658882722252957306928168N]
             (subvec b 44 46)))
      (is (= 34613937848949945460804300202004369555N
             (stenen/save (reduce +' 0N b)))))))

(deftest differentieel-49-dagparen
  (testing "49 invoerparen x 46 differential assertions met testorakel."
    (let [stichting dagen/stichtingsdag]
      (doseq [a (range -3 4)
              b (range -3 4)]
        (let [bron (+' stichting a)
              doel (+' stichting b)
              werk (dagen/werk-tellingen bron doel)
              productie (zichtbaar/zichtbare-druppels
                         werk (verborgen/verborgen-druppels werk))
              orakelwerk (orakel/work-counts bron doel)
              verwacht (orakel/build-visible-drops
                        orakelwerk (orakel/build-hidden-drops orakelwerk))]
          (doseq [index (range 46)]
            (is (= (nth verwacht index)
                   (nth productie index)))))))))

(deftest residuen-richting-en-grote-getallen
  (testing "46 exacte residuen voor extreme daggetallen."
    (let [groot (reduce *' 1N (repeat 100 10N))
          waarden (bereken (-' groot) groot)]
      (is (= 46 (count waarden)))
      (is (every? #(and (integer? %)
                        (<= 1N % stenen/modulus)) waarden))))
  (testing "Omgekeerde dagrichting verandert het resultaat."
    (let [stichting dagen/stichtingsdag]
      (is (not= (bereken (-' stichting 2N) (+' stichting 3N))
                (bereken (+' stichting 3N) (-' stichting 2N)))))))

(deftest ongeldige-invoer-wordt-geweigerd
  (let [werk (dagen/werk-tellingen dagen/stichtingsdag dagen/stichtingsdag)
        goed (verborgen/verborgen-druppels werk)]
    (is (= :invalid-visible-input
           (foutcode #(zichtbaar/zichtbare-druppels nil goed))))
    (is (= :invalid-visible-input
           (foutcode #(zichtbaar/zichtbare-druppels
                       (assoc werk :direction 4N) goed))))
    (is (= :invalid-visible-input
           (foutcode #(zichtbaar/zichtbare-druppels
                       (assoc werk :target 1.5) goed))))
    (is (= :invalid-visible-input
           (foutcode #(zichtbaar/zichtbare-druppels werk (subvec goed 0 6)))))
    (is (= :invalid-visible-input
           (foutcode #(zichtbaar/zichtbare-druppels
                       werk (assoc goed 0 0N)))))
    (is (= :invalid-visible-input
           (foutcode #(zichtbaar/zichtbare-druppels werk (vec (repeat 7 nil))))))))
