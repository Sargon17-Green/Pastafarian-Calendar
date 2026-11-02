(ns pastafari.maandnamen
  (:require [pastafari.maandselectie :as selectie]
            [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY22: maandnamen zijn unieke indices uit 1..47.
;; Productie gebruikt nulgebaseerde gemengd-radix-rang en een 47-bits masker,
;; NIET de eengebaseerde aftellus van het normatieve testorakel.
(def ^:private maximale-voorraad 47N)

(defn- fout [code]
  (throw (ex-info "De maandnamen zijn niet bewezen voor deze invoer."
                  {:code code})))

(defn- controleer [voorraad aantal]
  (when-not (and (integer? voorraad)
                 (<= 1N voorraad maximale-voorraad))
    (fout :invalid-month-name-pool))
  (when-not (and (integer? aantal)
                 (<= 1N aantal voorraad))
    (fout :invalid-month-name-count)))

(defn aantal-maandnaamreeksen
  "Exact P(voorraad,aantal), voor 1..47 unieke maandnaamindices."
  [voorraad aantal]
  (controleer voorraad aantal)
  (loop [over voorraad nog aantal product 1N]
    (if (zero? nog)
      product
      (recur (dec over) (dec nog) (*' product over)))))

(defn- vrije-naam-op-positie
  "Zoek de nulgebaseerde vrije positie zonder een permutatiefamilie te bouwen."
  [masker voorraad positie]
  (loop [index 0 gezien 0]
    (when (>= index voorraad)
      (fout :month-name-unrank-failed))
    (if (bit-test masker index)
      (if (= gezien positie)
        (inc index)
        (recur (inc index) (inc gezien)))
      (recur (inc index) gezien))))

(defn maandnamen-op-rang
  "Een-gebaseerde lexicografische rang; ten hoogste 47 namen en 47-bits masker."
  [voorraad aantal rang]
  (let [totaal (aantal-maandnaamreeksen voorraad aantal)]
    (when-not (and (integer? rang) (<= 1N rang totaal))
      (fout :invalid-month-name-rank))
    (loop [masker (dec (bit-shift-left 1 (int voorraad)))
           vrije (int voorraad)
           nog (int aantal)
           r0 (dec rang)
           blok totaal
           namen []]
      (if (zero? nog)
        (vec namen)
        (let [volgend-blok (quot blok vrije)
              positie (int (quot r0 volgend-blok))
              naam (vrije-naam-op-positie masker (int voorraad) positie)]
          (recur (bit-clear masker (dec naam))
                 (dec vrije)
                 (dec nog)
                 (mod r0 volgend-blok)
                 volgend-blok
                 (conj namen naam)))))))

(defn kies-maandnamen
  "Behoud alle bewezen maandweving-velden; kom 5/zegel 33.
   Voegt unieke maandnaamindices toe, GEEN vijfdelige datum."
  ([lijn berekeningsdag doeldag]
   (kies-maandnamen lijn berekeningsdag doeldag 128N 5000000N))
  ([lijn berekeningsdag doeldag zoekbudget celbudget]
   (let [{:keys [year month-count] :as basis}
         (selectie/kies-bewezen-maandweving
           lijn berekeningsdag doeldag zoekbudget celbudget)
         totaal (aantal-maandnaamreeksen maximale-voorraad month-count)
         saus (verdelingen/structuur-saus berekeningsdag year)
         stroom (keuzes/vraag-kom saus 5N 33N)
         rang (keuzes/kies-rang stroom totaal)]
     (assoc basis
            :month-name-indices
            (maandnamen-op-rang maximale-voorraad month-count rang)
            :month-name-family-count totaal))))
