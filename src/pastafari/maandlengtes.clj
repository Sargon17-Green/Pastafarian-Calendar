(ns pastafari.maandlengtes
  (:require [pastafari.maandaantal :as aantallen]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY16: iterative window-sum DP, independent of normative recursive oracle.
(defn- fout [code]
  (throw (ex-info "De maandlengtes zijn niet bewezen." {:code code})))

(defn- controleer [duur maanden]
  (when-not (and (integer? duur) (<= 4N duur 5778N)
                 (integer? maanden) (<= 1N maanden 47N)
                 (<= (*' 4N maanden) duur (*' 123N maanden)))
    (fout :invalid-month-length-family)))

(defn- bouw-tabel [duur maanden]
  (let [overschot (int (-' duur (*' 4N maanden)))
        basis (assoc (vec (repeat (inc overschot) 0N)) 0 1N)]
    (loop [k 1 vorig basis rijen [basis]]
      (if (> k maanden)
        rijen
        (let [rij
              (loop [r 0 venster 0N resultaat (transient [])]
                (if (> r overschot)
                  (persistent! resultaat)
                  (let [nieuw (-' (+' venster (nth vorig r))
                                  (if (>= r 120) (nth vorig (- r 120)) 0N))]
                    (recur (inc r) nieuw (conj! resultaat nieuw)))))]
          (recur (inc k) rij (conj rijen rij)))))))

(defn- aantal-in [tabel duur maanden]
  (nth (nth tabel (int maanden))
       (int (-' duur (*' 4N maanden)))))

(defn aantal-lengtereeksen
  "Exacte BigInt-telling voor 1..47 delen van 4..123 dagen."
  [duur maanden]
  (controleer duur maanden)
  (aantal-in (bouw-tabel duur maanden) duur maanden))

(defn- open-rang [tabel duur maanden rang]
  (let [totaal (aantal-in tabel duur maanden)]
    (when-not (and (integer? rang) (<= 1N rang totaal))
      (fout :invalid-month-length-rank))
    (loop [nog (int maanden)
           overschot (int (-' duur (*' 4N maanden)))
           huidige-rang rang
           antwoord []]
      (if (zero? nog)
        (vec antwoord)
        (let [keuze
              (loop [meer 0 r huidige-rang]
                (when (> meer 119)
                  (fout :month-length-unrank-failed))
                (let [volgend (- overschot meer)
                      blok (if (neg? volgend)
                             0N
                             (nth (nth tabel (dec nog)) volgend))]
                  (if (> r blok)
                    (recur (inc meer) (-' r blok))
                    {:meer meer :rest volgend :rang r})))]
          (recur (dec nog)
                 (:rest keuze)
                 (:rang keuze)
                 (conj antwoord (+ 4 (:meer keuze)))))))))

(defn lengtes-op-rang
  "Eengebaseerde lexicografische rang zonder enumeratie."
  [duur maanden rang]
  (controleer duur maanden)
  (open-rang (bouw-tabel duur maanden) duur maanden rang))

(defn kies-maandlengtes
  "Behoud bewezen velden; kies maandlengtes uit kom 3 en zegel 31."
  ([lijn berekeningsdag doeldag]
   (kies-maandlengtes lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag budget]
   (let [{:keys [year month-count] :as basis}
         (aantallen/kies-maandaantal lijn berekeningsdag doeldag budget)
         duur (-' (:close-gate-day year) (:open-gate-day year))
         _ (controleer duur month-count)
         tabel (bouw-tabel duur month-count)
         totaal (aantal-in tabel duur month-count)
         saus (verdelingen/structuur-saus berekeningsdag year)
         stroom (keuzes/vraag-kom saus 3N 31N)
         rang (keuzes/kies-rang stroom totaal)]
     (assoc basis
            :month-lengths (open-rang tabel duur month-count rang)
            :month-length-family-count totaal))))
