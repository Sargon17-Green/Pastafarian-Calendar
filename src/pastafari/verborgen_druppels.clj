(ns pastafari.verborgen-druppels
  (:require [pastafari.stenen :as stenen]))

;; Zeven verborgen druppels; volledig exact en zonder testorakel in productie.
(def ^:private gewichten
  [[3N 4N 6N 8N]
   [5N 7N 10N 12N]
   [7N 10N 14N 16N]
   [9N 13N 18N 20N]
   [11N 16N 22N 24N]
   [13N 19N 26N 28N]
   [15N 22N 30N 32N]])

;; Steensoorten per maalbeurt, nul-gebaseerd.
(def ^:private maalvolgorde [0 1 2 3 4 0 1])
(def ^:private verplichte-sleutels
  [:action :target :distance :connection :direction])

(defn- controleer-tellingen [tellingen]
  (when-not (and (map? tellingen)
                 (every? (fn [sleutel]
                           (let [waarde (get tellingen sleutel)]
                             (and (integer? waarde) (pos? waarde))))
                         verplichte-sleutels)
                 (<= 1 (:direction tellingen) 3))
    (throw (ex-info "Ongeldige exacte werk-tellingen."
                    {:code :invalid-work-counts :value tellingen})))
  tellingen)

(defn verborgen-druppels [tellingen]
  (controleer-tellingen tellingen)
  (let [{:keys [action target distance connection direction]} tellingen]
    (mapv
     (fn [index]
       (let [[a b c d] (nth gewichten index)
             steen (stenen/steen (inc index))
             zaad (+' action
                      (*' a target)
                      (*' b distance)
                      (*' c connection)
                      (*' d direction)
                      (reduce +' 0N steen))
             begin (stenen/save zaad)]
         (reduce
          (fn [waarde beurt]
            (stenen/save
             (+' (*' waarde waarde)
                 (*' 3N waarde)
                 (nth steen (nth maalvolgorde (dec beurt)))
                 beurt)))
          begin
          (range 1 8))))
     (range 7))))
