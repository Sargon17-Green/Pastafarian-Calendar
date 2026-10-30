(ns pastafari.keuzestroom
  (:require [pastafari.stenen :as stenen]))

;; Exacte selectie uit de zes eindkommen; nooit afhankelijk van het testorakel.
(defn- ongeldig []
  (throw (ex-info "Ongeldige keuzestroom of invoer."
                  {:code :invalid-choice-input})))

(defn- geldige-stroom? [stroom]
  (and (map? stroom)
       (integer? (:first stroom))
       (<= 1N (:first stroom) stenen/modulus)
       (#{1N -1N} (:direction-step stroom))))

(defn vraag-kom [sausresultaat kom-id zegel]
  (let [kommen (:bowls sausresultaat)
        volgorde (:order-at-drop46 sausresultaat)]
    (when-not (and (map? sausresultaat)
                   (vector? kommen) (= 6 (count kommen))
                   (every? #(and (integer? %)
                                 (<= 1N % stenen/modulus)) kommen)
                   (vector? volgorde)
                   (= 6 (count volgorde))
                   (= #{1 2 3 4 5 6} (set volgorde))
                   (integer? kom-id) (<= 1 kom-id 6)
                   (integer? zegel) (pos? zegel))
      (ongeldig))
    (let [positie (.indexOf volgorde kom-id)
          volgende (nth volgorde (mod (inc positie) 6))
          hier (nth kommen (dec kom-id))
          buur (nth kommen (dec volgende))
          begin (stenen/save
                 (+' (*' (+' hier zegel 181N)
                         (+' hier zegel 181N))
                     (*' 179N buur) zegel))
          richtingwaarde (stenen/save
                          (+' (*' (+' begin zegel 194N)
                                  (+' begin zegel 194N))
                              (*' 193N begin)
                              (*' 197N (nth kommen 5))))
          stap (if (odd? richtingwaarde) 1N -1N)]
      {:first begin :direction-step stap})))

(defn antwoord-op [stroom positie]
  (when-not (and (geldige-stroom? stroom)
                 (integer? positie) (not (neg? positie)))
    (ongeldig))
  (stenen/save (+' (:first stroom)
                   (*' (:direction-step stroom) positie))))

(defn- bereikgrootte [minimum]
  (loop [ruimte stenen/modulus]
    (if (>= ruimte minimum)
      ruimte
      (recur (*' ruimte stenen/modulus)))))

(defn- samengesteld-getal [stroom ruimte]
  ;; Basis-M-cijfers van laag naar hoog; een andere procedure dan
  ;; de normatieve testimplementatie (gewichtsiteratie tot ruimte).
  (loop [gewicht 1N
         positie 0N
         som 1N]
    (if (>= gewicht ruimte)
      som
      (let [cijfer (dec (antwoord-op stroom positie))]
        (recur (*' gewicht stenen/modulus)
               (inc positie)
               (+' som (*' cijfer gewicht)))))))

(defn kies-rang [stroom grootte]
  (when-not (and (geldige-stroom? stroom)
                 (integer? grootte) (pos? grootte))
    (ongeldig))
  (let [ruimte (bereikgrootte grootte)
        grens (*' (quot ruimte grootte) grootte)
        eerste (if (= ruimte stenen/modulus)
                 (:first stroom)
                 (samengesteld-getal stroom ruimte))
        stap (:direction-step stroom)]
    (loop [kandidaat eerste]
      (if (<= kandidaat grens)
        (inc (mod (dec kandidaat) grootte))
        (recur (inc (mod (+' (dec kandidaat) stap) ruimte)))))))
