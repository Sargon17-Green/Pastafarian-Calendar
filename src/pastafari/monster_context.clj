(ns pastafari.monster-context)

(defn new-context [calculation-day target-day]
  {:calculation-day calculation-day
   :target-day target-day
   :phase :entry
   :sub-phase 0
   :mode :bootstrap
   :status :new
   :branch-trace []
   :semantic-state {}
   :pending-state nil
   :rollback-state nil
   :metrics {}
   :logs []
   :diagnostics []
   :validation-failures []
   :last-error nil})

(defn trace [context marker]
  (update context :branch-trace conj marker))

(defn metric-inc [context metric-key]
  (update-in context [:metrics metric-key] (fnil inc 0)))
