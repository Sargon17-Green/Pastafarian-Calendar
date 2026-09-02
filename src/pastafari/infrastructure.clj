(ns pastafari.infrastructure
  (:require [pastafari.monster-context :as context]))

(defn require-integer-day [value field-name]
  (when-not (integer? value)
    (throw (ex-info "De dagwaarde moet een exact geheel getal zijn."
                    {:code :invalid-day
                     :field field-name
                     :value value})))
  value)

(defn validate-inputs [ctx]
  (require-integer-day (:calculation-day ctx) :calculation-day)
  (require-integer-day (:target-day ctx) :target-day)
  (-> ctx
      (assoc :status :validated)
      (context/trace :inputs-validated)))

(defn wrap-error [ctx operation throwable]
  (ex-info "De bootstrap-infrastructuur heeft een fout afgevangen."
           {:code :bootstrap-error
            :operation operation
            :phase (:phase ctx)}
           throwable))

(defn dispatch [ctx handler]
  (handler (-> ctx
               (context/metric-inc :dispatcher-calls)
               (context/trace :dispatch))))
