(ns pastafari.stage02-month-profile-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.maandprofiel :as profiel]
            [pastafari.maandrang :as rang]
            [pastafari.maandweving :as weving]))

(defn- foutcode [f]
  (try (f) nil (catch clojure.lang.ExceptionInfo e (:code (ex-data e)))))

(defn- geldig-woord? [lengtes woord]
  (let [v (vec woord)
        ids (range 1 (inc (count lengtes)))]
    (and (= (reduce + lengtes) (count v))
         (= (vec lengtes)
            (mapv (fn [id] (count (filter #(= id %) v))) ids))
         (apply < (map #(.indexOf v %) ids))
         (apply < (map #(.lastIndexOf v %) ids)))))

(defn- adversariele-rangen [totaal]
  (vec (distinct [1N 2N (quot (inc totaal) 2N) (dec totaal) totaal])))

(deftest bovengrens-met-onafhankelijke-som
  (testing "De gesloten bovengrens overdekt alle positie/kandidaat-paren."
    (doseq [lengtes [[4 4] [4 5 4] [4 4 4 4 4]
                     (vec (repeat 8 4))]]
      (let [{:keys [maanden dagen celbovengrens budgetveilig?
                    looptijd-bewezen?]} (profiel/veilige-celgrens lengtes)
            directe-som
            (reduce +' 0N
                    (for [p (range (int dagen))
                          _ (range maanden)]
                      (+' 1N (*' (inc maanden)
                                  (inc (- dagen p))))))]
        (is (<= directe-som celbovengrens))
        (is budgetveilig?)
        (is (false? looptijd-bewezen?))
        (is (= dagen (reduce +' 0N lengtes)))))))

(deftest vijandige-rangen-tegen-onafhankelijk-klein-dp
  (testing "Eerste, tweede, midden, voorlaatste en laatste rang."
    (doseq [lengtes [[4 4] [4 4 4] [4 5 4] [4 4 4 4 4]]]
      (let [totaal (weving/aantal-wevingen lengtes)
            grens (profiel/veilige-celgrens lengtes)]
        (is (:budgetveilig? grens))
        (doseq [r (adversariele-rangen totaal)]
          (let [start (System/nanoTime)
                werkelijk (rang/weving-op-rang-groot lengtes r)
                ns (- (System/nanoTime) start)
                orakel (weving/weving-op-rang lengtes r)]
            (is (= orakel werkelijk) (str "Rang " r ", lengtes " lengtes))
            (is (geldig-woord? lengtes werkelijk))
            (is (<= 0 ns))
            (println "DISCOVERY20 profile" lengtes "rang" r
                     "duur_ns" ns "budget_upper" (:celbovengrens grens))))))))

(deftest groter-adversarieel-profiel
  (testing "Grote API; valideer het woord, niet de volledige datum."
    (doseq [lengtes [(vec (repeat 6 4)) (vec (repeat 8 4))]]
      (let [totaal (weving/aantal-wevingen-groot lengtes)
            grens (profiel/veilige-celgrens lengtes)]
        (is (:budgetveilig? grens))
        (doseq [r (distinct [1N (quot (inc totaal) 2N) totaal])]
          (let [start (System/nanoTime)
                woord (rang/weving-op-rang-groot lengtes r)
                ns (- (System/nanoTime) start)]
            (is (geldig-woord? lengtes woord))
            (is (<= 0 ns))
            (println "DISCOVERY20 large profile" (count lengtes)
                     "rang" r "duur_ns" ns)))))))

(deftest afwijzingen-en-onveilige-maximale-familie
  (let [maximale-geldige-lengtes (conj (vec (repeat 46 123)) 120)
        {:keys [maanden dagen celbovengrens budgetveilig?]}
        (profiel/veilige-celgrens maximale-geldige-lengtes)]
    (is (= 47 maanden))
    (is (= 5778N dagen))
    (is (> celbovengrens 5000000N))
    (is (false? budgetveilig?)))
  (is (= :weaving-bound-exceeded
         (foutcode #(profiel/veilige-celgrens (vec (repeat 47 123))))))
  (is (false? (:budgetveilig? (profiel/veilige-celgrens [4 4 4] 1N))))
  (doseq [lengtes [nil [] [3] [124] [4 0] "444"]]
    (is (= :invalid-weaving-family
           (foutcode #(profiel/veilige-celgrens lengtes)))))
  (doseq [lengtes [(vec (repeat 48 4)) (vec (repeat 47 124))]]
    (is (#{:invalid-weaving-family :weaving-bound-exceeded}
          (foutcode #(profiel/veilige-celgrens lengtes)))))
  (doseq [begroting [nil 0 -1 1.5 5000001N]]
    (is (= :invalid-weaving-budget
           (foutcode #(profiel/veilige-celgrens [4 4] begroting))))))
