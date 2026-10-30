(ns pastafari.test-runner
  (:require [clojure.test :as test]
            [pastafari.stage01-test]
            [pastafari.stage02-test]
            [pastafari.stage02-stones-test]
            [pastafari.stage02-hidden-drops-test]
            [pastafari.stage02-visible-drops-test]
            [pastafari.stage02-sauce-test]))

(defn -main [& _]
  (let [result (test/run-tests 'pastafari.stage01-test
                               'pastafari.stage02-test
                               'pastafari.stage02-stones-test
                               'pastafari.stage02-hidden-drops-test
                               'pastafari.stage02-visible-drops-test
                               'pastafari.stage02-sauce-test)
        failures (+ (:fail result) (:error result))]
    (println (if (zero? failures)
               "Alle Stage-1- en Stage-2-discoverytests zijn geslaagd."
               "Er zijn mislukte tests."))
    (System/exit (if (zero? failures) 0 1))))
