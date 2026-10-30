(ns pastafari.test-runner
  (:require [clojure.test :as test]
            [pastafari.stage01-test]
            [pastafari.stage02-test]))

(defn -main [& _]
  (let [result (test/run-tests 'pastafari.stage01-test
                               'pastafari.stage02-test)
        failures (+ (:fail result) (:error result))]
    (println (if (zero? failures)
               "Alle Stage-1- en Stage-2-discoverytests zijn geslaagd."
               "Er zijn mislukte tests."))
    (System/exit (if (zero? failures) 0 1))))
