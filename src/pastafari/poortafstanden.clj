(ns pastafari.poortafstanden
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.verborgen-druppels :as verborgen]
            [pastafari.zichtbare-druppels :as zichtbaar]
            [pastafari.saus :as saus]
            [pastafari.keuzestroom :as stroom]))

;; Poortafstanden zijn een afgebakende voorbouwsteen, geen kalenderjaar.
(defn- afstand [nummer richting]
  (when-not (and (integer? nummer) (pos? nummer)
                 (#{1N -1N} richting))
    (throw (ex-info "Ongeldig poortnummer."
                    {:code :invalid-gate-index})))
  (let [begin dagen/stichtingsdag
        doel (+' begin (*' richting nummer))
        tellingen (dagen/werk-tellingen begin doel)
        verborgenwaarden (verborgen/verborgen-druppels tellingen)
        zichtbarewaarden (zichtbaar/zichtbare-druppels
                          tellingen verborgenwaarden)
        kommen (saus/saus tellingen zichtbarewaarden)
        keuze (stroom/vraag-kom kommen 1N 1N)]
    (+' 41N (stroom/kies-rang keuze 922N))))

(defn positieve-poortafstand [nummer]
  (afstand nummer 1N))

(defn negatieve-poortafstand [nummer]
  (afstand nummer -1N))
