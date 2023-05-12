#lang racket/base

(require racket/string
         rackunit
         reader/extractor/text
         reader/tests/extractor/data/load)

(module+ test
  (require rackunit/text-ui)
  (run-tests tests))

(define tests
  (test-suite
   "Content extraction"

   (check-true
    (string-contains?
     (extract-text (extract-test-data data/minond-xyz-same-adt))
     (string-append
      "There are instances where the semantics of distinct types overlap. "
      "Through ADTs and OOP, it is possible to represent this using different "
      "sets of types, while still being able to work with the set unions and "
      "intersections in a way that is type safe.")))))
