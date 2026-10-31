(ns pastafari.koteletnamen
  (:require [pastafari.koteletverdeling :as verdelingen]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY13: een injectieve, lexicografische keuze uit 17 naamindices.
;; Geen normatieve oracle-code in productie; de tests rekenen onafhankelijk.
(def ^:private naamvoorraad 17N)
(def ^:private zegel-namen 22N)

(defn- fout [code]
  (throw (ex-info "De koteletnamen zijn niet bewezen voor deze invoer."
                  {:code code})))

(defn- controleer [voorraad aantal]
  (when-not (and (integer? voorraad) (<= 1N voorraad naamvoorraad))
    (fout :invalid-name-pool))
  (when-not (and (integer? aantal) (<= 1N aantal voorraad))
    (fout :invalid-name-count)))

(defn aantal-naamreeksen [voorraad aantal]
  "Exact aantal geordende reeksen zonder herhaling: voorraad!/(voorraad-aantal)!.
   De generieke begrensde functie laat kleine uitputtende tests toe."
  (controleer voorraad aantal)
  (loop [over voorraad nog aantal product 1N]
    (if (zero? nog)
      product
      (recur (dec over) (dec nog) (*' product over)))))

(defn namen-op-rang [voorraad aantal rang]
  "Eengebaseerde lexicografische rang van unieke indices uit 1..voorraad.
   Maximaal 17 stappen, zonder enumeratie van de permutatiefamilie."
  (let [totaal (aantal-naamreeksen voorraad aantal)]
    (when-not (and (integer? rang) (<= 1N rang totaal))
      (fout :invalid-name-rank))
    (loop [vrije (vec (range 1 (inc (int voorraad))))
           nog aantal
           nulrang (dec rang)
           blok totaal
           namen []]
      (if (zero? nog)
        (vec namen)
        (let [volgende-blok (quot blok (count vrije))
              positie (int (quot nulrang volgende-blok))
              naam (nth vrije positie)
              zonder-naam (filterv #(not= % naam) vrije)]
          (recur zonder-naam
                 (dec nog)
                 (mod nulrang volgende-blok)
                 volgende-blok
                 (conj namen naam)))))))

(defn kies-namen
  "Behoud bewezen jaar, aantal en poortverdeling; voeg alleen unieke naamindices toe.
   Nog geen vijfdelige datum, maanden of kalendergebruik."
  ([lijn berekeningsdag doeldag]
   (kies-namen lijn berekeningsdag doeldag 128N))
  ([lijn berekeningsdag doeldag budget]
   (let [{:keys [year cutlet-count] :as basis}
         (verdelingen/kies-verdeling lijn berekeningsdag doeldag budget)
         saus (verdelingen/structuur-saus berekeningsdag year)
         totaal (aantal-naamreeksen naamvoorraad cutlet-count)
         stroom (keuzes/vraag-kom saus 5N zegel-namen)
         rang (keuzes/kies-rang stroom totaal)]
     (assoc basis
            :name-indices (namen-op-rang naamvoorraad cutlet-count rang)
            :name-family-count totaal))))
