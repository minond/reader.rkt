#lang racket/base

(require racket/file

         net/url-string

         reader/extractor/content
         (prefix-in html- reader/extractor/html)

         reader/tests/setup)

(provide extract-test-data
         data/minond-xyz-same-adt)

(struct test-data (url doc))

(define (load-test-data raw-url html-path)
  (test-data (string->url "https://minond.xyz/posts/adt-type-meaning")
             (html-parse (file->string html-path))))

(define (extract-test-data data)
  (extract-content (test-data-doc data)
                   (test-data-url data)))

(define data/minond-xyz-same-adt
  (load-test-data "https://minond.xyz/posts/adt-type-meaning"
                  (build-path test-root "extractor/data/minond-xyz-posts-adt-type-meaning")))
