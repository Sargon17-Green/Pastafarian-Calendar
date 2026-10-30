(ns pastafari.zichtbare-druppels
  (:require [pastafari.stenen :as stenen]))

;; Verborgen druppels: index 0 staat op dag 0, index 6 op dag -6.
;; De drie voorgangers blijven tijdens alle elf maalbeurten constant.
(def ^:private maalregels
  [[3N 5N 7N 11N 0]
   [5N 7N 11N 13N 1]
   [7N 11N 13N 17N 2]
   [11N 13N 17N 19N 3]
   [13N 17N 19N 23N 4]
   [17N 19N 23N 29N 0]
   [19N 23N 29N 31N 1]
   [23N 29N 31N 37N 2]
   [29N 31N 37N 41N 3]
   [31N 37N 41N 43N 4]
   [37N 41N 43N 47N 0]])

(def ^:private sleutels [:action :target :distance :connection :direction])

(defn- controleer-invoer [tellingen verborgen]
  (when-not
   (and (map? tellingen)
        (every? (fn [sleutel]
                  (let [waarde (get tellingen sleutel)]
                    (and (integer? waarde) (pos? waarde))))
                sleutels)
        (<= 1N (:direction tellingen) 3N)
        (vector? verborgen)
        (= 7 (count verborgen))
        (every? (fn [waarde]
                  (and (integer? waarde)
                       (<= 1N waarde stenen/modulus)))
                verborgen))
    (throw (ex-info "Ongeldige tellingen of verborgen druppels."
                    {:code :invalid-visible-input
                     :counts tellingen
                     :hidden verborgen})))
  [tellingen verborgen])

(defn- eerste-tijdlijn [verborgen]
  (reduce-kv (fn [tijdlijn index waarde]
               (assoc tijdlijn (- index) waarde))
             {}
             verborgen))

(defn zichtbare-druppels [tellingen verborgen]
  (controleer-invoer tellingen verborgen)
  (let [{:keys [action target distance connection direction]} tellingen]
    (loop [nummer 1
           tijdlijn (eerste-tijdlijn verborgen)
           resultaat []]
      (if (> nummer 46)
        resultaat
        (let [vorige1 (get tijdlijn (dec nummer))
              vorige3 (get tijdlijn (- nummer 3))
              vorige7 (get tijdlijn (- nummer 7))
              steen (stenen/steen nummer)
              [tarwe gerst zout bitter rood] steen
              begin (stenen/save
                     (+' (*' tarwe action)
                         (*' gerst target)
                         (*' zout distance)
                         (*' bitter connection)
                         (*' rood direction)
                         vorige1
                         (*' 3N vorige3)
                         (*' 5N vorige7)
                         nummer))
              waarde (reduce
                      (fn [x [a b c d soort]]
                        (stenen/save
                         (+' (*' x x)
                             (*' a x)
                             (*' b vorige1)
                             (*' c vorige3)
                             (*' d vorige7)
                             (nth steen soort))))
                      begin
                      maalregels)]
          (recur (inc nummer)
                 (assoc tijdlijn nummer waarde)
                 (conj resultaat waarde)))))))
