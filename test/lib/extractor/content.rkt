#lang racket/base

(require rackunit
         reader/lib/extractor/content
         reader/test/lib/extractor/data)

(module+ test
  (require rackunit/text-ui)
  (run-tests tests))

(define tests
  (test-suite
   "Content extraction"

   (check-match
    (extract-test-data data/minond-xyz-same-adt)
    (division
     empty
     (list
      (heading empty (list (text "Same (ADT) type, different meaning")) 1)
      _ ...
      (paragraph empty (list (text "There are instances where the semantics of distinct types overlap. Through ADTs and OOP, it is possible to represent this using different sets of types, while still being able to work with the set unions and intersections in a way that is type safe.")))
      _ ...
      (paragraph empty (list (text "Since the only constructors for ")
                             (code empty (list (text "Expr")))
                             (text " are ")
                             (code empty (list (text "Number")))
                             (text " and ")
                             (code empty (list (text "Arithmetic")))
                             (text ", this is an exhaustive match of all possible inputs. Let")
                             (entity 'rsquo)
                             (text "s try it out to make sure things work:")))
      _ ...)))))
