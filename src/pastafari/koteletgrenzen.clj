(ns pastafari.koteletgrenzen
  (:require [pastafari.koteletnamen :as namen]
            [pastafari.poortposities :as poorten]))

;; DISCOVERY14: alleen bewezen poortindices, geen extrapolatie.
(defn- fout [code]
  (throw (ex-info "De koteletgrenzen zijn niet bewezen." {:code code})))

(defn materialiseer-koteletten [lijn basis]
  "Behoud de bewezen partitie en namen; voeg exacte poortdagen toe."
  (when-not (and (map? basis) (map? (:year basis)))
    (fout :invalid-cutlet-materialization))
  (let [{:keys [year cutlet-count partition name-indices required-boundary]} basis
        open (:open-gate-index year)
        close (:close-gate-index year)]
    (when-not (and (integer? open) (integer? close) (< open close)
                   (<= 6N (-' close open) 256N)
                   (integer? cutlet-count) (<= 6N cutlet-count 17N)
                   (vector? partition) (= cutlet-count (count partition))
                   (every? #(and (integer? %) (pos? %)) partition)
                   (= (-' close open) (reduce +' 0N partition)))
      (fout :invalid-cutlet-materialization))
    (when-not (and (vector? name-indices)
                   (= cutlet-count (count name-indices))
                   (every? #(and (integer? %) (<= 1N % 17N)) name-indices)
                   (= (count name-indices) (count (distinct name-indices))))
      (fout :invalid-cutlet-name-indices))
    (when-not (or (nil? required-boundary)
                  (and (integer? required-boundary)
                       (< 0N required-boundary (-' close open))
                       (some #{required-boundary}
                             (rest (butlast (reductions +' 0N partition))))))
      (fout :invalid-cutlet-required-boundary))
    (let [eerste (poorten/poortdag lijn open)
          laatste (poorten/poortdag lijn close)]
      (when-not (and (= eerste (:open-gate-day year))
                     (= laatste (:close-gate-day year)))
        (fout :invalid-proven-year))
      (let [indices (vec (reductions +' open partition))
            delen (mapv (fn [naam a b]
                          {:name-index naam
                           :open-gate-index a
                           :close-gate-index b
                           :first-day (inc (poorten/poortdag lijn a))
                           :last-day (poorten/poortdag lijn b)})
                        name-indices (butlast indices) (rest indices))]
        (assoc basis :cutlets delen)))))

(defn kies-koteletten
  "Bereken eerst de DISCOVERY13-naamkeuze; materialiseer pas daarna."
  ([lijn berekeningsdag doeldag]
   (kies-koteletten lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag budget]
   (materialiseer-koteletten
    lijn (namen/kies-namen lijn berekeningsdag doeldag budget))))
