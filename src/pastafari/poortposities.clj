(ns pastafari.poortposities
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.poortafstanden :as afstanden]))

;; DISCOVERY07: exact, eindig, zonder datum- of jaarinterpretatie.
;; Een groot onbegrensd indexverzoek zou lineaire hoeveelheden saus vereisen.
(def maximale-straal 64N)

(defn- ongeldige-straal []
  (throw (ex-info "De poortstraal moet een geheel getal tussen 0 en 64 zijn."
                  {:code :invalid-gate-radius})))

(defn- controleer-lijn [lijn]
  (when-not (and (map? lijn)
                 (integer? (:straal lijn))
                 (<= 0N (:straal lijn) maximale-straal)
                 (vector? (:dagen lijn))
                 (= (count (:dagen lijn)) (inc (*' 2N (:straal lijn))))
                 (every? integer? (:dagen lijn))
                 (= dagen/stichtingsdag
                    (nth (:dagen lijn) (int (:straal lijn))))
                 (apply < (:dagen lijn)))
    (throw (ex-info "Ongeldige poortlijn." {:code :invalid-gate-line})))
  lijn)

(defn bouw-poortlijn [straal]
  (when-not (and (integer? straal)
                 (<= 0N straal maximale-straal))
    (ongeldige-straal))
  (loop [n 1N
         rechts [dagen/stichtingsdag]
         links [dagen/stichtingsdag]]
    (if (> n straal)
      (controleer-lijn
       {:straal straal
        :dagen (vec (concat (reverse (rest links)) rechts))})
      (recur (inc n)
             (conj rechts (+' (peek rechts)
                             (afstanden/positieve-poortafstand n)))
             (conj links (-' (peek links)
                            (afstanden/negatieve-poortafstand n)))))))

(defn poortdag [lijn index]
  (controleer-lijn lijn)
  (when-not (and (integer? index)
                 (<= (-' (:straal lijn)) index (:straal lijn)))
    (throw (ex-info "Poortindex buiten het berekende venster."
                    {:code :gate-index-outside-window})))
  (nth (:dagen lijn) (int (+' (:straal lijn) index))))

(defn poort-op-of-voor [lijn dag]
  (controleer-lijn lijn)
  (when-not (integer? dag)
    (throw (ex-info "Een dag moet exact geheel zijn." {:code :invalid-day})))
  (let [dagen (:dagen lijn)
        aantal (count dagen)]
    ;; Buiten de berekende grenzen is de werkelijke voorganger onbekend.
    (when-not (<= (first dagen) dag (peek dagen))
      (throw (ex-info "Dag buiten het bewezen poortvenster."
                      {:code :day-outside-gate-window})))
    ;; Upper-bound binaire zoekactie, geen aanroep van het testoracle.
    (loop [laag 0
           hoog aantal]
      (if (= laag hoog)
        (let [plaats (dec laag)]
          {:index (-' plaats (:straal lijn))
           :day (nth dagen plaats)})
        (let [midden (quot (+ laag hoog) 2)]
          (if (<= (nth dagen midden) dag)
            (recur (inc midden) hoog)
            (recur laag midden)))))))