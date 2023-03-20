#lang racket/base

(require rackunit
         reader/lib/html)

(module+ test
  (require rackunit/text-ui)
  (run-tests tests))

(define tests
  (test-suite
   "HTML entities"

   (check-match (html-entity->string 'amp) "&")
   (check-match (html-entity->string "&amp;") "&")
   (check-match (html-entity->string "&#38;") "&")
   (check-match (html-entity->string 38) "&")

   (check-match (string-replace-html-entities "testing &#38; running &amp; saving")
                "testing & running & saving")
   (check-match (string-replace-html-entities "testing &#38; running &am; saving")
                "testing & running &am; saving")))
