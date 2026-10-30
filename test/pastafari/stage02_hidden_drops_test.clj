(ns pastafari.stage02-hidden-drops-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.verborgen-druppels :as druppels]
            [pastafari.normative-oracle :as orakel]
            [pastafari.stenen :as stenen]))

(defn- reken [berekening doel]
  (druppels/verborgen-druppels
   (dagen/werk-tellingen berekening doel)))

(defn- foutcode [bewerking]
  (try (bewerking)
       nil
       (catch clojure.lang.ExceptionInfo e
         (:code (ex-data e)))))

(deftest vaste-ankers-uit-onafhankelijke-rekenweg
  (testing "Zeven waarden, tweemaal buiten het testorakel berekend."
    (is (= [119390830530032782664128530203002080344N
            11877236279154673426874867061566696749N
            24217814924229232987463457533828175476N
            166629231917547214614573522551290204247N
            81202913407267092008896220686064041568N
            73551520026920072430116213847585486272N
            6164285870955721082771365327359496898N]
           (reken -15055671N -15055671N)))
    (is (= [160342090669779519805299934758026027361N
            52880141811156006961845125730628264126N
            96856167816809361809155514813407213447N
            45640421104019478880925694743388098484N
            145027844735351299830457620284549992010N
            44867465635500913111739695355535534529N
            91227179715862036446805369256398356137N]
           (reken -15055673N -15055668N)))))

(deftest differentieel-49-dagparen
  (testing "343 onafhankelijke vergelijkingen van zeven druppels met het testorakel."
    (let [stichting dagen/stichtingsdag]
      (doseq [a (range -3 4)
              b (range -3 4)]
        (let [bron (+' stichting a)
              doel (+' stichting b)
              tellingen (dagen/werk-tellingen bron doel)
              productie (druppels/verborgen-druppels tellingen)
              verwacht (orakel/build-hidden-drops
                        (orakel/work-counts bron doel))]
          (doseq [index (range 7)]
            (is (= (nth verwacht index)
                   (nth productie index)))))))))

(deftest alle-waarden-binnen-de-modulus
  (testing "Exact zeven residuen tussen een en M voor extreem grote daggetallen."
    (let [groot (reduce *' 1N (repeat 100 10N))
          waarden (reken (-' groot) groot)]
      (is (= 7 (count waarden)))
      (doseq [waarde waarden]
        (is (and (integer? waarde)
                 (<= 1N waarde stenen/modulus)))))))

(deftest chronologische-richting-heeft-gevolgen
  (testing "Het omkeren van de twee dagen verandert de druppels."
    (let [stichting dagen/stichtingsdag]
      (is (not= (reken (-' stichting 2N) (+' stichting 3N))
                (reken (+' stichting 3N) (-' stichting 2N)))))))

(deftest ongeldige-tellingen-worden-geweigerd
  (testing "Geen impliciete doubles, lege tellingen of foutieve richting."
    (let [geldig (dagen/werk-tellingen dagen/stichtingsdag dagen/stichtingsdag)]
      (is (= :invalid-work-counts
             (foutcode #(druppels/verborgen-druppels nil))))
      (is (= :invalid-work-counts
             (foutcode #(druppels/verborgen-druppels {}))))
      (is (= :invalid-work-counts
             (foutcode #(druppels/verborgen-druppels (assoc geldig :action 1.5)))))
      (is (= :invalid-work-counts
             (foutcode #(druppels/verborgen-druppels (assoc geldig :direction 4)))))
      (is (= :invalid-work-counts
             (foutcode #(druppels/verborgen-druppels (dissoc geldig :target))))))))
