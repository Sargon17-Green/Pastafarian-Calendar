(ns pastafari.doeljaar
  (:require [pastafari.jaargrenzen :as jaren]
            [pastafari.poortposities :as poorten]))

;; DISCOVERY10. Zoek alleen binnen een bewezen poortlijn; maak geen nieuwe poorten.
;; De straal van de lijn is al begrensd op 128 (maximaal 257 poorten).
(def maximale-jaarstappen 128N)

(defn- fout [code]
  (throw (ex-info "Doeljaar niet bewezen binnen de zoekgrenzen." {:code code})))

(defn- controleer-dag [dag]
  (when-not (integer? dag) (fout :invalid-day))
  dag)

(defn- controleer-budget [budget]
  (when-not (and (integer? budget)
                 (<= 0N budget maximale-jaarstappen))
    (fout :invalid-step-budget))
  budget)

(defn- controleer-doeldekking [lijn doeldag]
  ;; poortdag valideert de volledige lijn. Buiten beide grenzen is niets bewezen.
  (poorten/poortdag lijn 0N)
  (let [straal (:straal lijn)]
    (when-not (<= (poorten/poortdag lijn (-' straal))
                  doeldag
                  (poorten/poortdag lijn straal))
      (fout :year-window-unproven))))

(defn vind-doeljaar
  "Zoek het unieke opeenvolgende jaar dat open < doeldag <= sluit bevat.
   Gebruik maximaal budget jaarovergangen (standaard 128). Falen is expliciet:
   geen extrapolatie, geen onbegrensde lussen, geen testoracle in productie."
  ([lijn berekeningsdag doeldag]
   (vind-doeljaar lijn berekeningsdag doeldag maximale-jaarstappen))
  ([lijn berekeningsdag doeldag budget]
   (controleer-dag berekeningsdag)
   (controleer-dag doeldag)
   (controleer-budget budget)
   (controleer-doeldekking lijn doeldag)
   (loop [jaar (jaren/jaar5000 lijn berekeningsdag)
          stappen 0N]
     (cond
       (and (< (:open-gate-day jaar) doeldag)
            (<= doeldag (:close-gate-day jaar)))
       jaar

       (>= stappen budget)
       (fout :year-step-budget-exhausted)

       (> doeldag (:close-gate-day jaar))
       (let [volgend (jaren/volgend-jaar lijn berekeningsdag jaar)]
         (when-not (and (= (:open-gate-index volgend) (:close-gate-index jaar))
                        (> (:close-gate-index volgend) (:close-gate-index jaar))
                        (= (:number volgend) (inc (:number jaar))))
           (fout :year-search-nonprogress))
         (recur volgend (inc stappen)))

       :else
       (let [vorig (jaren/vorig-jaar lijn berekeningsdag jaar)]
         (when-not (and (= (:close-gate-index vorig) (:open-gate-index jaar))
                        (< (:open-gate-index vorig) (:open-gate-index jaar))
                        (= (:number vorig) (dec (:number jaar))))
           (fout :year-search-nonprogress))
         (recur vorig (inc stappen)))))))