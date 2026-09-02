#lang racket/base

(require "tests/stage01-tests.rkt")

(dynamic-require '(submod "tests/stage01-tests.rkt" test) #f)
