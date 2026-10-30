(ns pastafari.dagfundament)

;; De eerste zelfstandige productiebouwsteen voor de kalenderdatum.
;; Deze namespace mag niet van pastafari.normative-oracle afhangen.
(def stichtingsdag -15055671N)

(defn- vereis-gehele-dag [waarde veld]
  (when-not (integer? waarde)
    (throw (ex-info "Een dag moet een exact geheel getal zijn."
                    {:code :invalid-day :field veld :value waarde})))
  waarde)

(defn- absoluut [getal]
  (if (neg? getal) (-' getal) getal))

(defn dagtelling [dag]
  (vereis-gehele-dag dag :day)
  (let [verschil (-' dag stichtingsdag)]
    (cond
      (zero? verschil) 1N
      (pos? verschil) (+' 1N (*' 2N verschil))
      :else (*' 2N (-' verschil)))))

(defn werk-tellingen [berekeningsdag doeldag]
  (vereis-gehele-dag berekeningsdag :calculation-day)
  (vereis-gehele-dag doeldag :target-day)
  (let [handeling (dagtelling berekeningsdag)
        doel (dagtelling doeldag)
        afstand (+' 1N (absoluut (-' doeldag berekeningsdag)))
        verbinding (+' handeling doel)
        richting (cond
                   (< doeldag berekeningsdag) 1N
                   (= doeldag berekeningsdag) 2N
                   :else 3N)]
    {:action handeling
     :target doel
     :distance afstand
     :connection verbinding
     :direction richting}))
