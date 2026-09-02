(ns pastafari.monster
  (:require [pastafari.infrastructure :as infra]
            [pastafari.monster-context :as context]))

(defn calendar-date-spaghetti [calculation-day target-day]
  (let [ctx (context/new-context calculation-day target-day)]
    (try
      (infra/dispatch ctx
                      (fn [dispatched]
                        (let [validated (infra/validate-inputs dispatched)]
                          (throw (ex-info "Het normatieve productiepad wordt pas in latere historische fasen opgebouwd."
                                          {:code :production-path-not-yet-built
                                           :phase (:phase validated)})))))
      (catch clojure.lang.ExceptionInfo e
        (if (= :production-path-not-yet-built (:code (ex-data e)))
          (throw e)
          (throw (infra/wrap-error ctx :calendar-date-spaghetti e)))))))
