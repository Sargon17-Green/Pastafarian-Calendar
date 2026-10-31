(ns pastafari.jaargrenzen
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.saus :as saus]
            [pastafari.keuzestroom :as keuzes]))

;; DISCOVERY09. Alleen bewezen poortindices; geen onbegrensde uitbreiding.
(def ^:private minimum-jaardagen 252N)
(def ^:private maximum-jaardagen 5778N)
(def ^:private minimum-poorten 6N)

(defn- fout [code]
  (throw (ex-info "Geen bewezen jaargrenzen voor deze invoer." {:code code})))

(defn- controleer-lijn [lijn]
  (poorten/poortdag lijn 0N)
  lijn)

(defn- controleer-dag [dag]
  (when-not (integer? dag) (fout :invalid-day))
  dag)

(defn- controleer-dekking [lijn begin eind]
  (controleer-lijn lijn)
  (let [r (:straal lijn)]
    (when-not (and (<= (poorten/poortdag lijn (-' r)) begin)
                   (<= eind (poorten/poortdag lijn r)))
      (fout :year-window-unproven)))
  lijn)

(defn- saus-voor [berekeningsdag doeldag]
  (let [tellingen (dagen/werk-tellingen berekeningsdag doeldag)
        druppels (verborgen/verborgen-druppels tellingen)]
    (saus/saus tellingen
               (zichtbaar/zichtbare-druppels tellingen druppels))))

(defn- kies-jaar [lijn berekeningsdag doeldag zegel kandidaatlijst nummer]
  (when (empty? kandidaatlijst) (fout :no-year-candidates))
  (let [stroom (keuzes/vraag-kom (saus-voor berekeningsdag doeldag) 1N zegel)
        rang (keuzes/kies-rang stroom (count kandidaatlijst))
        {:keys [open-index close-index]} (nth kandidaatlijst (dec (int rang)))]
    {:number nummer
     :open-gate-index open-index
     :close-gate-index close-index
     :open-gate-day (poorten/poortdag lijn open-index)
     :close-gate-day (poorten/poortdag lijn close-index)}))

(defn- geldig-paar? [lijn open-index close-index]
  (and (>= (-' close-index open-index) minimum-poorten)
       (let [duur (-' (poorten/poortdag lijn close-index)
                      (poorten/poortdag lijn open-index))]
         (<= minimum-jaardagen duur maximum-jaardagen))))

(defn jaar5000-kandidaten [lijn berekeningsdag]
  (controleer-dag berekeningsdag)
  (controleer-dekking lijn (-' berekeningsdag maximum-jaardagen)
                      (+' berekeningsdag maximum-jaardagen))
  (let [r (:straal lijn)
        kandidaten
        (for [open-index (range (-' r) (inc r))
              close-index (range (+' open-index minimum-poorten) (inc r))
              :when (geldig-paar? lijn open-index close-index)
              :let [open-day (poorten/poortdag lijn open-index)
                    close-day (poorten/poortdag lijn close-index)]
              :when (and (< open-day berekeningsdag)
                         (<= berekeningsdag close-day))]
          {:open-index open-index
           :close-index close-index
           :open-day open-day
           :length (-' close-day open-day)})]
    (vec (sort-by (juxt :length :open-day) kandidaten))))

(defn jaar5000 [lijn berekeningsdag]
  (kies-jaar lijn berekeningsdag berekeningsdag 10N
             (jaar5000-kandidaten lijn berekeningsdag) 5000N))

(defn- controleer-jaar [lijn jaar]
  (controleer-lijn lijn)
  (when-not (and (map? jaar) (integer? (:number jaar))
                 (integer? (:open-gate-index jaar))
                 (integer? (:close-gate-index jaar)))
    (fout :invalid-known-year))
  (let [a (:open-gate-index jaar)
        b (:close-gate-index jaar)
        r (:straal lijn)]
    (when-not (and (<= (-' r) a) (<= b r) (< a b)
                   (geldig-paar? lijn a b)
                   (= (:open-gate-day jaar) (poorten/poortdag lijn a))
                   (= (:close-gate-day jaar) (poorten/poortdag lijn b)))
      (fout :invalid-known-year)))
  jaar)

(defn volgend-jaar [lijn berekeningsdag bekend-jaar]
  (controleer-dag berekeningsdag)
  (controleer-jaar lijn bekend-jaar)
  (let [open-index (:close-gate-index bekend-jaar)
        open-day (poorten/poortdag lijn open-index)]
    (controleer-dekking lijn open-day (+' open-day maximum-jaardagen))
    (let [r (:straal lijn)
          kandidaten
          (->> (range (inc open-index) (inc r))
               (filter #(geldig-paar? lijn open-index %))
               (mapv (fn [close-index]
                       {:open-index open-index
                        :close-index close-index
                        :length (-' (poorten/poortdag lijn close-index) open-day)}))
               (sort-by :length)
               vec)]
      (kies-jaar lijn berekeningsdag open-day 11N kandidaten
                 (inc (:number bekend-jaar))))))

(defn vorig-jaar [lijn berekeningsdag bekend-jaar]
  (controleer-dag berekeningsdag)
  (controleer-jaar lijn bekend-jaar)
  (let [close-index (:open-gate-index bekend-jaar)
        close-day (poorten/poortdag lijn close-index)]
    (controleer-dekking lijn (-' close-day maximum-jaardagen) close-day)
    (let [r (:straal lijn)
          kandidaten
          (->> (range (dec close-index) (dec (-' r)) -1)
               (filter #(geldig-paar? lijn % close-index))
               (mapv (fn [open-index]
                       {:open-index open-index
                        :close-index close-index
                        :length (-' close-day (poorten/poortdag lijn open-index))}))
               (sort-by :length)
               vec)]
      (kies-jaar lijn berekeningsdag close-day 12N kandidaten
                 (dec (:number bekend-jaar))))))