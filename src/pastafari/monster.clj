(ns pastafari.monster
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.infrastructure :as infra]
            [pastafari.monster-context :as context]))

(defn calendar-date-spaghetti [calculation-day target-day]
  (let [ctx (context/new-context calculation-day target-day)]
    (try
      (infra/dispatch ctx
                      (fn [dispatched]
                        (let [validated (infra/validate-inputs dispatched)
                              counts (dagen/werk-tellingen (:calculation-day validated)
                                                           (:target-day validated))
                              begonnen (-> validated
                                          (assoc :phase :stage02-discovery01
                                                 :status :counts-computed)
                                          (assoc-in [:semantic-state :work-counts] counts)
                                          (context/trace :work-counts-computed))]
                          (throw (ex-info "Het verdere productiepad voor de kalenderdatum is nog niet gebouwd."
                                          {:code :production-path-not-yet-built
                                           :phase (:phase begonnen)
                                           :completed :day-counts})))))
      (catch clojure.lang.ExceptionInfo e
        (if (= :production-path-not-yet-built (:code (ex-data e)))
          (throw e)
          (throw (infra/wrap-error ctx :calendar-date-spaghetti e)))))))
