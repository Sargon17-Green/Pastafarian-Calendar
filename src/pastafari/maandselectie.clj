(ns pastafari.maandselectie
  (:require [pastafari.maandlengtes :as lengtes]
            [pastafari.maandprofiel :as profiel]
            [pastafari.maandrang :as rang]
            [pastafari.maandweving :as weving]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY21: opt-in selectie, uitsluitend als de gesloten
;; celkostbovengrens het gevraagde budget dekt.
;; De bestaande begrensde maandweving-API wordt niet gewijzigd.
(defn kies-bewezen-maandweving
  "Kies maandweving met kom 4/zegel 32, alleen bij bewezen celbudget.
   Voegt uitsluitend maandweving en bewijsmetadata aan de bestaande
   jaar-/kotelet-/maandlengtevelden toe; geeft GEEN vijfdelige datum."
  ([lijn berekeningsdag doeldag]
   (kies-bewezen-maandweving lijn berekeningsdag doeldag 128N 5000000N))
  ([lijn berekeningsdag doeldag zoekbudget celbudget]
   (let [{:keys [year month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag zoekbudget)
         bewijs (profiel/veilige-celgrens month-lengths celbudget)]
     (when-not (:budgetveilig? bewijs)
       (throw (ex-info "De maandweefselectie is buiten de bewezen celbegroting."
                       {:code :weaving-unrank-budget-unproven
                        :required (:celbovengrens bewijs)
                        :available celbudget})))
     (let [totaal (weving/aantal-wevingen-groot month-lengths)
           saus (verdelingen/structuur-saus berekeningsdag year)
           stroom (keuzes/vraag-kom saus 4N 32N)
           gekozen-rang (keuzes/kies-rang stroom totaal)
           woord (rang/weving-op-rang-groot month-lengths gekozen-rang celbudget)]
       (assoc basis
              :month-weaving woord
              :month-weaving-family-count totaal
              :month-weaving-cell-bound (:celbovengrens bewijs))))))
