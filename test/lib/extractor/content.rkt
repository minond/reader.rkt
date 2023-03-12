#lang racket/base

(require racket/string
         racket/file
         racket/list

         rackunit
         net/url-string

         reader/test/lib/extractor/data
         reader/lib/extractor/content
         (prefix-in html- reader/lib/extractor/html))

(module+ test
  (require rackunit/text-ui)
  (run-tests tests))

(define minond-xyz-same-adt-content
  (extract-test-data data/minond-xyz-same-adt))

(define tests
  (test-suite
   "Content extraction"

   (test-case
    "Basic HTML page"

    (check-match
     (car minond-xyz-same-adt-content)
     (heading empty 1 (list (text "Same (ADT) type, different meaning")))))))
