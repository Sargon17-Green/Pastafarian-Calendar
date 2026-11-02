(ns pastafari.test-runner
  (:require [clojure.test :as test]
            [pastafari.stage01-test]
            [pastafari.stage02-test]
            [pastafari.stage02-stones-test]
            [pastafari.stage02-hidden-drops-test]
            [pastafari.stage02-visible-drops-test]
            [pastafari.stage02-sauce-test]
            [pastafari.stage02-gate-test]
            [pastafari.stage02-gate-positions-test]
            [pastafari.stage02-gate-windows-test]
            [pastafari.stage02-year-boundaries-test]
            [pastafari.stage02-target-year-test]
            [pastafari.stage02-cutlet-count-test]
            [pastafari.stage02-cutlet-partition-test]
            [pastafari.stage02-cutlet-names-test]
            [pastafari.stage02-cutlet-bounds-test]
            [pastafari.stage02-month-count-test]
            [pastafari.stage02-month-length-test]
            [pastafari.stage02-month-weaving-test]
            [pastafari.stage02-month-weaving-large-test]
            [pastafari.stage02-month-unrank-large-test]
            [pastafari.stage02-month-profile-test]
            [pastafari.stage02-month-selection-test]
            [pastafari.stage02-month-names-test]
            [pastafari.stage02-date-projection-test]))

(defn -main [& _]
  (let [result (test/run-tests 'pastafari.stage01-test
                               'pastafari.stage02-test
                               'pastafari.stage02-stones-test
                               'pastafari.stage02-hidden-drops-test
                               'pastafari.stage02-visible-drops-test
                               'pastafari.stage02-sauce-test
                               'pastafari.stage02-gate-test
                               'pastafari.stage02-gate-positions-test
                               'pastafari.stage02-gate-windows-test
                               'pastafari.stage02-year-boundaries-test
                               'pastafari.stage02-target-year-test
                               'pastafari.stage02-cutlet-count-test
                               'pastafari.stage02-cutlet-partition-test
                               'pastafari.stage02-cutlet-names-test
                               'pastafari.stage02-cutlet-bounds-test
                               'pastafari.stage02-month-count-test
                               'pastafari.stage02-month-length-test
                               'pastafari.stage02-month-weaving-test
                               'pastafari.stage02-month-weaving-large-test
                               'pastafari.stage02-month-unrank-large-test
                               'pastafari.stage02-month-profile-test
                               'pastafari.stage02-month-selection-test
                               'pastafari.stage02-month-names-test
                               'pastafari.stage02-date-projection-test)
        failures (+ (:fail result) (:error result))]
    (println (if (zero? failures)
               "Alle Stage-1- en Stage-2-discoverytests zijn geslaagd."
               "Er zijn mislukte tests."))
    (System/exit (if (zero? failures) 0 1))))
