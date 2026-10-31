(ns pastafari.koteletverdeling
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.koteletaantal :as koteletten]
            [pastafari.poortposities :as poorten]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.saus :as saus]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY12: exacte positieve composities van bewezen poortgaten.
;; Productie telt met binomiaalcoefficienten; het testoracle gebruikt
;; onafhankelijke recursieve telling. Een verplichte grens is intern.
(def ^:private maximale-poortgaten 256N)
(def ^:private zegel-verdeling 21N)

(defn- fout [code]
  (throw (ex-info "De koteletverdeling is niet bewezen."
                  {:code code})))

(defn- controleer-familie [poortgaten aantal grens]
  (when-not (and (integer? poortgaten)
                 (<= 0N poortgaten maximale-poortgaten))
    (fout :invalid-gate-gap-count))
  (when (< poortgaten 6N)
    (fout :no-cutlet-candidates))
  (when-not (and (integer? aantal)
                 (<= 6N aantal (min 17N poortgaten)))
    (fout :invalid-cutlet-count))
  (when-not (or (nil? grens)
                (and (integer? grens) (< 0N grens poortgaten)))
    (fout :invalid-required-boundary)))

(defn- combinatie [n k]
  ;; Exacte C(n,k), ook bij onmogelijke deelproblemen: nul.
  (if (or (neg? n) (neg? k) (> k n))
    0N
    (let [kortste (min k (-' n k))]
      (loop [i 1N resultaat 1N]
        (if (> i kortste)
          resultaat
          (recur (inc i)
                 (quot (*' resultaat (-' n (dec i))) i)))))))

(defn- tel-staat [ruimte vakken grens]
  ;; Zonder verplichte grens: C(ruimte-1, vakken-1).
  ;; Met interne grens b: som over het aantal delen vóór b
  ;; van C(b-1,j-1)*C(ruimte-b-1,vakken-j-1).
  (cond
    (zero? vakken) (if (and (zero? ruimte) (nil? grens)) 1N 0N)
    (< ruimte vakken) 0N
    (nil? grens) (combinatie (dec ruimte) (dec vakken))
    (or (<= grens 0N) (>= grens ruimte)) 0N
    :else
    (reduce +' 0N
            (for [j (range 1 vakken)]
              (*' (combinatie (dec grens) (dec j))
                  (combinatie (dec (-' ruimte grens))
                              (dec (-' vakken j))))))))

(defn aantal-verdelingen [poortgaten aantal grens]
  "Aantal lexicografisch geordende positieve composities.
   grens=nil of een verplichte interne cumulatieve som."
  (controleer-familie poortgaten aantal grens)
  (tel-staat poortgaten aantal grens))

(defn verdeling-op-rang [poortgaten aantal grens rang]
  "Open een eengebaseerde lexicografische rang zonder enumeratie.
   Maximaal 17 delen, 256 poortgaten, exacte BigInt-rekenkunde."
  (let [totaal (aantal-verdelingen poortgaten aantal grens)]
    (when-not (and (integer? rang) (<= 1N rang totaal))
      (fout :invalid-cutlet-partition-rank))
    (loop [ruimte poortgaten
           vakken aantal
           nodig grens
           huidige-rang rang
           uitvoer []]
      (if (zero? vakken)
        (vec uitvoer)
        (let [keuze
              (loop [x 1N r huidige-rang]
                (when (> x (-' ruimte (dec vakken)))
                  (fout :cutlet-partition-unrank-failed))
                (let [volgende-grens
                      (cond
                        (nil? nodig) nil
                        (= x nodig) nil
                        (< x nodig) (-' nodig x)
                        :else ::overschreden)
                      blok (if (= volgende-grens ::overschreden)
                             0N
                             (tel-staat (-' ruimte x)
                                        (dec vakken)
                                        volgende-grens))]
                  (if (> r blok)
                    (recur (inc x) (-' r blok))
                    {:lengte x :rang r :grens volgende-grens})))]
          (recur (-' ruimte (:lengte keuze))
                 (dec vakken)
                 (:grens keuze)
                 (:rang keuze)
                 (conj uitvoer (:lengte keuze))))))))

(defn- structuur-saus [berekeningsdag jaar]
  (let [structuurdag (inc (:open-gate-day jaar))
        tellingen (dagen/werk-tellingen berekeningsdag structuurdag)
        verborgen-druppels (verborgen/verborgen-druppels tellingen)
        zichtbare-druppels (zichtbaar/zichtbare-druppels tellingen verborgen-druppels)]
    (saus/saus tellingen zichtbare-druppels)))

(defn kies-verdeling
  "Tussenresultaat op basis van bewezen doeljaar en koteletaantal.
   Geen namen, maanden of volledige datumcomponenten."
  ([lijn berekeningsdag doeldag]
   (kies-verdeling lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag budget]
   (let [{:keys [year cutlet-count]} (koteletten/kies-aantal lijn berekeningsdag doeldag budget)
         open (:open-gate-index year)
         close (:close-gate-index year)
         poortgaten (-' close open)
         poort (poorten/poort-op-of-voor lijn berekeningsdag)
         index (:index poort)
         grens (when (and (= berekeningsdag (:day poort))
                          (< open index close))
                 (-' index open))
         totaal (aantal-verdelingen poortgaten cutlet-count grens)
         stroom (keuzes/vraag-kom (structuur-saus berekeningsdag year)
                                  2N zegel-verdeling)
         rang (keuzes/kies-rang stroom totaal)]
     {:year year
      :cutlet-count cutlet-count
      :partition (verdeling-op-rang poortgaten cutlet-count grens rang)
      :partition-count totaal
      :required-boundary grens})))
