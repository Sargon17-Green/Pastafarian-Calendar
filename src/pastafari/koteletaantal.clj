(ns pastafari.koteletaantal
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.doeljaar :as doeljaar]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.saus :as saus]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY11: alleen het aantal koteletten, niet hun verdeling of namen.
;; De jaargrenzen komen uit de reeds bewezen begrensde doeljaarzoekactie.
(def minimum-koteletten 6N)
(def maximum-koteletten 17N)
(def maximaal-poortgaten 256N)
(def ^:private zegel-koteletaantal 20N)

(defn- fout [code]
  (throw (ex-info "Het koteletaantal is niet bewezen voor deze invoer."
                  {:code code})))

(defn kandidaat-aantallen [poortgaten]
  "Geordende toegestane aantallen: 6..min(17, poortgaten).
   Deze zuivere lijstfunctie bewijst op zichzelf geen kalenderjaar."
  (when-not (and (integer? poortgaten)
                 (<= 0N poortgaten maximaal-poortgaten))
    (fout :invalid-gate-gap-count))
  (let [hoogste (min maximum-koteletten poortgaten)]
    (when (< hoogste minimum-koteletten)
      (fout :no-cutlet-candidates))
    (vec (range 6 (inc (int hoogste))))))

(defn kies-aantal
  "Kies het aantal koteletten voor het bewezen doeljaar.
   Retourneer een tussenresultaat en nooit de vijf datumcomponenten."
  ([lijn berekeningsdag doeldag]
   (kies-aantal lijn berekeningsdag doeldag doeljaar/maximale-jaarstappen))
  ([lijn berekeningsdag doeldag budget]
   (let [jaar (doeljaar/vind-doeljaar lijn berekeningsdag doeldag budget)
         poortgaten (-' (:close-gate-index jaar) (:open-gate-index jaar))
         kandidaten (kandidaat-aantallen poortgaten)
         structuurdag (inc (:open-gate-day jaar))
         tellingen (dagen/werk-tellingen berekeningsdag structuurdag)
         verborgen-druppels (verborgen/verborgen-druppels tellingen)
         zichtbare-druppels (zichtbaar/zichtbare-druppels tellingen verborgen-druppels)
         structuur-saus (saus/saus tellingen zichtbare-druppels)
         stroom (keuzes/vraag-kom structuur-saus 2N zegel-koteletaantal)
         rang (keuzes/kies-rang stroom (count kandidaten))]
     {:year jaar
      :cutlet-count (nth kandidaten (dec (int rang)))
      :candidate-count (count kandidaten)})))
