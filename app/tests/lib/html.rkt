#lang racket/base

(require rackunit
         "../../lib/html.rkt")

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

   (check-match (string-replace-html-entities "a&#x2014;b")
                "a—b")
   (check-match (string-replace-html-entities "testing &#38; running &amp; saving")
                "testing & running & saving")
   (check-match (string-replace-html-entities "testing &#38; running &am; saving")
                "testing & running &am; saving")))
