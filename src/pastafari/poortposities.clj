(ns pastafari.poortposities
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.poortafstanden :as afstanden]))

;; DISCOVERY07: exact, eindig, zonder datum- of jaarinterpretatie.
;; Een groot onbegrensd indexverzoek zou lineaire hoeveelheden saus vereisen.
(def maximale-straal 128N)

(defn- ongeldige-straal []
  (throw (ex-info "De poortstraal moet een geheel getal tussen 0 en 128 zijn."
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

;; DISCOVERY08: bereken alleen nieuwe uiteinden; de oude poortdagen blijven gelijk.
(defn verleng-poortlijn [lijn nieuwe-straal]
  (controleer-lijn lijn)
  (when-not (and (integer? nieuwe-straal)
                 (<= 0N nieuwe-straal maximale-straal))
    (ongeldige-straal))
  (let [oude-straal (:straal lijn)]
    (when (< nieuwe-straal oude-straal)
      (throw (ex-info "Een poortlijn kan niet worden verkleind."
                      {:code :cannot-shrink-gate-line})))
    (loop [nummer (inc oude-straal)
           linkerkant (first (:dagen lijn))
           rechterkant (peek (:dagen lijn))
           toegevoegde-linkerkant []
           toegevoegde-rechterkant []]
      (if (> nummer nieuwe-straal)
        (controleer-lijn
         {:straal nieuwe-straal
          :dagen (vec (concat (reverse toegevoegde-linkerkant)
                             (:dagen lijn)
                             toegevoegde-rechterkant))})
        (let [links (-' linkerkant
                        (afstanden/negatieve-poortafstand nummer))
              rechts (+' rechterkant
                         (afstanden/positieve-poortafstand nummer))]
          (recur (inc nummer) links rechts
                 (conj toegevoegde-linkerkant links)
                 (conj toegevoegde-rechterkant rechts)))))))

;; Links gesloten, rechts open: [P(k),P(k+1)); geen kalenderjaar.
(defn poortinterval [lijn dag]
  (controleer-lijn lijn)
  (let [{:keys [index] begin :day} (poort-op-of-voor lijn dag)]
    (when (= index (:straal lijn))
      (throw (ex-info "Rechtergrens van het poortinterval ontbreekt."
                      {:code :gate-interval-not-proven})))
    (let [eind (poortdag lijn (inc index))]
      {:index index
       :begin begin
       :eind eind
       :lengte (-' eind begin)
       :positie (-' dag begin)})))
