(ns pastafari.datumprojectie
  (:require [pastafari.maandrang :as rang]
            [pastafari.maandweving :as weving]
            [pastafari.maandnamen :as namen]
            [pastafari.maandlengtes :as lengtes]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY23: een eindige projectie, geen nieuwe selectieprocedure.
;; De bron van de volledige jaarstructuur is de opt-in, budgetbewezen keten.
;; Het normatieve orakel komt uitsluitend voor in de tests.

(defn- weigering [code]
  (throw (ex-info "Vijf numerieke datumvelden zijn niet bewezen voor deze structuur."
                  {:code code})))

(defn- geldige-delen? [delen begin einde]
  (and (vector? delen)
       (<= 6 (count delen) 17)
       (every? (fn [deel]
                 (and (map? deel)
                      (integer? (:name-index deel))
                      (<= 1N (:name-index deel) 17N)
                      (integer? (:first-day deel))
                      (integer? (:last-day deel))
                      (<= (:first-day deel) (:last-day deel))))
               delen)
       (= (count delen) (count (set (map :name-index delen))))
       (= begin (:first-day (first delen)))
       (= einde (:last-day (peek delen)))
       (every? (fn [[links rechts]]
                 (= (inc (:last-day links)) (:first-day rechts)))
               (partition 2 1 delen))))

(defn- geldige-maanden? [basis duur]
  (let [{:keys [month-count month-lengths month-weaving
                month-name-indices]} basis]
    (and (integer? month-count)
         (<= 3N month-count 47N)
         (vector? month-lengths)
         (= month-count (count month-lengths))
         (every? #(and (integer? %) (<= 4N % 123N)) month-lengths)
         (= duur (reduce +' 0N month-lengths))
         (vector? month-weaving)
         (= duur (count month-weaving))
         (every? #(and (integer? %) (<= 1N % month-count))
                 month-weaving)
         (let [aantallen (frequencies month-weaving)]
           (= month-lengths
              (mapv #(get aantallen % 0)
                    (range 1 (inc month-count)))))
         (vector? month-name-indices)
         (= month-count (count month-name-indices))
         (every? #(and (integer? %) (<= 1N % 47N))
                 month-name-indices)
         (= month-count (count (set month-name-indices))))))

(defn projecteer-bewezen-dag
  "Projecteer één bewezen doeljaar naar exact vijf numerieke velden.
   Maximaal 5778 dagposities, 47 maanden en 17 koteletten. Geen orakel."
  [basis doeldag]
  (when-not (and (map? basis)
                 (map? (:year basis))
                 (integer? (get-in basis [:year :number]))
                 (integer? (get-in basis [:year :open-gate-day]))
                 (integer? (get-in basis [:year :close-gate-day])))
    (weigering :invalid-date-projection-structure))
  (let [{:keys [year cutlets month-weaving month-name-indices]} basis
        open (:open-gate-day year)
        close (:close-gate-day year)
        duur (-' close open)]
    (when-not (<= 252N duur 5778N)
      (weigering :invalid-date-projection-structure))
    (when-not (and (integer? doeldag) (< open doeldag) (<= doeldag close))
      (weigering :target-day-outside-proven-year))
    (when-not (and (geldige-delen? cutlets (inc open) close)
                   (geldige-maanden? basis duur))
      (weigering :invalid-date-projection-structure))
    (let [dagindex (int (-' doeldag (inc open)))
          kotelet (some #(when (<= (:first-day %) doeldag (:last-day %)) %)
                        cutlets)
          maand-id (nth month-weaving dagindex)
          maandnaam (nth month-name-indices (dec maand-id))
          dag-in-maand (reduce (fn [n id] (if (= id maand-id) (inc n) n))
                              0
                              (subvec month-weaving 0 (inc dagindex)))]
      (when-not kotelet
        (weigering :date-cutlet-not-found))
      [(:number year)
       (:name-index kotelet)
       (inc (-' doeldag (:first-day kotelet)))
       maandnaam
       dag-in-maand])))

(defn kies-bewezen-datum
  "Opt-in: behoud bewijsvelden, voeg alleen :date-components toe.
   De bestaande maand- en naamkeuzen blijven budgetbeperkt."
  ([lijn berekeningsdag doeldag]
   (kies-bewezen-datum lijn berekeningsdag doeldag 128N 5000000N))
  ([lijn berekeningsdag doeldag zoekbudget celbudget]
   (let [basis (namen/kies-maandnamen
                lijn berekeningsdag doeldag zoekbudget celbudget)]
     (assoc basis :date-components
            (projecteer-bewezen-dag basis doeldag)))))


;; DIAG03: iedere geldige maandweving begint met maand 1.
;; Alleen de EERSTE jaardag kan zonder het volledige woord worden bewezen.
(defn kies-eerste-dag-zonder-weving
  "Vijf numerieke velden voor uitsluitend de eerste dag van een bewezen jaar."
  ([lijn berekeningsdag doeldag]
   (kies-eerste-dag-zonder-weving lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag zoekbudget]
   (let [{:keys [year cutlets month-count month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag zoekbudget)
         open (:open-gate-day year)
         close (:close-gate-day year)
         eerste (inc open)]
     (when-not (= doeldag eerste)
       (weigering :target-not-first-day-of-year))
     (when-not (and (geldige-delen? cutlets eerste close)
                    (integer? month-count)
                    (<= 3N month-count 47N)
                    (vector? month-lengths)
                    (= month-count (count month-lengths))
                    (every? #(and (integer? %) (<= 4N % 123N)) month-lengths)
                    (= (-' close open) (reduce +' 0N month-lengths)))
       (weigering :invalid-date-projection-structure))
     (let [totaal (namen/aantal-maandnaamreeksen 47N month-count)
           saus (verdelingen/structuur-saus berekeningsdag year)
           stroom (keuzes/vraag-kom saus 5N 33N)
           naamrang (keuzes/kies-rang stroom totaal)
           eerste-maandnaam (first
                              (namen/maandnamen-op-rang 47N month-count naamrang))]
       (assoc basis
              :date-components [(:number year)
                                (:name-index (first cutlets))
                                1N eerste-maandnaam 1N]
              :date-proof-scope :first-day-only
              :month-weaving-computed? false)))))


;; DISCOVERY24 DIAG04. In een legale weving sluiten de maanden in de
;; volgorde 1..m. Daarom is het LAATSTE symbool maand-ID m. Op de laatste
;; jaardag is de dag-in-maand exact de lengte van maand m. Dit is een
;; afzonderlijke begrensde projectie, geen algemene weaving-unrank.
(defn kies-laatste-dag-zonder-weving
  "Exact vijf datumvelden uitsluitend voor de laatste dag van het bewezen jaar."
  ([lijn berekeningsdag doeldag]
   (kies-laatste-dag-zonder-weving lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag zoekbudget]
   (let [{:keys [year cutlets month-count month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag zoekbudget)
         open (:open-gate-day year)
         close (:close-gate-day year)]
     (when-not (= doeldag close)
       (weigering :target-not-last-day-of-year))
     (when-not (and (geldige-delen? cutlets (inc open) close)
                    (integer? month-count)
                    (<= 3N month-count 47N)
                    (vector? month-lengths)
                    (= month-count (count month-lengths))
                    (every? #(and (integer? %) (<= 4N % 123N)) month-lengths)
                    (= (-' close open) (reduce +' 0N month-lengths)))
       (weigering :invalid-date-projection-structure))
     (let [totaal (namen/aantal-maandnaamreeksen 47N month-count)
           saus (verdelingen/structuur-saus berekeningsdag year)
           stroom (keuzes/vraag-kom saus 5N 33N)
           naamrang (keuzes/kies-rang stroom totaal)
           laatste-maandnaam (peek
                               (namen/maandnamen-op-rang 47N month-count naamrang))
           laatste-kotelet (peek cutlets)]
       (assoc basis
              :date-components [(:number year)
                                (:name-index laatste-kotelet)
                                (inc (-' close (:first-day laatste-kotelet)))
                                laatste-maandnaam
                                (peek month-lengths)]
              :date-proof-scope :last-day-only
              :month-weaving-computed? false)))))


;; DISCOVERY24 DIAG05: exacte tweede jaardag via twee-prefixrang.
;; De bestaande algemene datumprojectie en budgetpoort blijven ongewijzigd.
(defn kies-tweede-dag-zonder-weving
  "Vijf velden uitsluitend op de tweede jaardag; geen volledig maandwoord."
  ([lijn berekeningsdag doeldag]
   (kies-tweede-dag-zonder-weving lijn berekeningsdag doeldag 128N 5000000N))
  ([lijn berekeningsdag doeldag zoekbudget prefixbudget]
   (let [{:keys [year cutlets month-count month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag zoekbudget)
         open (:open-gate-day year)
         close (:close-gate-day year)]
     (when-not (= doeldag (+' open 2N))
       (weigering :target-not-second-day-of-year))
     (when-not (and (geldige-delen? cutlets (inc open) close)
                    (integer? month-count) (<= 3N month-count 47N)
                    (vector? month-lengths)
                    (= month-count (count month-lengths))
                    (every? #(and (integer? %) (<= 4N % 123N)) month-lengths)
                    (= (-' close open) (reduce +' 0N month-lengths)))
       (weigering :invalid-date-projection-structure))
     (let [totaal (weving/aantal-wevingen-groot month-lengths)
           saus (verdelingen/structuur-saus berekeningsdag year)
           weefrang (keuzes/kies-rang
                     (keuzes/vraag-kom saus 4N 32N) totaal)
           prefix (rang/tweede-maand-op-rang-groot
                   month-lengths weefrang prefixbudget)
           naam-totaal (namen/aantal-maandnaamreeksen 47N month-count)
           naamrang (keuzes/kies-rang
                     (keuzes/vraag-kom saus 5N 33N) naam-totaal)
           maandnamen (namen/maandnamen-op-rang 47N month-count naamrang)
           maand-id (:month-id prefix)
           kotelet (some #(when (<= (:first-day %) doeldag (:last-day %)) %)
                         cutlets)]
       (when-not kotelet
         (weigering :date-cutlet-not-found))
       (assoc basis
              :date-components [(:number year)
                                (:name-index kotelet)
                                (inc (-' doeldag (:first-day kotelet)))
                                (nth maandnamen (dec (int maand-id)))
                                (:day-in-month prefix)]
              :month-prefix (:month-prefix prefix)
              :month-prefix-cell-upper-bound (:prefix-cell-upper-bound prefix)
              :date-proof-scope :second-day-prefix-only
              :month-weaving-computed? false)))))


;; DISCOVERY24 DIAG06: uitsluitend de derde jaardag, zonder volledige weving.
(defn kies-derde-dag-zonder-weving
  "Opt-in; vijf numerieke velden met exacte, begrensde drieletterprefix."
  ([lijn berekeningsdag doeldag]
   (kies-derde-dag-zonder-weving lijn berekeningsdag doeldag 128N 5000000N))
  ([lijn berekeningsdag doeldag zoekbudget prefixbudget]
   (let [{:keys [year cutlets month-count month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag zoekbudget)
         open (:open-gate-day year)
         close (:close-gate-day year)]
     (when-not (= doeldag (+' open 3N))
       (weigering :target-not-third-day-of-year))
     (when-not (and (geldige-delen? cutlets (inc open) close)
                    (integer? month-count) (<= 3N month-count 47N)
                    (vector? month-lengths)
                    (= month-count (count month-lengths))
                    (every? #(and (integer? %) (<= 4N % 123N)) month-lengths)
                    (= (-' close open) (reduce +' 0N month-lengths)))
       (weigering :invalid-date-projection-structure))
     (let [totaal (weving/aantal-wevingen-groot month-lengths)
           saus (verdelingen/structuur-saus berekeningsdag year)
           weefrang (keuzes/kies-rang
                     (keuzes/vraag-kom saus 4N 32N) totaal)
           prefix (rang/derde-maand-op-rang-groot
                   month-lengths weefrang prefixbudget)
           naam-totaal (namen/aantal-maandnaamreeksen 47N month-count)
           naamrang (keuzes/kies-rang
                     (keuzes/vraag-kom saus 5N 33N) naam-totaal)
           maandnamen (namen/maandnamen-op-rang 47N month-count naamrang)
           maand-id (:month-id prefix)
           kotelet (some #(when (<= (:first-day %) doeldag (:last-day %)) %)
                         cutlets)]
       (when-not kotelet
         (weigering :date-cutlet-not-found))
       (assoc basis
              :date-components [(:number year)
                                (:name-index kotelet)
                                (inc (-' doeldag (:first-day kotelet)))
                                (nth maandnamen (dec (int maand-id)))
                                (:day-in-month prefix)]
              :month-prefix (:month-prefix prefix)
              :month-prefix-cell-upper-bound (:prefix-cell-upper-bound prefix)
              :date-proof-scope :third-day-prefix-only
              :month-weaving-computed? false)))))

;; DIAG08: afzonderlijke vierde-jaardagprojectie, met bestaande 5000000N-gate.
(defn kies-vierde-dag-zonder-weving
  "Opt-in; vijf numerieke velden met exacte, begrensde vierletterprefix."
  ([lijn berekeningsdag doeldag]
   (kies-vierde-dag-zonder-weving lijn berekeningsdag doeldag 128N 5000000N))
  ([lijn berekeningsdag doeldag zoekbudget prefixbudget]
   (let [{:keys [year cutlets month-count month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag zoekbudget)
         open (:open-gate-day year)
         close (:close-gate-day year)]
     (when-not (= doeldag (+' open 4N))
       (weigering :target-not-fourth-day-of-year))
     (when-not (and (geldige-delen? cutlets (inc open) close)
                    (integer? month-count) (<= 3N month-count 47N)
                    (vector? month-lengths)
                    (= month-count (count month-lengths))
                    (every? #(and (integer? %) (<= 4N % 123N)) month-lengths)
                    (= (-' close open) (reduce +' 0N month-lengths)))
       (weigering :invalid-date-projection-structure))
     (let [totaal (weving/aantal-wevingen-groot month-lengths)
           saus (verdelingen/structuur-saus berekeningsdag year)
           weefrang (keuzes/kies-rang
                     (keuzes/vraag-kom saus 4N 32N) totaal)
           prefix (rang/vierde-maand-op-rang-groot
                   month-lengths weefrang prefixbudget)
           naam-totaal (namen/aantal-maandnaamreeksen 47N month-count)
           naamrang (keuzes/kies-rang
                     (keuzes/vraag-kom saus 5N 33N) naam-totaal)
           maandnamen (namen/maandnamen-op-rang 47N month-count naamrang)
           maand-id (:month-id prefix)
           kotelet (some #(when (<= (:first-day %) doeldag (:last-day %)) %)
                         cutlets)]
       (when-not kotelet
         (weigering :date-cutlet-not-found))
       (assoc basis
              :date-components [(:number year)
                                (:name-index kotelet)
                                (inc (-' doeldag (:first-day kotelet)))
                                (nth maandnamen (dec (int maand-id)))
                                (:day-in-month prefix)]
              :month-prefix (:month-prefix prefix)
              :month-prefix-cell-upper-bound (:prefix-cell-upper-bound prefix)
              :date-proof-scope :fourth-day-prefix-only
              :month-weaving-computed? false)))))