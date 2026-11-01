(ns pastafari.maandweving
  (:require [pastafari.maandlengtes :as lengtes]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY17: bottom-up DP op restvectoren; geen recursieve teloracle.
(def ^:private maximale-maanden 5)
(def ^:private maximale-dagen 32N)

(defn- fout [code]
  (throw (ex-info "De maandweving is niet bewezen." {:code code})))

(defn- controleer-lengtes [lengtes]
  (when-not (and (sequential? lengtes)
                 (pos? (count lengtes))
                 (every? #(and (integer? %) (<= 4N % 123N)) lengtes))
    (fout :invalid-weaving-family))
  (when (or (> (count lengtes) maximale-maanden)
            (> (reduce +' 0N lengtes) maximale-dagen))
    (fout :weaving-bound-exceeded))
  (mapv int lengtes))

(defn- grensstaat? [lengtes resterend]
  (let [geopend (count (take-while true? (map < resterend lengtes)))
        gesloten (count (take-while zero? resterend))]
    (and (= (subvec resterend geopend) (subvec lengtes geopend))
         (every? pos? (subvec resterend gesloten)))))

(defn- legale-stap? [lengtes resterend geopend gesloten maand]
  (let [index (dec maand)
        rest (nth resterend index)]
    (and (pos? rest)
         (or (< rest (nth lengtes index)) (= maand (inc geopend)))
         (or (> rest 1) (= maand (inc gesloten))))))

(defn- legale-maanden [lengtes resterend]
  (let [geopend (count (take-while true? (map < resterend lengtes)))
        gesloten (count (take-while zero? resterend))]
    (filterv #(legale-stap? lengtes resterend geopend gesloten %)
             (range 1 (inc (count lengtes))))))

(defn- maak-tabel [lengtes]
  ;; Een overgang verlaagt de resterende som precies één; de topologische
  ;; DP enumereert toestanden in plaats van alle lexicografische woorden.
  (let [toestanden (reduce (fn [acc n]
                             (for [voor acc x (range (inc n))]
                               (conj voor x)))
                           [[]] lengtes)
        geordend (sort-by #(reduce + 0 %) toestanden)]
    (reduce
      (fn [tabel resterend]
        (if-not (grensstaat? lengtes resterend)
          tabel
          (assoc tabel resterend
                 (if (every? zero? resterend)
                   1N
                   (reduce +' 0N
                           (for [maand (legale-maanden lengtes resterend)]
                             (get tabel
                                  (update resterend (dec maand) dec)
                                  0N)))))))
      {} geordend)))

(defn- open-rang [lengtes tabel rang]
  (let [totaal (get tabel lengtes 0N)]
    (when-not (and (integer? rang) (<= 1N rang totaal))
      (fout :invalid-weaving-rank))
    (loop [resterend lengtes
           huidige-rang rang
           antwoord []]
      (if (every? zero? resterend)
        antwoord
        (let [stap
              (loop [maanden (legale-maanden lengtes resterend)
                     r huidige-rang]
                (when (empty? maanden)
                  (fout :weaving-unrank-failed))
                (let [maand (first maanden)
                      volgende (update resterend (dec maand) dec)
                      blok (get tabel volgende 0N)]
                  (if (> r blok)
                    (recur (rest maanden) (-' r blok))
                    {:maand maand :resterend volgende :rang r})))]
          (recur (:resterend stap)
                 (:rang stap)
                 (conj antwoord (:maand stap))))))))

(defn aantal-wevingen
  "Exacte BigInt-telling; 1..5 maanden en hoogstens 32 dagen."
  [maandlengtes]
  (let [lengtes (controleer-lengtes maandlengtes)]
    (get (maak-tabel lengtes) lengtes 0N)))

(defn weving-op-rang
  "Eengebaseerde lexicografische maand-ID-reeks binnen de bewezen grens."
  [maandlengtes rang]
  (let [lengtes (controleer-lengtes maandlengtes)
        tabel (maak-tabel lengtes)]
    (open-rang lengtes tabel rang)))

(defn kies-maandweving
  "Erft alle bewezen velden; kom 4 en zegel 32, zonder datumclaim."
  ([lijn berekeningsdag doeldag]
   (kies-maandweving lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag budget]
   (let [{:keys [year month-lengths] :as basis}
         (lengtes/kies-maandlengtes lijn berekeningsdag doeldag budget)
         gevalideerd (controleer-lengtes month-lengths)
         tabel (maak-tabel gevalideerd)
         totaal (get tabel gevalideerd 0N)
         saus (verdelingen/structuur-saus berekeningsdag year)
         stroom (keuzes/vraag-kom saus 4N 32N)
         rang (keuzes/kies-rang stroom totaal)]
     (assoc basis
            :month-weaving (open-rang gevalideerd tabel rang)
            :month-weaving-family-count totaal))))


;; DISCOVERY18: afzonderlijke, exact getelde grote families.
;; Dit verandert de begrensde rang-/selectie-API van DISCOVERY17 niet.
(def ^:private maximale-grote-maanden 47)
(def ^:private maximale-grote-dagen 5778N)

(defn- controleer-grote-lengtes [maandlengtes]
  (when-not (and (sequential? maandlengtes)
                 (pos? (count maandlengtes))
                 (every? #(and (integer? %) (<= 4N % 123N)) maandlengtes))
    (fout :invalid-weaving-family))
  (when (or (> (count maandlengtes) maximale-grote-maanden)
            (> (reduce +' 0N maandlengtes) maximale-grote-dagen))
    (fout :weaving-bound-exceeded))
  (mapv int maandlengtes))

(defn- gewichten-voor-nieuwe-maand [nieuwe-dagen oude-dagen]
  ;; w(t) = C(nieuwe-dagen+t-2,t), exact via een deelbare recurrence.
  (loop [t 0
         gewicht 1N
         antwoord [1N]]
    (if (>= t (dec oude-dagen))
      antwoord
      (let [volgende (quot (*' gewicht (+ (dec nieuwe-dagen) t))
                            (inc t))]
        (recur (inc t) volgende (conj antwoord volgende))))))

(defn- voeg-maand-toe [frequenties oude-dagen nieuwe-dagen]
  ;; Oude woorden eindigen noodzakelijk met de hoogste oude maand.
  ;; Voor nieuwe eerste-positie u+1 zijn de bestaande u tekens ervoor
  ;; en staan alle overige nieuwe tekens in de u..oude-dagen gaten,
  ;; inclusief minstens één nieuwe letter in het laatste gat.
  ;; Cumulatieve telling over oude eerste-posities <= u.
  (let [gewichten (gewichten-voor-nieuwe-maand nieuwe-dagen oude-dagen)]
    (loop [u 1
           prefix 0N
           resultaat [0N 0N]]
      (if (> u oude-dagen)
        resultaat
        (let [nieuw-prefix (+' prefix (get frequenties u 0N))
              gewicht (nth gewichten (- oude-dagen u))]
          (recur (inc u)
                 nieuw-prefix
                 (conj resultaat (*' nieuw-prefix gewicht))))))))

(defn aantal-wevingen-groot
  "Exact BigInt aantal maandwoorden voor 1..47 maanden, elk 4..123 dagen,
   totaal <= 5778. Alleen tellen; geen rang-/datumuitbreiding.
   O(m*N) BigInt-bewerkingen en O(N) BigInt-opslag."
  [maandlengtes]
  (let [lengtes (controleer-grote-lengtes maandlengtes)]
    (loop [oude-dagen (first lengtes)
           nog (next lengtes)
           frequenties [0N 1N]]
      (if (nil? nog)
        (reduce +' 0N frequenties)
        (let [nieuwe-dagen (first nog)]
          (recur (+ oude-dagen nieuwe-dagen)
                 (next nog)
                 (voeg-maand-toe frequenties oude-dagen nieuwe-dagen)))))))
