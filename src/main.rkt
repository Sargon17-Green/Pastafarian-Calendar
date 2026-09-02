#lang racket/base

(require "monster-base.rkt")

(provide calendar-date-spaghetti make-bootstrap-manager)

(struct bootstrap-manager (registry) #:transparent)

(define (make-bootstrap-manager)
  (bootstrap-manager (make-monster-registry)))

(define (calendar-date-spaghetti calculation-day target-day)
  (define ctx (make-base-monster-context calculation-day target-day))
  (with-validation-boundary
   ctx
   (lambda ()
     (set-monster-context-status! ctx 'bootstrap-only)
     (monster-log! ctx 'bootstrap-entry (vector calculation-day target-day))
     (error 'calendar-date-spaghetti
            "1 etapo Bootstrap dar neturi autoritetingo gamybinio kalendoriaus kelio"))))
