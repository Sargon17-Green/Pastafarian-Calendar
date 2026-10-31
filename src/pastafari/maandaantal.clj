(ns pastafari.maandaantal
  (:require [pastafari.koteletgrenzen :as grenzen]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY15: eindige aantalfamilie, nog geen maandlengtes of datum.
(defn- fout [code]
  (throw (ex-info "Het maandaantal is niet bewezen." {:code code})))

(defn mogelijke-maandaantallen
  "Alle 3..47 aantallen met maandlengtes tussen 4 en 123."
  [jaar]
  (when-not (and (map? jaar)
                 (integer? (:open-gate-day jaar))
                 (integer? (:close-gate-day jaar))
                 (<= 252N (-' (:close-gate-day jaar)
                               (:open-gate-day jaar)) 5778N))
    (fout :invalid-year-duration))
  (let [duur (-' (:close-gate-day jaar) (:open-gate-day jaar))]
    ;; Onafhankelijke begrensde enumeratie; norm gebruikt ceil/floor.
    (filterv (fn [m] (<= (*' 4N m) duur (*' 123N m)))
             (range 3 48))))

(defn kies-maandaantal
  "Behoud de koteletgrenzen; selecteer aantal via kom 3, zegel 30."
  ([lijn berekeningsdag doeldag]
   (kies-maandaantal lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag budget]
   (let [{:keys [year] :as basis}
         (grenzen/kies-koteletten lijn berekeningsdag doeldag budget)
         kandidaten (mogelijke-maandaantallen year)
         saus (verdelingen/structuur-saus berekeningsdag year)
         stroom (keuzes/vraag-kom saus 3N 30N)
         rang (keuzes/kies-rang stroom (count kandidaten))]
     (assoc basis
            :month-count (nth kandidaten (dec (int rang)))
            :month-count-options (count kandidaten)))))
