(ns pastafari.datumprojectie
  (:require [pastafari.maandnamen :as namen]))

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
                month-name-indices]} basis
        aantallen (when (vector? month-weaving) (frequencies month-weaving))]
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
         (= month-lengths
            (mapv #(get aantallen % 0)
                  (range 1 (inc month-count))))
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
