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
