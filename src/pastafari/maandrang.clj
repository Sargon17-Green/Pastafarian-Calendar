(ns pastafari.maandrang
  (:require [pastafari.maandweving :as weving]))

;; Een aparte unranking-API; geen wijziging van de datumkiezer.
(def ^:private hoogste-begroting 5000000N)

(defn- fout [code]
  (throw (ex-info "Grote maandrang is niet bewezen." {:code code})))

(defn- binomiaal [n k]
  (loop [i 1 resultaat 1N]
    (if (> i k)
      resultaat
      (recur (inc i) (quot (*' resultaat (+ (- n k) i)) i)))))

(defn- alleen-laatste [restvector gesloten geopend]
  ;; B=product C(S_i-1,r_i-1) voor de reeds geopende actieve maanden.
  (loop [i gesloten dagen 0 resultaat 1N]
    (if (= i geopend)
      {:dagen dagen :aantal resultaat}
      (let [a (nth restvector i)
            nieuw (+ dagen a)]
        (recur (inc i) nieuw
               (if (= i gesloten)
                 resultaat
                 (*' resultaat (binomiaal (dec nieuw) (dec a)))))))))

(defn- gewichten [b tmax]
  (loop [t 0 w 1N resultaat [1N]]
    (if (= t tmax)
      resultaat
      (let [nieuw (quot (*' w (+ b t -1)) (inc t))]
        (recur (inc t) nieuw (conj resultaat nieuw))))))

(defn- toevoegen [frequenties vrij? basis oude-dagen b]
  ;; Eerste nieuwe maand: u=0 toegestaan; latere: u>=vorige eerste positie.
  ;; Laatste nieuwe letter staat na de laatste oude letter.
  (let [w (gewichten b oude-dagen)]
    (loop [u 0 prefix 0N resultaat [0N]]
      (if (> u oude-dagen)
        resultaat
        (let [som (if vrij? basis (+' prefix (get frequenties u 0N)))]
          (recur (inc u) som
                 (conj resultaat (*' som (nth w (- oude-dagen u))))))))))

(defn- tel-rest [restvector geopend gesloten]
  (if (every? zero? restvector)
    1N
    (let [m (count restvector)
          {:keys [dagen aantal]} (alleen-laatste restvector gesloten geopend)
          [begin totaal init vrij?]
          (if (zero? geopend)
            [1 (first restvector) [0N 1N] false]
            [geopend dagen nil true])]
      (loop [i begin t totaal frequenties init vrij? vrij?]
        (if (= i m)
          (if (nil? frequenties) aantal (reduce +' 0N frequenties))
          (let [b (nth restvector i)
                nieuw (toevoegen frequenties vrij? aantal t b)]
            (recur (inc i) (+ t b) nieuw false)))))))

(defn- raming [restvector geopend]
  (+' 1N (*' (inc (- (count restvector) geopend))
             (inc (reduce + 0 restvector)))))

(defn weving-op-rang-groot
  "Exacte eengebaseerde lexicografische maandweving; buiten begroting fout.
   Nog niet verbonden met de vijfdelige datum."
  ([lengtes rang]
   (weving-op-rang-groot lengtes rang hoogste-begroting))
  ([lengtes rang begroting]
   (let [totaal (weving/aantal-wevingen-groot lengtes)
         begin (mapv int lengtes)
         m (count begin)]
     (when-not (and (integer? rang) (<= 1N rang totaal))
       (fout :invalid-weaving-rank))
     (when-not (and (integer? begroting)
                    (<= 1N begroting hoogste-begroting))
       (fout :invalid-weaving-budget))
     (loop [restvector begin geopend 0 gesloten 0
            huidige-rang rang verbruik 0N antwoord []]
       (if (every? zero? restvector)
         antwoord
         (let [keuze
               (loop [kandidaten (range 1 (inc (min m (inc geopend))))
                      r huidige-rang gebruikt verbruik]
                 (when (empty? kandidaten)
                   (fout :weaving-unrank-failed))
                 (let [maand (first kandidaten)
                       index (dec maand)
                       aantal (nth restvector index)]
                   (if (or (zero? aantal)
                           (and (= aantal 1) (not= maand (inc gesloten))))
                     (recur (rest kandidaten) r gebruikt)
                     (let [volgende (update restvector index dec)
                           open (max geopend maand)
                           dicht (if (= aantal 1) (inc gesloten) gesloten)
                           kosten (+' gebruikt (raming volgende open))]
                       (when (> kosten begroting)
                         (fout :weaving-unrank-budget-exceeded))
                       (let [blok (tel-rest volgende open dicht)]
                         (if (> r blok)
                           (recur (rest kandidaten) (-' r blok) kosten)
                           {:maand maand :restvector volgende :open open
                            :dicht dicht :rang r :kosten kosten}))))))]
           (recur (:restvector keuze) (:open keuze) (:dicht keuze)
                  (:rang keuze) (:kosten keuze)
                  (conj antwoord (:maand keuze)))))))))


;; DISCOVERY24 DIAG05: een exact, budgetbegrensd prefix voor jaardag twee.
;; Iedere legale weving begint met 1; de tweede letter is 1 of 2.
(defn tweede-maand-op-rang-groot
  "Geef de tweede maand-ID zonder de volledige maandweving te bouwen."
  ([lengtes rang]
   (tweede-maand-op-rang-groot lengtes rang hoogste-begroting))
  ([lengtes rang begroting]
   (let [totaal (weving/aantal-wevingen-groot lengtes)
         begin (mapv int lengtes)]
     (when (< (count begin) 2)
       (fout :second-day-needs-two-months))
     (when-not (and (integer? rang) (<= 1N rang totaal))
       (fout :invalid-weaving-rank))
     (when-not (and (integer? begroting)
                    (<= 1N begroting hoogste-begroting))
       (fout :invalid-weaving-budget))
     (let [rest11 (update begin 0 #(- % 2))
           kosten (raming rest11 1)]
       (when (> kosten begroting)
         (fout :second-day-prefix-budget-unproven))
       (let [blok11 (tel-rest rest11 1 0)
             maand (if (<= rang blok11) 1N 2N)]
         (when-not (and (pos? blok11) (< blok11 totaal))
           (fout :second-day-prefix-invalid-count))
         {:month-id maand
          :day-in-month (if (= maand 1N) 2N 1N)
          :month-prefix [1N maand]
          :prefix-block11-count blok11
          :prefix-cell-upper-bound kosten
          :date-proof-scope :second-day-prefix-only
          :month-weaving-computed? false})))))


;; DISCOVERY24 DIAG06: rangschik uitsluitend de eerste drie maandtekens.
;; De reeds bewezen generieke unranking-functie wordt niet aangepast.
(defn derde-maand-op-rang-groot
  "Exacte prefix van drie tekens onder dezelfde gecumuleerde celbegroting."
  ([lengtes rang]
   (derde-maand-op-rang-groot lengtes rang hoogste-begroting))
  ([lengtes rang begroting]
   (let [totaal (weving/aantal-wevingen-groot lengtes)
         begin (mapv int lengtes)
         m (count begin)]
     (when (< m 2)
       (fout :third-day-needs-two-months))
     (when-not (and (integer? rang) (<= 1N rang totaal))
       (fout :invalid-weaving-rank))
     (when-not (and (integer? begroting)
                    (<= 1N begroting hoogste-begroting))
       (fout :invalid-weaving-budget))
     (loop [positie 2
            restvector (update begin 0 dec)
            geopend 1 gesloten 0
            huidige-rang rang verbruik 0N prefix [1N]]
       (if (> positie 3)
         (let [maand (peek prefix)]
           {:month-id maand
            :day-in-month (bigint (count (filter #(= maand %) prefix)))
            :month-prefix prefix
            :prefix-cell-upper-bound verbruik
            :date-proof-scope :third-day-prefix-only
            :month-weaving-computed? false})
         (let [keuze
               (loop [maand 1 r huidige-rang kosten verbruik]
                 (if (> maand (min m (inc geopend)))
                   (fout :third-day-prefix-invalid-count)
                   (let [aantal (nth restvector (dec maand))]
                     (if (or (zero? aantal)
                             (and (= aantal 1)
                                  (not= maand (inc gesloten))))
                       (recur (inc maand) r kosten)
                       (let [volgende (update restvector (dec maand) dec)
                             nieuw-geopend (max geopend maand)
                             nieuw-gesloten (if (= aantal 1)
                                             (inc gesloten) gesloten)
                             nieuw-kosten (+' kosten
                                            (raming volgende nieuw-geopend))]
                         (when (> nieuw-kosten begroting)
                           (fout :third-day-prefix-budget-unproven))
                         (let [blok (tel-rest volgende nieuw-geopend
                                              nieuw-gesloten)]
                           (if (> r blok)
                             (recur (inc maand) (-' r blok) nieuw-kosten)
                             {:maand maand :restvector volgende
                              :geopend nieuw-geopend :gesloten nieuw-gesloten
                              :rang r :kosten nieuw-kosten})))))))]
           (recur (inc positie) (:restvector keuze)
                  (:geopend keuze) (:gesloten keuze)
                  (:rang keuze) (:kosten keuze)
                  (conj prefix (bigint (:maand keuze))))))))))

;; DIAG08: begrensd lexicografisch vierletterprefix, zonder volledige weving.
(defn vierde-maand-op-rang-groot
  "Exacte prefix van vier tekens onder dezelfde gecumuleerde celbegroting."
  ([lengtes rang]
   (vierde-maand-op-rang-groot lengtes rang hoogste-begroting))
  ([lengtes rang begroting]
   (let [totaal (weving/aantal-wevingen-groot lengtes)
         begin (mapv int lengtes)
         m (count begin)]
     (when (< m 2)
       (fout :fourth-day-needs-two-months))
     (when-not (and (integer? rang) (<= 1N rang totaal))
       (fout :invalid-weaving-rank))
     (when-not (and (integer? begroting)
                    (<= 1N begroting hoogste-begroting))
       (fout :invalid-weaving-budget))
     (loop [positie 2
            restvector (update begin 0 dec)
            geopend 1 gesloten 0
            huidige-rang rang verbruik 0N prefix [1N]]
       (if (> positie 4)
         (let [maand (peek prefix)]
           {:month-id maand
            :day-in-month (bigint (count (filter #(= maand %) prefix)))
            :month-prefix prefix
            :prefix-cell-upper-bound verbruik
            :date-proof-scope :fourth-day-prefix-only
            :month-weaving-computed? false})
         (let [keuze
               (loop [maand 1 r huidige-rang kosten verbruik]
                 (if (> maand (min m (inc geopend)))
                   (fout :fourth-day-prefix-invalid-count)
                   (let [aantal (nth restvector (dec maand))]
                     (if (or (zero? aantal)
                             (and (= aantal 1)
                                  (not= maand (inc gesloten))))
                       (recur (inc maand) r kosten)
                       (let [volgende (update restvector (dec maand) dec)
                             nieuw-geopend (max geopend maand)
                             nieuw-gesloten (if (= aantal 1)
                                             (inc gesloten) gesloten)
                             nieuw-kosten (+' kosten
                                            (raming volgende nieuw-geopend))]
                         (when (> nieuw-kosten begroting)
                           (fout :fourth-day-prefix-budget-unproven))
                         (let [blok (tel-rest volgende nieuw-geopend
                                              nieuw-gesloten)]
                           (if (> r blok)
                             (recur (inc maand) (-' r blok) nieuw-kosten)
                             {:maand maand :restvector volgende
                              :geopend nieuw-geopend :gesloten nieuw-gesloten
                              :rang r :kosten nieuw-kosten})))))))]
           (recur (inc positie) (:restvector keuze)
                  (:geopend keuze) (:gesloten keuze)
                  (:rang keuze) (:kosten keuze)
                  (conj prefix (bigint (:maand keuze))))))))))
;; DIAG09: begrensd lexicografisch vierletterprefix, zonder volledige weving.
(defn vijfde-maand-op-rang-groot
  "Exacte prefix van vier tekens onder dezelfde gecumuleerde celbegroting."
  ([lengtes rang]
   (vijfde-maand-op-rang-groot lengtes rang hoogste-begroting))
  ([lengtes rang begroting]
   (let [totaal (weving/aantal-wevingen-groot lengtes)
         begin (mapv int lengtes)
         m (count begin)]
     (when (< m 2)
       (fout :fifth-day-needs-two-months))
     (when-not (and (integer? rang) (<= 1N rang totaal))
       (fout :invalid-weaving-rank))
     (when-not (and (integer? begroting)
                    (<= 1N begroting hoogste-begroting))
       (fout :invalid-weaving-budget))
     (loop [positie 2
            restvector (update begin 0 dec)
            geopend 1 gesloten 0
            huidige-rang rang verbruik 0N prefix [1N]]
       (if (> positie 5)
         (let [maand (peek prefix)]
           {:month-id maand
            :day-in-month (bigint (count (filter #(= maand %) prefix)))
            :month-prefix prefix
            :prefix-cell-upper-bound verbruik
            :date-proof-scope :fifth-day-prefix-only
            :month-weaving-computed? false})
         (let [keuze
               (loop [maand 1 r huidige-rang kosten verbruik]
                 (if (> maand (min m (inc geopend)))
                   (fout :fifth-day-prefix-invalid-count)
                   (let [aantal (nth restvector (dec maand))]
                     (if (or (zero? aantal)
                             (and (= aantal 1)
                                  (not= maand (inc gesloten))))
                       (recur (inc maand) r kosten)
                       (let [volgende (update restvector (dec maand) dec)
                             nieuw-geopend (max geopend maand)
                             nieuw-gesloten (if (= aantal 1)
                                             (inc gesloten) gesloten)
                             nieuw-kosten (+' kosten
                                            (raming volgende nieuw-geopend))]
                         (when (> nieuw-kosten begroting)
                           (fout :fifth-day-prefix-budget-unproven))
                         (let [blok (tel-rest volgende nieuw-geopend
                                              nieuw-gesloten)]
                           (if (> r blok)
                             (recur (inc maand) (-' r blok) nieuw-kosten)
                             {:maand maand :restvector volgende
                              :geopend nieuw-geopend :gesloten nieuw-gesloten
                              :rang r :kosten nieuw-kosten})))))))]
           (recur (inc positie) (:restvector keuze)
                  (:geopend keuze) (:gesloten keuze)
                  (:rang keuze) (:kosten keuze)
                  (conj prefix (bigint (:maand keuze))))))))))

;; DIAG10: afzonderlijk exact zesletterprefix, budget onveranderd.
(defn zesde-maand-op-rang-groot
  "Exacte prefix van zes tekens onder dezelfde gecumuleerde celbegroting."
  ([lengtes rang]
   (zesde-maand-op-rang-groot lengtes rang hoogste-begroting))
  ([lengtes rang begroting]
   (let [totaal (weving/aantal-wevingen-groot lengtes)
         begin (mapv int lengtes)
         m (count begin)]
     (when (< m 2)
       (fout :sixth-day-needs-two-months))
     (when-not (and (integer? rang) (<= 1N rang totaal))
       (fout :invalid-weaving-rank))
     (when-not (and (integer? begroting)
                    (<= 1N begroting hoogste-begroting))
       (fout :invalid-weaving-budget))
     (loop [positie 2
            restvector (update begin 0 dec)
            geopend 1 gesloten 0
            huidige-rang rang verbruik 0N prefix [1N]]
       (if (> positie 6)
         (let [maand (peek prefix)]
           {:month-id maand
            :day-in-month (bigint (count (filter #(= maand %) prefix)))
            :month-prefix prefix
            :prefix-cell-upper-bound verbruik
            :date-proof-scope :sixth-day-prefix-only
            :month-weaving-computed? false})
         (let [keuze
               (loop [maand 1 r huidige-rang kosten verbruik]
                 (if (> maand (min m (inc geopend)))
                   (fout :sixth-day-prefix-invalid-count)
                   (let [aantal (nth restvector (dec maand))]
                     (if (or (zero? aantal)
                             (and (= aantal 1)
                                  (not= maand (inc gesloten))))
                       (recur (inc maand) r kosten)
                       (let [volgende (update restvector (dec maand) dec)
                             nieuw-geopend (max geopend maand)
                             nieuw-gesloten (if (= aantal 1)
                                             (inc gesloten) gesloten)
                             nieuw-kosten (+' kosten
                                            (raming volgende nieuw-geopend))]
                         (when (> nieuw-kosten begroting)
                           (fout :sixth-day-prefix-budget-unproven))
                         (let [blok (tel-rest volgende nieuw-geopend
                                              nieuw-gesloten)]
                           (if (> r blok)
                             (recur (inc maand) (-' r blok) nieuw-kosten)
                             {:maand maand :restvector volgende
                              :geopend nieuw-geopend :gesloten nieuw-gesloten
                              :rang r :kosten nieuw-kosten})))))))]
           (recur (inc positie) (:restvector keuze)
                  (:geopend keuze) (:gesloten keuze)
                  (:rang keuze) (:kosten keuze)
                  (conj prefix (bigint (:maand keuze))))))))))
