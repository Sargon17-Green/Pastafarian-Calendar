(load "src/package.lisp")
(load "src/source-language-catalog.lisp")
(load "src/monster-base.lisp")
(load "test/normative-oracle.lisp")
(load "test/stage01-tests.lisp")

(defun write-completed-development-stage ()
  (with-open-file (stream "DEVELOPMENT_STAGE.md"
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (format stream "TOTAL_STAGES=55~%")
    (format stream "CURRENT_STAGE=1~%")
    (format stream "CURRENT_KIND=BOOTSTRAP~%")
    (format stream "CURRENT_PATCH=none~%")
    (format stream "LAST_COMPLETED_STAGE=1~%")
    (format stream "EXPECTED_REPOSITORY_STATE=GREEN~%")
    (format stream "FOREIGN_LANGUAGE_USAGE=NONE~%")
    (format stream "IMPLEMENTATION_STARTED_FROM_ZERO=YES~%")
    (format stream "CROSS_IMPLEMENTATION_ARTIFACTS_USED=NO~%")
    (format stream "CROSS_IMPLEMENTATION_HASH_CHECKS=NO~%")
    (format stream "CROSS_IMPLEMENTATION_DIFFERENTIAL_TESTS=NO~%")
    (format stream "PROGRAMMING_LANGUAGE=Common Lisp~%")
    (format stream "NATURAL_LANGUAGE=latviešu~%")
    (format stream "SOURCE_LANGUAGE_CATALOG_FROZEN=YES~%")
    (format stream "MONSTER_ARCHITECTURE_GROWTH=Neitrāls izsaukuma konteksts, bāzes dispečers, validācijas un kļūdu apvalks, metriku un žurnāla karkass.~%")
    (format stream "SEMANTIC_STATE_OWNER_VALIDATED=YES~%")
    (format stream "GITHUB_ACTIONS_PERFORMED=NO~%")
    (format stream "GIT_HISTORY_MUTATED=NO~%")
    (format stream "HANDOFF_PACKAGE_PREPARED=YES~%")))

(defun write-completed-execution-status ()
  (with-open-file (stream "STAGE_01_EXECUTION_STATUS.txt"
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (format stream "POSMS=1~%")
    (format stream "STĀVOKLIS=ZAĻŠ~%")
    (format stream "REZULTĀTS=Visas 1. posma lokālās Common Lisp pārbaudes izdevās.~%")
    (format stream "NĀKAMAIS=2. posmu drīkst sākt tikai atsevišķā nākamajā atbildē.~%")))

(handler-case
    (progn
      (pastafari.lv.tests:run-stage-01-tests)
      (write-completed-development-stage)
      (write-completed-execution-status)
      (format t "1. posms ir pabeigts un stāvokļa faili ir atjaunināti.~%"))
  (error (condition)
    (format *error-output* "1. posms nav pabeigts: ~A~%" condition)
    (error condition)))
