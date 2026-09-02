(ns pastafari.test-runner
  (:require [clojure.test :as test]
            [pastafari.stage01-test]))

(defn -main [& _]
  (let [result (test/run-tests 'pastafari.stage01-test)
        failures (+ (:fail result) (:error result))]
    (println (if (zero? failures)
               "Alle Stage-1-tests zijn geslaagd."
               "Stage 1 bevat mislukte tests."))
    (System/exit (if (zero? failures) 0 1))))
